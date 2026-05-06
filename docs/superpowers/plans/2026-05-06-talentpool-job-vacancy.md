# TalentPool Job Vacancy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tambah domain Vacancy + VacancyApplication ke TalentPool, lengkap dengan API (Go) dan frontend (React).

**Architecture:** Domain `vacancy` berdiri sendiri di `api/internal/domain/vacancy/`. CQRS + NATS events. Frontend: 3 halaman baru di `/admin/talent-pool/vacancies`. Hired application otomatis trigger `TalentPool.MarkPlaced`.

**Tech Stack:** Go 1.22, Chi v5, sqlx, PostgreSQL, React 18, TypeScript, Tailwind CSS, TanStack Query

---

## File Map

### API (Go)

| File | Aksi |
|------|------|
| `api/migrations/081_create_vacancy_tables.sql` | Create |
| `api/internal/domain/vacancy/vacancy.go` | Create |
| `api/internal/domain/vacancy/events.go` | Create |
| `api/infrastructure/database/vacancy_repository.go` | Create |
| `api/internal/command/create_vacancy/handler.go` | Create |
| `api/internal/command/update_vacancy/handler.go` | Create |
| `api/internal/command/update_vacancy_status/handler.go` | Create |
| `api/internal/command/delete_vacancy/handler.go` | Create |
| `api/internal/command/create_vacancy_application/handler.go` | Create |
| `api/internal/command/update_application_status/handler.go` | Create |
| `api/internal/query/list_vacancies/handler.go` | Create |
| `api/internal/query/get_vacancy/handler.go` | Create |
| `api/internal/query/list_applications/handler.go` | Create |
| `api/internal/delivery/http/vacancy_handler.go` | Create |
| `api/cmd/api/main.go` | Modify — wire vacancy deps + register routes |

### Frontend (React)

| File | Aksi |
|------|------|
| `web-dashboard/src/services/vacancy.service.ts` | Create |
| `web-dashboard/src/types/vacancy.types.ts` | Create |
| `web-dashboard/src/pages/TalentPool/VacancyListPage.tsx` | Create |
| `web-dashboard/src/pages/TalentPool/VacancyListPage.module.css` | Create |
| `web-dashboard/src/pages/TalentPool/VacancyFormPage.tsx` | Create |
| `web-dashboard/src/pages/TalentPool/VacancyFormPage.module.css` | Create |
| `web-dashboard/src/pages/TalentPool/VacancyDetailPage.tsx` | Create |
| `web-dashboard/src/pages/TalentPool/VacancyDetailPage.module.css` | Create |
| `web-dashboard/src/pages/TalentPool/components/VacancyStatusBadge.tsx` | Create |
| `web-dashboard/src/pages/TalentPool/components/ApplicationStatusBadge.tsx` | Create |
| `web-dashboard/src/pages/TalentPool/components/RecommendTalentModal.tsx` | Create |
| `web-dashboard/src/App.tsx` (atau router file) | Modify — tambah routes |
| `web-dashboard/src/components/layout/Sidebar.tsx` (atau nav file) | Modify — tambah sub-item Lowongan |

---

## Task 1: DB Migration

**Files:**
- Create: `api/migrations/081_create_vacancy_tables.sql`

- [ ] **Step 1: Tulis migration**

```sql
-- 081_create_vacancy_tables.sql

CREATE TABLE vacancies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    requirements TEXT NOT NULL DEFAULT '',
    salary_min NUMERIC,
    salary_max NUMERIC,
    salary_currency VARCHAR(10) NOT NULL DEFAULT 'IDR',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    quota INT NOT NULL DEFAULT 1,
    posted_by UUID NOT NULL,
    posted_by_role VARCHAR(50) NOT NULL DEFAULT 'staff',
    opened_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE vacancy_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vacancy_id UUID NOT NULL REFERENCES vacancies(id) ON DELETE CASCADE,
    talent_pool_id UUID NOT NULL,
    applicant_type VARCHAR(50) NOT NULL DEFAULT 'self',
    recommended_by UUID,
    status VARCHAR(50) NOT NULL DEFAULT 'applied',
    notes TEXT NOT NULL DEFAULT '',
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(vacancy_id, talent_pool_id)
);

CREATE INDEX idx_vacancies_partner_id ON vacancies(partner_id);
CREATE INDEX idx_vacancies_status ON vacancies(status);
CREATE INDEX idx_vacancies_created_at ON vacancies(created_at DESC);
CREATE INDEX idx_vacancy_applications_vacancy_id ON vacancy_applications(vacancy_id);
CREATE INDEX idx_vacancy_applications_talent_pool_id ON vacancy_applications(talent_pool_id);
CREATE INDEX idx_vacancy_applications_status ON vacancy_applications(status);
```

- [ ] **Step 2: Jalankan migration**

```bash
cd api && make migrate-up
```

Expected: migration 081 applied, tabel `vacancies` dan `vacancy_applications` terbuat.

- [ ] **Step 3: Commit**

```bash
git add api/migrations/081_create_vacancy_tables.sql
git commit -m "feat(vacancy): add vacancy and vacancy_applications tables migration"
```

---

## Task 2: Go Domain — vacancy

**Files:**
- Create: `api/internal/domain/vacancy/vacancy.go`
- Create: `api/internal/domain/vacancy/events.go`

- [ ] **Step 1: Tulis domain entity**

```go
// api/internal/domain/vacancy/vacancy.go
package vacancy

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrVacancyNotFound         = errors.New("vacancy tidak ditemukan")
	ErrApplicationNotFound     = errors.New("application tidak ditemukan")
	ErrTalentNotActive         = errors.New("talent pool entry tidak aktif")
	ErrDuplicateApplication    = errors.New("talent sudah apply ke vacancy ini")
	ErrInvalidStatusTransition = errors.New("status transition tidak valid")
	ErrQuotaExceeded           = errors.New("quota vacancy sudah penuh")
	ErrPartnerNotFound         = errors.New("partner tidak ditemukan")
)

type SalaryRange struct {
	Min      *float64 `json:"min"`
	Max      *float64 `json:"max"`
	Currency string   `json:"currency"`
}

type Vacancy struct {
	ID           uuid.UUID
	PartnerID    uuid.UUID
	Title        string
	Description  string
	Requirements string
	Salary       *SalaryRange
	Status       string // draft | open | closed | filled
	Quota        int
	PostedBy     uuid.UUID
	PostedByRole string // partner | staff
	OpenedAt     *time.Time
	ClosedAt     *time.Time
	DeletedAt    *time.Time
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

func NewVacancy(partnerID uuid.UUID, title, description, requirements string, salary *SalaryRange, quota int, postedBy uuid.UUID, postedByRole string) (*Vacancy, error) {
	if title == "" {
		return nil, errors.New("title tidak boleh kosong")
	}
	if quota < 1 {
		return nil, errors.New("quota minimal 1")
	}
	return &Vacancy{
		ID:           uuid.New(),
		PartnerID:    partnerID,
		Title:        title,
		Description:  description,
		Requirements: requirements,
		Salary:       salary,
		Status:       "draft",
		Quota:        quota,
		PostedBy:     postedBy,
		PostedByRole: postedByRole,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}, nil
}

var validTransitions = map[string][]string{
	"draft":  {"open"},
	"open":   {"closed", "filled"},
	"closed": {},
	"filled": {},
}

func (v *Vacancy) TransitionStatus(newStatus string) error {
	allowed, ok := validTransitions[v.Status]
	if !ok {
		return ErrInvalidStatusTransition
	}
	for _, s := range allowed {
		if s == newStatus {
			v.Status = newStatus
			v.UpdatedAt = time.Now()
			now := time.Now()
			if newStatus == "open" {
				v.OpenedAt = &now
			} else if newStatus == "closed" || newStatus == "filled" {
				v.ClosedAt = &now
			}
			return nil
		}
	}
	return ErrInvalidStatusTransition
}

type VacancyApplication struct {
	ID              uuid.UUID
	VacancyID       uuid.UUID
	TalentPoolID    uuid.UUID
	ApplicantType   string // self | recommended
	RecommendedBy   *uuid.UUID
	Status          string // applied | reviewed | interview | hired | rejected
	Notes           string
	AppliedAt       time.Time
	UpdatedAt       time.Time
}

func NewVacancyApplication(vacancyID, talentPoolID uuid.UUID, applicantType string, recommendedBy *uuid.UUID) *VacancyApplication {
	return &VacancyApplication{
		ID:            uuid.New(),
		VacancyID:     vacancyID,
		TalentPoolID:  talentPoolID,
		ApplicantType: applicantType,
		RecommendedBy: recommendedBy,
		Status:        "applied",
		AppliedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}
}

var validAppTransitions = map[string][]string{
	"applied":   {"reviewed", "rejected"},
	"reviewed":  {"interview", "rejected"},
	"interview": {"hired", "rejected"},
	"hired":     {},
	"rejected":  {},
}

func (a *VacancyApplication) TransitionStatus(newStatus string) error {
	allowed, ok := validAppTransitions[a.Status]
	if !ok {
		return ErrInvalidStatusTransition
	}
	for _, s := range allowed {
		if s == newStatus {
			a.Status = newStatus
			a.UpdatedAt = time.Now()
			return nil
		}
	}
	return ErrInvalidStatusTransition
}

type WriteRepository interface {
	SaveVacancy(ctx context.Context, v *Vacancy) error
	UpdateVacancy(ctx context.Context, v *Vacancy) error
	SaveApplication(ctx context.Context, a *VacancyApplication) error
	UpdateApplication(ctx context.Context, a *VacancyApplication) error
	CountHired(ctx context.Context, vacancyID uuid.UUID) (int, error)
}

type ReadRepository interface {
	GetVacancyByID(ctx context.Context, id uuid.UUID) (*Vacancy, error)
	ListVacancies(ctx context.Context, offset, limit int, status string, partnerID uuid.UUID, sortBy, sortDir string) ([]*Vacancy, int, error)
	GetApplicationByID(ctx context.Context, id uuid.UUID) (*VacancyApplication, error)
	ListApplicationsByVacancy(ctx context.Context, vacancyID uuid.UUID, offset, limit int, status string) ([]*VacancyApplication, int, error)
	ListAllApplications(ctx context.Context, offset, limit int, status string, talentPoolID uuid.UUID) ([]*VacancyApplication, int, error)
	ExistsApplication(ctx context.Context, vacancyID, talentPoolID uuid.UUID) (bool, error)
}
```

- [ ] **Step 2: Tulis events**

```go
// api/internal/domain/vacancy/events.go
package vacancy

import "github.com/google/uuid"

const (
	EventVacancyCreated     = "vacancy.created"
	EventVacancyStatusChanged = "vacancy.status_changed"
	EventApplicationHired   = "vacancy.application.hired"
)

type VacancyCreated struct {
	VacancyID uuid.UUID `json:"vacancy_id"`
	PartnerID uuid.UUID `json:"partner_id"`
	Title     string    `json:"title"`
	Timestamp int64     `json:"timestamp"`
}

func (e *VacancyCreated) EventName() string { return EventVacancyCreated }

type VacancyStatusChanged struct {
	VacancyID uuid.UUID `json:"vacancy_id"`
	NewStatus string    `json:"new_status"`
	Timestamp int64     `json:"timestamp"`
}

func (e *VacancyStatusChanged) EventName() string { return EventVacancyStatusChanged }

type ApplicationHired struct {
	ApplicationID uuid.UUID `json:"application_id"`
	VacancyID     uuid.UUID `json:"vacancy_id"`
	TalentPoolID  uuid.UUID `json:"talent_pool_id"`
	Timestamp     int64     `json:"timestamp"`
}

func (e *ApplicationHired) EventName() string { return EventApplicationHired }
```

- [ ] **Step 3: Verifikasi compile**

```bash
cd api && go build ./internal/domain/vacancy/...
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add api/internal/domain/vacancy/
git commit -m "feat(vacancy): add vacancy domain entity, application entity, and events"
```

---

## Task 3: Go Repository

**Files:**
- Create: `api/infrastructure/database/vacancy_repository.go`

- [ ] **Step 1: Tulis repository**

```go
// api/infrastructure/database/vacancy_repository.go
package database

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/vacancy"
)

type VacancyRepository struct {
	db *sqlx.DB
}

func NewVacancyRepository(db *sqlx.DB) *VacancyRepository {
	return &VacancyRepository{db: db}
}

type vacancyRecord struct {
	ID             uuid.UUID  `db:"id"`
	PartnerID      uuid.UUID  `db:"partner_id"`
	Title          string     `db:"title"`
	Description    string     `db:"description"`
	Requirements   string     `db:"requirements"`
	SalaryMin      *float64   `db:"salary_min"`
	SalaryMax      *float64   `db:"salary_max"`
	SalaryCurrency string     `db:"salary_currency"`
	Status         string     `db:"status"`
	Quota          int        `db:"quota"`
	PostedBy       uuid.UUID  `db:"posted_by"`
	PostedByRole   string     `db:"posted_by_role"`
	OpenedAt       *time.Time `db:"opened_at"`
	ClosedAt       *time.Time `db:"closed_at"`
	DeletedAt      *time.Time `db:"deleted_at"`
	CreatedAt      time.Time  `db:"created_at"`
	UpdatedAt      time.Time  `db:"updated_at"`
}

func (rec *vacancyRecord) toDomain() *vacancy.Vacancy {
	v := &vacancy.Vacancy{
		ID:           rec.ID,
		PartnerID:    rec.PartnerID,
		Title:        rec.Title,
		Description:  rec.Description,
		Requirements: rec.Requirements,
		Status:       rec.Status,
		Quota:        rec.Quota,
		PostedBy:     rec.PostedBy,
		PostedByRole: rec.PostedByRole,
		OpenedAt:     rec.OpenedAt,
		ClosedAt:     rec.ClosedAt,
		DeletedAt:    rec.DeletedAt,
		CreatedAt:    rec.CreatedAt,
		UpdatedAt:    rec.UpdatedAt,
	}
	if rec.SalaryMin != nil || rec.SalaryMax != nil {
		v.Salary = &vacancy.SalaryRange{
			Min:      rec.SalaryMin,
			Max:      rec.SalaryMax,
			Currency: rec.SalaryCurrency,
		}
	}
	return v
}

func (r *VacancyRepository) SaveVacancy(ctx context.Context, v *vacancy.Vacancy) error {
	var salaryMin, salaryMax *float64
	salaryCurrency := "IDR"
	if v.Salary != nil {
		salaryMin = v.Salary.Min
		salaryMax = v.Salary.Max
		salaryCurrency = v.Salary.Currency
	}
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO vacancies (id, partner_id, title, description, requirements,
			salary_min, salary_max, salary_currency, status, quota,
			posted_by, posted_by_role, opened_at, closed_at, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)`,
		v.ID, v.PartnerID, v.Title, v.Description, v.Requirements,
		salaryMin, salaryMax, salaryCurrency, v.Status, v.Quota,
		v.PostedBy, v.PostedByRole, v.OpenedAt, v.ClosedAt, v.CreatedAt, v.UpdatedAt,
	)
	return err
}

func (r *VacancyRepository) UpdateVacancy(ctx context.Context, v *vacancy.Vacancy) error {
	var salaryMin, salaryMax *float64
	salaryCurrency := "IDR"
	if v.Salary != nil {
		salaryMin = v.Salary.Min
		salaryMax = v.Salary.Max
		salaryCurrency = v.Salary.Currency
	}
	_, err := r.db.ExecContext(ctx, `
		UPDATE vacancies SET title=$1, description=$2, requirements=$3,
			salary_min=$4, salary_max=$5, salary_currency=$6,
			status=$7, quota=$8, opened_at=$9, closed_at=$10, deleted_at=$11, updated_at=$12
		WHERE id=$13`,
		v.Title, v.Description, v.Requirements,
		salaryMin, salaryMax, salaryCurrency,
		v.Status, v.Quota, v.OpenedAt, v.ClosedAt, v.DeletedAt, v.UpdatedAt,
		v.ID,
	)
	return err
}

func (r *VacancyRepository) GetVacancyByID(ctx context.Context, id uuid.UUID) (*vacancy.Vacancy, error) {
	var rec vacancyRecord
	err := r.db.GetContext(ctx, &rec, `SELECT * FROM vacancies WHERE id=$1 AND deleted_at IS NULL`, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, vacancy.ErrVacancyNotFound
		}
		return nil, err
	}
	return rec.toDomain(), nil
}

func (r *VacancyRepository) ListVacancies(ctx context.Context, offset, limit int, status string, partnerID uuid.UUID, sortBy, sortDir string) ([]*vacancy.Vacancy, int, error) {
	conditions := []string{"deleted_at IS NULL"}
	args := []interface{}{}
	argIdx := 1

	if status != "" {
		conditions = append(conditions, fmt.Sprintf("status=$%d", argIdx))
		args = append(args, status)
		argIdx++
	}
	if partnerID != uuid.Nil {
		conditions = append(conditions, fmt.Sprintf("partner_id=$%d", argIdx))
		args = append(args, partnerID)
		argIdx++
	}

	where := "WHERE " + strings.Join(conditions, " AND ")

	allowedSort := map[string]bool{"title": true, "status": true, "created_at": true, "quota": true}
	orderBy := "created_at DESC"
	if allowedSort[sortBy] {
		dir := "ASC"
		if strings.ToUpper(sortDir) == "DESC" {
			dir = "DESC"
		}
		orderBy = sortBy + " " + dir
	}

	var total int
	countArgs := make([]interface{}, len(args))
	copy(countArgs, args)
	if err := r.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM vacancies "+where, countArgs...).Scan(&total); err != nil {
		return nil, 0, err
	}

	args = append(args, limit, offset)
	rows, err := r.db.QueryxContext(ctx,
		fmt.Sprintf("SELECT * FROM vacancies %s ORDER BY %s LIMIT $%d OFFSET $%d", where, orderBy, argIdx, argIdx+1),
		args...,
	)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var result []*vacancy.Vacancy
	for rows.Next() {
		var rec vacancyRecord
		if err := rows.StructScan(&rec); err != nil {
			return nil, 0, err
		}
		result = append(result, rec.toDomain())
	}
	if result == nil {
		result = []*vacancy.Vacancy{}
	}
	return result, total, nil
}

type applicationRecord struct {
	ID            uuid.UUID  `db:"id"`
	VacancyID     uuid.UUID  `db:"vacancy_id"`
	TalentPoolID  uuid.UUID  `db:"talent_pool_id"`
	ApplicantType string     `db:"applicant_type"`
	RecommendedBy *uuid.UUID `db:"recommended_by"`
	Status        string     `db:"status"`
	Notes         string     `db:"notes"`
	AppliedAt     time.Time  `db:"applied_at"`
	UpdatedAt     time.Time  `db:"updated_at"`
}

func (rec *applicationRecord) toDomain() *vacancy.VacancyApplication {
	return &vacancy.VacancyApplication{
		ID:            rec.ID,
		VacancyID:     rec.VacancyID,
		TalentPoolID:  rec.TalentPoolID,
		ApplicantType: rec.ApplicantType,
		RecommendedBy: rec.RecommendedBy,
		Status:        rec.Status,
		Notes:         rec.Notes,
		AppliedAt:     rec.AppliedAt,
		UpdatedAt:     rec.UpdatedAt,
	}
}

func (r *VacancyRepository) SaveApplication(ctx context.Context, a *vacancy.VacancyApplication) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO vacancy_applications (id, vacancy_id, talent_pool_id, applicant_type, recommended_by, status, notes, applied_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
		a.ID, a.VacancyID, a.TalentPoolID, a.ApplicantType, a.RecommendedBy, a.Status, a.Notes, a.AppliedAt, a.UpdatedAt,
	)
	return err
}

func (r *VacancyRepository) UpdateApplication(ctx context.Context, a *vacancy.VacancyApplication) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE vacancy_applications SET status=$1, notes=$2, updated_at=$3 WHERE id=$4`,
		a.Status, a.Notes, a.UpdatedAt, a.ID,
	)
	return err
}

func (r *VacancyRepository) GetApplicationByID(ctx context.Context, id uuid.UUID) (*vacancy.VacancyApplication, error) {
	var rec applicationRecord
	err := r.db.GetContext(ctx, &rec, `SELECT * FROM vacancy_applications WHERE id=$1`, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, vacancy.ErrApplicationNotFound
		}
		return nil, err
	}
	return rec.toDomain(), nil
}

func (r *VacancyRepository) ListApplicationsByVacancy(ctx context.Context, vacancyID uuid.UUID, offset, limit int, status string) ([]*vacancy.VacancyApplication, int, error) {
	conditions := []string{"vacancy_id=$1"}
	args := []interface{}{vacancyID}
	argIdx := 2

	if status != "" {
		conditions = append(conditions, fmt.Sprintf("status=$%d", argIdx))
		args = append(args, status)
		argIdx++
	}
	where := "WHERE " + strings.Join(conditions, " AND ")

	var total int
	countArgs := make([]interface{}, len(args))
	copy(countArgs, args)
	if err := r.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM vacancy_applications "+where, countArgs...).Scan(&total); err != nil {
		return nil, 0, err
	}

	args = append(args, limit, offset)
	rows, err := r.db.QueryxContext(ctx,
		fmt.Sprintf("SELECT * FROM vacancy_applications %s ORDER BY applied_at DESC LIMIT $%d OFFSET $%d", where, argIdx, argIdx+1),
		args...,
	)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var result []*vacancy.VacancyApplication
	for rows.Next() {
		var rec applicationRecord
		if err := rows.StructScan(&rec); err != nil {
			return nil, 0, err
		}
		result = append(result, rec.toDomain())
	}
	if result == nil {
		result = []*vacancy.VacancyApplication{}
	}
	return result, total, nil
}

func (r *VacancyRepository) ListAllApplications(ctx context.Context, offset, limit int, status string, talentPoolID uuid.UUID) ([]*vacancy.VacancyApplication, int, error) {
	conditions := []string{}
	args := []interface{}{}
	argIdx := 1

	if status != "" {
		conditions = append(conditions, fmt.Sprintf("status=$%d", argIdx))
		args = append(args, status)
		argIdx++
	}
	if talentPoolID != uuid.Nil {
		conditions = append(conditions, fmt.Sprintf("talent_pool_id=$%d", argIdx))
		args = append(args, talentPoolID)
		argIdx++
	}

	where := ""
	if len(conditions) > 0 {
		where = "WHERE " + strings.Join(conditions, " AND ")
	}

	var total int
	countArgs := make([]interface{}, len(args))
	copy(countArgs, args)
	if err := r.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM vacancy_applications "+where, countArgs...).Scan(&total); err != nil {
		return nil, 0, err
	}

	args = append(args, limit, offset)
	rows, err := r.db.QueryxContext(ctx,
		fmt.Sprintf("SELECT * FROM vacancy_applications %s ORDER BY applied_at DESC LIMIT $%d OFFSET $%d", where, argIdx, argIdx+1),
		args...,
	)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var result []*vacancy.VacancyApplication
	for rows.Next() {
		var rec applicationRecord
		if err := rows.StructScan(&rec); err != nil {
			return nil, 0, err
		}
		result = append(result, rec.toDomain())
	}
	if result == nil {
		result = []*vacancy.VacancyApplication{}
	}
	return result, total, nil
}

func (r *VacancyRepository) ExistsApplication(ctx context.Context, vacancyID, talentPoolID uuid.UUID) (bool, error) {
	var count int
	err := r.db.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM vacancy_applications WHERE vacancy_id=$1 AND talent_pool_id=$2`,
		vacancyID, talentPoolID,
	).Scan(&count)
	return count > 0, err
}

func (r *VacancyRepository) CountHired(ctx context.Context, vacancyID uuid.UUID) (int, error) {
	var count int
	err := r.db.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM vacancy_applications WHERE vacancy_id=$1 AND status='hired'`,
		vacancyID,
	).Scan(&count)
	return count, err
}

// Suppress unused import
var _ = json.Marshal
```

- [ ] **Step 2: Verify compile**

```bash
cd api && go build ./infrastructure/database/...
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add api/infrastructure/database/vacancy_repository.go
git commit -m "feat(vacancy): add VacancyRepository with full CRUD and application support"
```

---

## Task 4: Go Commands

**Files:**
- Create: `api/internal/command/create_vacancy/handler.go`
- Create: `api/internal/command/update_vacancy/handler.go`
- Create: `api/internal/command/update_vacancy_status/handler.go`
- Create: `api/internal/command/delete_vacancy/handler.go`
- Create: `api/internal/command/create_vacancy_application/handler.go`
- Create: `api/internal/command/update_application_status/handler.go`

- [ ] **Step 1: create_vacancy**

```go
// api/internal/command/create_vacancy/handler.go
package create_vacancy

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/vacancy"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

var ErrInvalidCommand = errors.New("invalid command type")

type CreateVacancyCommand struct {
	PartnerID    uuid.UUID
	Title        string
	Description  string
	Requirements string
	Salary       *vacancy.SalaryRange
	Quota        int
	PostedBy     uuid.UUID
	PostedByRole string
}

type Handler struct {
	writeRepo vacancy.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo vacancy.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateVacancyCommand)
	if !ok {
		return ErrInvalidCommand
	}

	v, err := vacancy.NewVacancy(c.PartnerID, c.Title, c.Description, c.Requirements, c.Salary, c.Quota, c.PostedBy, c.PostedByRole)
	if err != nil {
		return err
	}

	if err := h.writeRepo.SaveVacancy(ctx, v); err != nil {
		log.Error().Err(err).Msg("failed to save vacancy")
		return err
	}

	event := &vacancy.VacancyCreated{
		VacancyID: v.ID,
		PartnerID: v.PartnerID,
		Title:     v.Title,
		Timestamp: time.Now().Unix(),
	}
	if pubErr := h.eventBus.Publish(ctx, event); pubErr != nil {
		log.Error().Err(pubErr).Msg("failed to publish VacancyCreated event")
	}

	log.Info().Str("vacancy_id", v.ID.String()).Msg("vacancy created")
	return nil
}
```

- [ ] **Step 2: update_vacancy**

```go
// api/internal/command/update_vacancy/handler.go
package update_vacancy

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/vacancy"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

var ErrInvalidCommand = errors.New("invalid command type")

type UpdateVacancyCommand struct {
	VacancyID    uuid.UUID
	Title        string
	Description  string
	Requirements string
	Salary       *vacancy.SalaryRange
	Quota        int
}

type Handler struct {
	writeRepo vacancy.WriteRepository
	readRepo  vacancy.ReadRepository
}

func NewHandler(writeRepo vacancy.WriteRepository, readRepo vacancy.ReadRepository) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateVacancyCommand)
	if !ok {
		return ErrInvalidCommand
	}

	v, err := h.readRepo.GetVacancyByID(ctx, c.VacancyID)
	if err != nil {
		return err
	}

	v.Title = c.Title
	v.Description = c.Description
	v.Requirements = c.Requirements
	v.Salary = c.Salary
	v.Quota = c.Quota

	if err := h.writeRepo.UpdateVacancy(ctx, v); err != nil {
		log.Error().Err(err).Msg("failed to update vacancy")
		return err
	}
	return nil
}
```

- [ ] **Step 3: update_vacancy_status**

```go
// api/internal/command/update_vacancy_status/handler.go
package update_vacancy_status

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/vacancy"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

var ErrInvalidCommand = errors.New("invalid command type")

type UpdateVacancyStatusCommand struct {
	VacancyID uuid.UUID
	NewStatus string
}

type Handler struct {
	writeRepo vacancy.WriteRepository
	readRepo  vacancy.ReadRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo vacancy.WriteRepository, readRepo vacancy.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateVacancyStatusCommand)
	if !ok {
		return ErrInvalidCommand
	}

	v, err := h.readRepo.GetVacancyByID(ctx, c.VacancyID)
	if err != nil {
		return err
	}

	if err := v.TransitionStatus(c.NewStatus); err != nil {
		return err
	}

	if err := h.writeRepo.UpdateVacancy(ctx, v); err != nil {
		log.Error().Err(err).Msg("failed to update vacancy status")
		return err
	}

	event := &vacancy.VacancyStatusChanged{
		VacancyID: v.ID,
		NewStatus: v.Status,
		Timestamp: time.Now().Unix(),
	}
	if pubErr := h.eventBus.Publish(ctx, event); pubErr != nil {
		log.Error().Err(pubErr).Msg("failed to publish VacancyStatusChanged event")
	}
	return nil
}
```

- [ ] **Step 4: delete_vacancy**

```go
// api/internal/command/delete_vacancy/handler.go
package delete_vacancy

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/vacancy"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

var ErrInvalidCommand = errors.New("invalid command type")

type DeleteVacancyCommand struct {
	VacancyID uuid.UUID
}

type Handler struct {
	writeRepo vacancy.WriteRepository
	readRepo  vacancy.ReadRepository
}

func NewHandler(writeRepo vacancy.WriteRepository, readRepo vacancy.ReadRepository) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteVacancyCommand)
	if !ok {
		return ErrInvalidCommand
	}

	v, err := h.readRepo.GetVacancyByID(ctx, c.VacancyID)
	if err != nil {
		return err
	}

	now := time.Now()
	v.DeletedAt = &now
	v.UpdatedAt = now

	if err := h.writeRepo.UpdateVacancy(ctx, v); err != nil {
		log.Error().Err(err).Msg("failed to soft delete vacancy")
		return err
	}
	log.Info().Str("vacancy_id", v.ID.String()).Msg("vacancy soft deleted")
	return nil
}
```

- [ ] **Step 5: create_vacancy_application**

```go
// api/internal/command/create_vacancy_application/handler.go
package create_vacancy_application

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/talentpool"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/vacancy"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

var ErrInvalidCommand = errors.New("invalid command type")

type CreateVacancyApplicationCommand struct {
	VacancyID     uuid.UUID
	TalentPoolID  uuid.UUID
	ApplicantType string
	RecommendedBy *uuid.UUID
}

type Handler struct {
	vacancyWriteRepo  vacancy.WriteRepository
	vacancyReadRepo   vacancy.ReadRepository
	talentPoolReadRepo talentpool.ReadRepository
}

func NewHandler(vacancyWriteRepo vacancy.WriteRepository, vacancyReadRepo vacancy.ReadRepository, talentPoolReadRepo talentpool.ReadRepository) *Handler {
	return &Handler{
		vacancyWriteRepo:   vacancyWriteRepo,
		vacancyReadRepo:    vacancyReadRepo,
		talentPoolReadRepo: talentPoolReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateVacancyApplicationCommand)
	if !ok {
		return ErrInvalidCommand
	}

	// Verify vacancy exists
	v, err := h.vacancyReadRepo.GetVacancyByID(ctx, c.VacancyID)
	if err != nil {
		return err
	}
	if v.Status != "open" {
		return errors.New("hanya vacancy berstatus open yang bisa dilamar")
	}

	// Verify talent pool entry is active
	tp, err := h.talentPoolReadRepo.GetByID(ctx, c.TalentPoolID)
	if err != nil {
		return vacancy.ErrTalentNotActive
	}
	if tp.TalentpoolStatus != "active" {
		return vacancy.ErrTalentNotActive
	}

	// Check duplicate
	exists, err := h.vacancyReadRepo.ExistsApplication(ctx, c.VacancyID, c.TalentPoolID)
	if err != nil {
		return err
	}
	if exists {
		return vacancy.ErrDuplicateApplication
	}

	app := vacancy.NewVacancyApplication(c.VacancyID, c.TalentPoolID, c.ApplicantType, c.RecommendedBy)
	if err := h.vacancyWriteRepo.SaveApplication(ctx, app); err != nil {
		log.Error().Err(err).Msg("failed to save vacancy application")
		return err
	}

	log.Info().Str("application_id", app.ID.String()).Msg("vacancy application created")
	return nil
}
```

- [ ] **Step 6: update_application_status**

```go
// api/internal/command/update_application_status/handler.go
package update_application_status

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/talentpool"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/vacancy"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

var ErrInvalidCommand = errors.New("invalid command type")

type UpdateApplicationStatusCommand struct {
	ApplicationID uuid.UUID
	NewStatus     string
	Notes         string
}

type Handler struct {
	vacancyWriteRepo   vacancy.WriteRepository
	vacancyReadRepo    vacancy.ReadRepository
	talentPoolWriteRepo talentpool.WriteRepository
	talentPoolReadRepo  talentpool.ReadRepository
	eventBus           eventbus.EventBus
}

func NewHandler(
	vacancyWriteRepo vacancy.WriteRepository,
	vacancyReadRepo vacancy.ReadRepository,
	talentPoolWriteRepo talentpool.WriteRepository,
	talentPoolReadRepo talentpool.ReadRepository,
	eventBus eventbus.EventBus,
) *Handler {
	return &Handler{
		vacancyWriteRepo:    vacancyWriteRepo,
		vacancyReadRepo:     vacancyReadRepo,
		talentPoolWriteRepo: talentPoolWriteRepo,
		talentPoolReadRepo:  talentPoolReadRepo,
		eventBus:            eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateApplicationStatusCommand)
	if !ok {
		return ErrInvalidCommand
	}

	app, err := h.vacancyReadRepo.GetApplicationByID(ctx, c.ApplicationID)
	if err != nil {
		return err
	}

	if err := app.TransitionStatus(c.NewStatus); err != nil {
		return err
	}
	app.Notes = c.Notes

	if err := h.vacancyWriteRepo.UpdateApplication(ctx, app); err != nil {
		log.Error().Err(err).Msg("failed to update application status")
		return err
	}

	if c.NewStatus == "hired" {
		// Side-effect 1: MarkPlaced on TalentPool
		v, err := h.vacancyReadRepo.GetVacancyByID(ctx, app.VacancyID)
		if err != nil {
			return err
		}
		tp, err := h.talentPoolReadRepo.GetByID(ctx, app.TalentPoolID)
		if err != nil {
			return err
		}
		tp.MarkPlaced(talentpool.PlacementRecord{
			CompanyName: "", // filled via partner lookup if needed — vacancy title is sufficient for now
			Position:    v.Title,
			PlacedAt:    time.Now(),
			Notes:       "via vacancy: " + v.Title,
		})
		if err := h.talentPoolWriteRepo.Update(ctx, tp); err != nil {
			log.Error().Err(err).Msg("failed to mark talent pool as placed")
			return err
		}

		// Side-effect 2: Auto-fill vacancy if hired >= quota
		hiredCount, err := h.vacancyWriteRepo.CountHired(ctx, v.ID)
		if err == nil && hiredCount >= v.Quota {
			_ = v.TransitionStatus("filled")
			_ = h.vacancyWriteRepo.UpdateVacancy(ctx, v)
		}

		event := &vacancy.ApplicationHired{
			ApplicationID: app.ID,
			VacancyID:     app.VacancyID,
			TalentPoolID:  app.TalentPoolID,
			Timestamp:     time.Now().Unix(),
		}
		if pubErr := h.eventBus.Publish(ctx, event); pubErr != nil {
			log.Error().Err(pubErr).Msg("failed to publish ApplicationHired event")
		}
	}

	log.Info().Str("application_id", app.ID.String()).Str("status", app.Status).Msg("application status updated")
	return nil
}
```

- [ ] **Step 7: Verify compile**

```bash
cd api && go build ./internal/command/create_vacancy/... ./internal/command/update_vacancy/... ./internal/command/update_vacancy_status/... ./internal/command/delete_vacancy/... ./internal/command/create_vacancy_application/... ./internal/command/update_application_status/...
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add api/internal/command/create_vacancy/ api/internal/command/update_vacancy/ api/internal/command/update_vacancy_status/ api/internal/command/delete_vacancy/ api/internal/command/create_vacancy_application/ api/internal/command/update_application_status/
git commit -m "feat(vacancy): add all vacancy and application command handlers"
```

---

## Task 5: Go Queries

**Files:**
- Create: `api/internal/query/list_vacancies/handler.go`
- Create: `api/internal/query/get_vacancy/handler.go`
- Create: `api/internal/query/list_applications/handler.go`

- [ ] **Step 1: list_vacancies**

```go
// api/internal/query/list_vacancies/handler.go
package list_vacancies

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/vacancy"
)

var ErrInvalidQuery = errors.New("invalid query type")

type ListVacanciesQuery struct {
	Offset    int
	Limit     int
	Status    string
	PartnerID uuid.UUID
	SortBy    string
	SortDir   string
}

type VacancyReadModel struct {
	ID           string               `json:"id"`
	PartnerID    string               `json:"partner_id"`
	Title        string               `json:"title"`
	Description  string               `json:"description"`
	Requirements string               `json:"requirements"`
	Salary       *vacancy.SalaryRange `json:"salary"`
	Status       string               `json:"status"`
	Quota        int                  `json:"quota"`
	PostedBy     string               `json:"posted_by"`
	PostedByRole string               `json:"posted_by_role"`
	OpenedAt     *int64               `json:"opened_at"`
	ClosedAt     *int64               `json:"closed_at"`
	CreatedAt    int64                `json:"created_at"`
	UpdatedAt    int64                `json:"updated_at"`
}

type ListResult struct {
	Data   []*VacancyReadModel `json:"data"`
	Total  int                 `json:"total"`
	Offset int                 `json:"offset"`
	Limit  int                 `json:"limit"`
}

type Handler struct {
	readRepo vacancy.ReadRepository
}

func NewHandler(readRepo vacancy.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func toReadModel(v *vacancy.Vacancy) *VacancyReadModel {
	rm := &VacancyReadModel{
		ID:           v.ID.String(),
		PartnerID:    v.PartnerID.String(),
		Title:        v.Title,
		Description:  v.Description,
		Requirements: v.Requirements,
		Salary:       v.Salary,
		Status:       v.Status,
		Quota:        v.Quota,
		PostedBy:     v.PostedBy.String(),
		PostedByRole: v.PostedByRole,
		CreatedAt:    v.CreatedAt.Unix(),
		UpdatedAt:    v.UpdatedAt.Unix(),
	}
	if v.OpenedAt != nil {
		t := v.OpenedAt.Unix()
		rm.OpenedAt = &t
	}
	if v.ClosedAt != nil {
		t := v.ClosedAt.Unix()
		rm.ClosedAt = &t
	}
	return rm
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListVacanciesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	entries, total, err := h.readRepo.ListVacancies(ctx, q.Offset, q.Limit, q.Status, q.PartnerID, q.SortBy, q.SortDir)
	if err != nil {
		log.Error().Err(err).Msg("failed to list vacancies")
		return nil, err
	}

	readModels := make([]*VacancyReadModel, len(entries))
	for i, v := range entries {
		readModels[i] = toReadModel(v)
	}
	return &ListResult{Data: readModels, Total: total, Offset: q.Offset, Limit: q.Limit}, nil
}
```

- [ ] **Step 2: get_vacancy**

```go
// api/internal/query/get_vacancy/handler.go
package get_vacancy

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/vacancy"
	"github.com/vernonedu/entrepreneurship-api/internal/query/list_vacancies"
)

var ErrInvalidQuery = errors.New("invalid query type")

type GetVacancyQuery struct {
	VacancyID uuid.UUID
}

type Handler struct {
	readRepo vacancy.ReadRepository
}

func NewHandler(readRepo vacancy.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetVacancyQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	v, err := h.readRepo.GetVacancyByID(ctx, q.VacancyID)
	if err != nil {
		log.Error().Err(err).Msg("failed to get vacancy by id")
		return nil, err
	}

	return list_vacancies.ToReadModel(v), nil
}
```

> **Note:** Ekspos `toReadModel` dari `list_vacancies` sebagai exported `ToReadModel` agar bisa dipakai `get_vacancy`.

- [ ] **Step 3: Update list_vacancies — ekspos ToReadModel**

Di file `api/internal/query/list_vacancies/handler.go`, rename `toReadModel` → `ToReadModel` (capital T):

```go
// Ganti:
func toReadModel(v *vacancy.Vacancy) *VacancyReadModel {

// Menjadi:
func ToReadModel(v *vacancy.Vacancy) *VacancyReadModel {

// Dan update caller di Handle():
readModels[i] = ToReadModel(v)
```

- [ ] **Step 4: list_applications**

```go
// api/internal/query/list_applications/handler.go
package list_applications

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/vacancy"
)

var ErrInvalidQuery = errors.New("invalid query type")

type ListApplicationsQuery struct {
	VacancyID    uuid.UUID // uuid.Nil = all vacancies
	TalentPoolID uuid.UUID
	Status       string
	Offset       int
	Limit        int
}

type ApplicationReadModel struct {
	ID            string  `json:"id"`
	VacancyID     string  `json:"vacancy_id"`
	TalentPoolID  string  `json:"talent_pool_id"`
	ApplicantType string  `json:"applicant_type"`
	RecommendedBy *string `json:"recommended_by"`
	Status        string  `json:"status"`
	Notes         string  `json:"notes"`
	AppliedAt     int64   `json:"applied_at"`
	UpdatedAt     int64   `json:"updated_at"`
}

type ListResult struct {
	Data   []*ApplicationReadModel `json:"data"`
	Total  int                     `json:"total"`
	Offset int                     `json:"offset"`
	Limit  int                     `json:"limit"`
}

type Handler struct {
	readRepo vacancy.ReadRepository
}

func NewHandler(readRepo vacancy.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func toAppReadModel(a *vacancy.VacancyApplication) *ApplicationReadModel {
	rm := &ApplicationReadModel{
		ID:            a.ID.String(),
		VacancyID:     a.VacancyID.String(),
		TalentPoolID:  a.TalentPoolID.String(),
		ApplicantType: a.ApplicantType,
		Status:        a.Status,
		Notes:         a.Notes,
		AppliedAt:     a.AppliedAt.Unix(),
		UpdatedAt:     a.UpdatedAt.Unix(),
	}
	if a.RecommendedBy != nil {
		s := a.RecommendedBy.String()
		rm.RecommendedBy = &s
	}
	return rm
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListApplicationsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	var apps []*vacancy.VacancyApplication
	var total int
	var err error

	if q.VacancyID != uuid.Nil {
		apps, total, err = h.readRepo.ListApplicationsByVacancy(ctx, q.VacancyID, q.Offset, q.Limit, q.Status)
	} else {
		apps, total, err = h.readRepo.ListAllApplications(ctx, q.Offset, q.Limit, q.Status, q.TalentPoolID)
	}
	if err != nil {
		log.Error().Err(err).Msg("failed to list applications")
		return nil, err
	}

	readModels := make([]*ApplicationReadModel, len(apps))
	for i, a := range apps {
		readModels[i] = toAppReadModel(a)
	}
	return &ListResult{Data: readModels, Total: total, Offset: q.Offset, Limit: q.Limit}, nil
}
```

- [ ] **Step 5: Verify compile**

```bash
cd api && go build ./internal/query/list_vacancies/... ./internal/query/get_vacancy/... ./internal/query/list_applications/...
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add api/internal/query/list_vacancies/ api/internal/query/get_vacancy/ api/internal/query/list_applications/
git commit -m "feat(vacancy): add list_vacancies, get_vacancy, list_applications query handlers"
```

---

## Task 6: HTTP Handler + Wire

**Files:**
- Create: `api/internal/delivery/http/vacancy_handler.go`
- Modify: `api/cmd/api/main.go`

- [ ] **Step 1: Tulis vacancy_handler.go**

```go
// api/internal/delivery/http/vacancy_handler.go
package http

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	create_vacancy "github.com/vernonedu/entrepreneurship-api/internal/command/create_vacancy"
	create_vacancy_application "github.com/vernonedu/entrepreneurship-api/internal/command/create_vacancy_application"
	delete_vacancy "github.com/vernonedu/entrepreneurship-api/internal/command/delete_vacancy"
	update_application_status "github.com/vernonedu/entrepreneurship-api/internal/command/update_application_status"
	update_vacancy "github.com/vernonedu/entrepreneurship-api/internal/command/update_vacancy"
	update_vacancy_status "github.com/vernonedu/entrepreneurship-api/internal/command/update_vacancy_status"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/vacancy"
	get_vacancy "github.com/vernonedu/entrepreneurship-api/internal/query/get_vacancy"
	list_applications "github.com/vernonedu/entrepreneurship-api/internal/query/list_applications"
	list_vacancies "github.com/vernonedu/entrepreneurship-api/internal/query/list_vacancies"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/querybus"
	"github.com/vernonedu/entrepreneurship-api/pkg/sortutil"
)

type VacancyHandler struct {
	cmdBus commandbus.CommandBus
	qryBus querybus.QueryBus
}

func NewVacancyHandler(cmdBus commandbus.CommandBus, qryBus querybus.QueryBus) *VacancyHandler {
	return &VacancyHandler{cmdBus: cmdBus, qryBus: qryBus}
}

type createVacancyRequest struct {
	PartnerID    string               `json:"partner_id"`
	Title        string               `json:"title"`
	Description  string               `json:"description"`
	Requirements string               `json:"requirements"`
	Salary       *vacancy.SalaryRange `json:"salary"`
	Quota        int                  `json:"quota"`
	PostedByRole string               `json:"posted_by_role"`
}

type updateVacancyRequest struct {
	Title        string               `json:"title"`
	Description  string               `json:"description"`
	Requirements string               `json:"requirements"`
	Salary       *vacancy.SalaryRange `json:"salary"`
	Quota        int                  `json:"quota"`
}

type updateStatusRequest struct {
	Status string `json:"status"`
}

type createApplicationRequest struct {
	TalentPoolID  string  `json:"talent_pool_id"`
	ApplicantType string  `json:"applicant_type"`
	RecommendedBy *string `json:"recommended_by"`
}

type updateApplicationStatusRequest struct {
	Status string `json:"status"`
	Notes  string `json:"notes"`
}

func (h *VacancyHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req createVacancyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	partnerID, err := uuid.Parse(req.PartnerID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid partner_id")
		return
	}

	// TODO: extract postedBy from JWT context when auth middleware is wired
	postedBy := uuid.Nil

	cmd := &create_vacancy.CreateVacancyCommand{
		PartnerID:    partnerID,
		Title:        req.Title,
		Description:  req.Description,
		Requirements: req.Requirements,
		Salary:       req.Salary,
		Quota:        req.Quota,
		PostedBy:     postedBy,
		PostedByRole: req.PostedByRole,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create vacancy")
		writeError(w, http.StatusInternalServerError, "failed to create vacancy")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "vacancy created"})
}

func (h *VacancyHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}
	status := r.URL.Query().Get("status")
	var partnerID uuid.UUID
	if p := r.URL.Query().Get("partner_id"); p != "" {
		if parsed, err := uuid.Parse(p); err == nil {
			partnerID = parsed
		}
	}
	sort := sortutil.Parse(r.URL.Query().Get("sort"))
	sortBy, sortDir := "", ""
	if sort != nil {
		sortBy, sortDir = sort.Column, sort.Dir
	}

	query := &list_vacancies.ListVacanciesQuery{
		Offset: offset, Limit: limit, Status: status, PartnerID: partnerID, SortBy: sortBy, SortDir: sortDir,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list vacancies")
		writeError(w, http.StatusInternalServerError, "failed to list vacancies")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *VacancyHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid vacancy id")
		return
	}
	result, err := h.qryBus.Execute(r.Context(), &get_vacancy.GetVacancyQuery{VacancyID: id})
	if err != nil {
		log.Error().Err(err).Msg("failed to get vacancy")
		writeError(w, http.StatusInternalServerError, "failed to get vacancy")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"data": result})
}

func (h *VacancyHandler) Update(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid vacancy id")
		return
	}
	var req updateVacancyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &update_vacancy.UpdateVacancyCommand{
		VacancyID: id, Title: req.Title, Description: req.Description,
		Requirements: req.Requirements, Salary: req.Salary, Quota: req.Quota,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update vacancy")
		writeError(w, http.StatusInternalServerError, "failed to update vacancy")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "vacancy updated"})
}

func (h *VacancyHandler) UpdateStatus(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid vacancy id")
		return
	}
	var req updateStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &update_vacancy_status.UpdateVacancyStatusCommand{VacancyID: id, NewStatus: req.Status}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update vacancy status")
		if err == vacancy.ErrInvalidStatusTransition {
			writeError(w, http.StatusUnprocessableEntity, err.Error())
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to update vacancy status")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "vacancy status updated"})
}

func (h *VacancyHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid vacancy id")
		return
	}
	cmd := &delete_vacancy.DeleteVacancyCommand{VacancyID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to delete vacancy")
		writeError(w, http.StatusInternalServerError, "failed to delete vacancy")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "vacancy deleted"})
}

func (h *VacancyHandler) CreateApplication(w http.ResponseWriter, r *http.Request) {
	vacancyID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid vacancy id")
		return
	}
	var req createApplicationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	talentPoolID, err := uuid.Parse(req.TalentPoolID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid talent_pool_id")
		return
	}

	var recommendedBy *uuid.UUID
	if req.RecommendedBy != nil {
		if parsed, err := uuid.Parse(*req.RecommendedBy); err == nil {
			recommendedBy = &parsed
		}
	}

	cmd := &create_vacancy_application.CreateVacancyApplicationCommand{
		VacancyID: vacancyID, TalentPoolID: talentPoolID,
		ApplicantType: req.ApplicantType, RecommendedBy: recommendedBy,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create application")
		switch err {
		case vacancy.ErrTalentNotActive:
			writeError(w, http.StatusUnprocessableEntity, err.Error())
		case vacancy.ErrDuplicateApplication:
			writeError(w, http.StatusConflict, err.Error())
		default:
			writeError(w, http.StatusInternalServerError, "failed to create application")
		}
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "application created"})
}

func (h *VacancyHandler) ListApplications(w http.ResponseWriter, r *http.Request) {
	vacancyID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid vacancy id")
		return
	}
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}
	status := r.URL.Query().Get("status")

	query := &list_applications.ListApplicationsQuery{
		VacancyID: vacancyID, Offset: offset, Limit: limit, Status: status,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list applications")
		writeError(w, http.StatusInternalServerError, "failed to list applications")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *VacancyHandler) ListAllApplications(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}
	status := r.URL.Query().Get("status")
	var talentPoolID uuid.UUID
	if t := r.URL.Query().Get("talent_pool_id"); t != "" {
		if parsed, err := uuid.Parse(t); err == nil {
			talentPoolID = parsed
		}
	}
	query := &list_applications.ListApplicationsQuery{
		Offset: offset, Limit: limit, Status: status, TalentPoolID: talentPoolID,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to list all applications")
		writeError(w, http.StatusInternalServerError, "failed to list all applications")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *VacancyHandler) UpdateApplicationStatus(w http.ResponseWriter, r *http.Request) {
	appID, err := uuid.Parse(chi.URLParam(r, "appId"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid application id")
		return
	}
	var req updateApplicationStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &update_application_status.UpdateApplicationStatusCommand{
		ApplicationID: appID, NewStatus: req.Status, Notes: req.Notes,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update application status")
		if err == vacancy.ErrInvalidStatusTransition {
			writeError(w, http.StatusUnprocessableEntity, err.Error())
			return
		}
		if err == vacancy.ErrQuotaExceeded {
			writeError(w, http.StatusUnprocessableEntity, err.Error())
			return
		}
		writeError(w, http.StatusInternalServerError, "failed to update application status")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "application status updated"})
}

func RegisterVacancyRoutes(h *VacancyHandler, r chi.Router) {
	r.Post("/api/v1/talent-pool/vacancies", h.Create)
	r.Get("/api/v1/talent-pool/vacancies", h.List)
	r.Get("/api/v1/talent-pool/vacancies/{id}", h.GetByID)
	r.Put("/api/v1/talent-pool/vacancies/{id}", h.Update)
	r.Patch("/api/v1/talent-pool/vacancies/{id}/status", h.UpdateStatus)
	r.Delete("/api/v1/talent-pool/vacancies/{id}", h.Delete)
	r.Post("/api/v1/talent-pool/vacancies/{id}/applications", h.CreateApplication)
	r.Get("/api/v1/talent-pool/vacancies/{id}/applications", h.ListApplications)
	r.Get("/api/v1/talent-pool/applications", h.ListAllApplications)
	r.Patch("/api/v1/talent-pool/applications/{appId}/status", h.UpdateApplicationStatus)
}
```

- [ ] **Step 2: Wire di main.go**

Cari section di `api/cmd/api/main.go` tempat `TalentPoolRepository` dan handler `TalentPool` di-wire. Tambahkan tepat di bawahnya:

```go
// Imports — tambahkan di bagian import:
createvacancy      "github.com/vernonedu/entrepreneurship-api/internal/command/create_vacancy"
updatevacancy      "github.com/vernonedu/entrepreneurship-api/internal/command/update_vacancy"
updatevacancystatus "github.com/vernonedu/entrepreneurship-api/internal/command/update_vacancy_status"
deletevacancy      "github.com/vernonedu/entrepreneurship-api/internal/command/delete_vacancy"
createvacancyapp   "github.com/vernonedu/entrepreneurship-api/internal/command/create_vacancy_application"
updateappstatus    "github.com/vernonedu/entrepreneurship-api/internal/command/update_application_status"
listvacancies      "github.com/vernonedu/entrepreneurship-api/internal/query/list_vacancies"
getvacancy         "github.com/vernonedu/entrepreneurship-api/internal/query/get_vacancy"
listapplications   "github.com/vernonedu/entrepreneurship-api/internal/query/list_applications"

// Repository init (setelah talentPoolRepo):
vacancyRepo := database.NewVacancyRepository(db)

// Command handlers:
cmdBus.Register(&createvacancy.CreateVacancyCommand{}, createvacancy.NewHandler(vacancyRepo, eventBus))
cmdBus.Register(&updatevacancy.UpdateVacancyCommand{}, updatevacancy.NewHandler(vacancyRepo, vacancyRepo))
cmdBus.Register(&updatevacancystatus.UpdateVacancyStatusCommand{}, updatevacancystatus.NewHandler(vacancyRepo, vacancyRepo, eventBus))
cmdBus.Register(&deletevacancy.DeleteVacancyCommand{}, deletevacancy.NewHandler(vacancyRepo, vacancyRepo))
cmdBus.Register(&createvacancyapp.CreateVacancyApplicationCommand{}, createvacancyapp.NewHandler(vacancyRepo, vacancyRepo, talentPoolRepo))
cmdBus.Register(&updateappstatus.UpdateApplicationStatusCommand{}, updateappstatus.NewHandler(vacancyRepo, vacancyRepo, talentPoolRepo, talentPoolRepo, eventBus))

// Query handlers:
qryBus.Register(&listvacancies.ListVacanciesQuery{}, listvacancies.NewHandler(vacancyRepo))
qryBus.Register(&getvacancy.GetVacancyQuery{}, getvacancy.NewHandler(vacancyRepo))
qryBus.Register(&listapplications.ListApplicationsQuery{}, listapplications.NewHandler(vacancyRepo))

// Handler + routes (setelah talentPoolHandler):
vacancyHandler := httphandler.NewVacancyHandler(cmdBus, qryBus)
httphandler.RegisterVacancyRoutes(vacancyHandler, r)
```

- [ ] **Step 3: Build full API**

```bash
cd api && go build ./...
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add api/internal/delivery/http/vacancy_handler.go api/cmd/api/main.go
git commit -m "feat(vacancy): add VacancyHandler, register routes and wire all deps in main.go"
```

---

## Task 7: Frontend Types + Service

**Files:**
- Create: `web-dashboard/src/types/vacancy.types.ts`
- Create: `web-dashboard/src/services/vacancy.service.ts`

- [ ] **Step 1: Tulis types**

```typescript
// web-dashboard/src/types/vacancy.types.ts

export interface SalaryRange {
  min?: number
  max?: number
  currency: string
}

export type VacancyStatus = 'draft' | 'open' | 'closed' | 'filled'
export type ApplicationStatus = 'applied' | 'reviewed' | 'interview' | 'hired' | 'rejected'
export type ApplicantType = 'self' | 'recommended'

export interface Vacancy {
  id: string
  partner_id: string
  title: string
  description: string
  requirements: string
  salary?: SalaryRange
  status: VacancyStatus
  quota: number
  posted_by: string
  posted_by_role: string
  opened_at?: number
  closed_at?: number
  created_at: number
  updated_at: number
}

export interface VacancyApplication {
  id: string
  vacancy_id: string
  talent_pool_id: string
  applicant_type: ApplicantType
  recommended_by?: string
  status: ApplicationStatus
  notes: string
  applied_at: number
  updated_at: number
}

export interface CreateVacancyPayload {
  partner_id: string
  title: string
  description: string
  requirements: string
  salary?: SalaryRange
  quota: number
  posted_by_role: string
}

export interface UpdateVacancyPayload {
  title: string
  description: string
  requirements: string
  salary?: SalaryRange
  quota: number
}

export interface CreateApplicationPayload {
  talent_pool_id: string
  applicant_type: ApplicantType
  recommended_by?: string
}

export interface UpdateApplicationStatusPayload {
  status: ApplicationStatus
  notes: string
}

export interface VacancyFilters {
  status?: VacancyStatus
  partner_id?: string
}

export interface ApplicationFilters {
  status?: ApplicationStatus
  talent_pool_id?: string
}
```

- [ ] **Step 2: Tulis service**

```typescript
// web-dashboard/src/services/vacancy.service.ts
import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'
import type {
  Vacancy,
  VacancyApplication,
  CreateVacancyPayload,
  UpdateVacancyPayload,
  CreateApplicationPayload,
  UpdateApplicationStatusPayload,
  VacancyFilters,
  ApplicationFilters,
} from '@/types/vacancy.types'

export const vacancyService = {
  list: (params?: ListParams & VacancyFilters): Promise<PaginatedResponse<Vacancy>> =>
    apiClient.get<unknown>(`talent-pool/vacancies${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string): Promise<Vacancy> =>
    apiClient.get<any>(`talent-pool/vacancies/${id}`).then((r: any) => r?.data ?? r),

  create: (payload: CreateVacancyPayload): Promise<void> =>
    apiClient.post<void>('talent-pool/vacancies', payload),

  update: (id: string, payload: UpdateVacancyPayload): Promise<void> =>
    apiClient.put<void>(`talent-pool/vacancies/${id}`, payload),

  updateStatus: (id: string, status: string): Promise<void> =>
    apiClient.patch<void>(`talent-pool/vacancies/${id}/status`, { status }),

  delete: (id: string): Promise<void> =>
    apiClient.delete<void>(`talent-pool/vacancies/${id}`),

  listApplications: (vacancyId: string, params?: ListParams & ApplicationFilters): Promise<PaginatedResponse<VacancyApplication>> =>
    apiClient.get<unknown>(`talent-pool/vacancies/${vacancyId}/applications${buildQueryString(params)}`).then(r => extractPaginated(r)),

  listAllApplications: (params?: ListParams & ApplicationFilters): Promise<PaginatedResponse<VacancyApplication>> =>
    apiClient.get<unknown>(`talent-pool/applications${buildQueryString(params)}`).then(r => extractPaginated(r)),

  createApplication: (vacancyId: string, payload: CreateApplicationPayload): Promise<void> =>
    apiClient.post<void>(`talent-pool/vacancies/${vacancyId}/applications`, payload),

  updateApplicationStatus: (appId: string, payload: UpdateApplicationStatusPayload): Promise<void> =>
    apiClient.patch<void>(`talent-pool/applications/${appId}/status`, payload),
}
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/types/vacancy.types.ts web-dashboard/src/services/vacancy.service.ts
git commit -m "feat(vacancy): add vacancy types and frontend service"
```

---

## Task 8: Frontend — VacancyListPage

**Files:**
- Create: `web-dashboard/src/pages/TalentPool/components/VacancyStatusBadge.tsx`
- Create: `web-dashboard/src/pages/TalentPool/VacancyListPage.tsx`
- Create: `web-dashboard/src/pages/TalentPool/VacancyListPage.module.css`

- [ ] **Step 1: VacancyStatusBadge**

```tsx
// web-dashboard/src/pages/TalentPool/components/VacancyStatusBadge.tsx
import type { VacancyStatus } from '@/types/vacancy.types'

const CONFIG: Record<VacancyStatus, { label: string; color: string }> = {
  draft:  { label: 'Draft',  color: '#6b7280' },
  open:   { label: 'Open',   color: '#16a34a' },
  closed: { label: 'Closed', color: '#dc2626' },
  filled: { label: 'Filled', color: '#2563eb' },
}

export function VacancyStatusBadge({ status }: { status: VacancyStatus }) {
  const cfg = CONFIG[status] ?? { label: status, color: '#6b7280' }
  return (
    <span style={{
      display: 'inline-block',
      padding: '2px 10px',
      borderRadius: 9999,
      fontSize: 12,
      fontWeight: 600,
      color: '#fff',
      background: cfg.color,
    }}>
      {cfg.label}
    </span>
  )
}
```

- [ ] **Step 2: VacancyListPage**

```tsx
// web-dashboard/src/pages/TalentPool/VacancyListPage.tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { vacancyService } from '@/services/vacancy.service'
import { VacancyStatusBadge } from './components/VacancyStatusBadge'
import type { VacancyStatus } from '@/types/vacancy.types'
import styles from './VacancyListPage.module.css'

export default function VacancyListPage() {
  const navigate = useNavigate()
  const [statusFilter, setStatusFilter] = useState<VacancyStatus | ''>('')
  const [page, setPage] = useState(0)
  const limit = 20

  const { data, isLoading, isError } = useQuery({
    queryKey: ['vacancies', statusFilter, page],
    queryFn: () => vacancyService.list({ status: statusFilter || undefined, offset: page * limit, limit }),
  })

  const vacancies = data?.data ?? []
  const total = data?.total ?? 0

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <h1 className={styles.title}>Lowongan Kerja</h1>
        <button className={styles.btnPrimary} onClick={() => navigate('/admin/talent-pool/vacancies/new')}>
          + Buat Lowongan
        </button>
      </div>

      <div className={styles.filters}>
        <select
          className={styles.select}
          value={statusFilter}
          onChange={e => { setStatusFilter(e.target.value as VacancyStatus | ''); setPage(0) }}
        >
          <option value="">Semua Status</option>
          <option value="draft">Draft</option>
          <option value="open">Open</option>
          <option value="closed">Closed</option>
          <option value="filled">Filled</option>
        </select>
      </div>

      {isLoading && <div className={styles.state}>Memuat...</div>}
      {isError && <div className={styles.stateError}>Gagal memuat data.</div>}

      {!isLoading && !isError && (
        <>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Judul Posisi</th>
                <th>Partner</th>
                <th>Status</th>
                <th>Quota</th>
                <th>Dibuat</th>
              </tr>
            </thead>
            <tbody>
              {vacancies.length === 0 && (
                <tr><td colSpan={5} className={styles.empty}>Tidak ada lowongan.</td></tr>
              )}
              {vacancies.map(v => (
                <tr key={v.id} className={styles.row} onClick={() => navigate(`/admin/talent-pool/vacancies/${v.id}`)}>
                  <td className={styles.titleCell}>{v.title}</td>
                  <td>{v.partner_id}</td>
                  <td><VacancyStatusBadge status={v.status} /></td>
                  <td>{v.quota}</td>
                  <td>{new Date(v.created_at * 1000).toLocaleDateString('id-ID')}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className={styles.pagination}>
            <button disabled={page === 0} onClick={() => setPage(p => p - 1)}>‹ Prev</button>
            <span>Halaman {page + 1} · {total} total</span>
            <button disabled={(page + 1) * limit >= total} onClick={() => setPage(p => p + 1)}>Next ›</button>
          </div>
        </>
      )}
    </div>
  )
}
```

- [ ] **Step 3: CSS module**

```css
/* web-dashboard/src/pages/TalentPool/VacancyListPage.module.css */
.page { padding: 24px; max-width: 1200px; }
.header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; }
.title { font-size: 20px; font-weight: 700; margin: 0; }
.btnPrimary { background: #2563eb; color: #fff; border: none; border-radius: 6px; padding: 8px 16px; cursor: pointer; font-size: 14px; }
.btnPrimary:hover { background: #1d4ed8; }
.filters { margin-bottom: 16px; }
.select { padding: 6px 12px; border-radius: 6px; border: 1px solid #d1d5db; font-size: 14px; }
.table { width: 100%; border-collapse: collapse; }
.table th { text-align: left; padding: 10px 12px; font-size: 13px; color: #6b7280; border-bottom: 1px solid #e5e7eb; }
.table td { padding: 12px; font-size: 14px; border-bottom: 1px solid #f3f4f6; }
.row { cursor: pointer; }
.row:hover td { background: #f9fafb; }
.titleCell { font-weight: 600; color: #111827; }
.empty { text-align: center; color: #9ca3af; padding: 32px; }
.state { padding: 24px; color: #6b7280; }
.stateError { padding: 24px; color: #dc2626; }
.pagination { display: flex; align-items: center; gap: 12px; margin-top: 16px; font-size: 14px; }
.pagination button { padding: 6px 12px; border-radius: 6px; border: 1px solid #d1d5db; cursor: pointer; background: #fff; }
.pagination button:disabled { opacity: 0.4; cursor: not-allowed; }
```

- [ ] **Step 4: Commit**

```bash
git add web-dashboard/src/pages/TalentPool/components/VacancyStatusBadge.tsx web-dashboard/src/pages/TalentPool/VacancyListPage.tsx web-dashboard/src/pages/TalentPool/VacancyListPage.module.css
git commit -m "feat(vacancy): add VacancyListPage and VacancyStatusBadge"
```

---

## Task 9: Frontend — VacancyFormPage

**Files:**
- Create: `web-dashboard/src/pages/TalentPool/VacancyFormPage.tsx`
- Create: `web-dashboard/src/pages/TalentPool/VacancyFormPage.module.css`

Perlu daftar Partners untuk dropdown. Gunakan existing partner service (endpoint `/partners`).

- [ ] **Step 1: Tulis VacancyFormPage**

```tsx
// web-dashboard/src/pages/TalentPool/VacancyFormPage.tsx
import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { vacancyService } from '@/services/vacancy.service'
import { apiClient } from '@/services/api.client'
import type { CreateVacancyPayload, UpdateVacancyPayload } from '@/types/vacancy.types'
import styles from './VacancyFormPage.module.css'

interface Partner { id: string; name: string }

export default function VacancyFormPage() {
  const navigate = useNavigate()
  const { id } = useParams<{ id?: string }>()
  const isEdit = Boolean(id)
  const qc = useQueryClient()

  const [partnerId, setPartnerId] = useState('')
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [requirements, setRequirements] = useState('')
  const [quota, setQuota] = useState(1)
  const [salaryMin, setSalaryMin] = useState('')
  const [salaryMax, setSalaryMax] = useState('')
  const [postedByRole, setPostedByRole] = useState('staff')
  const [error, setError] = useState('')

  const { data: partnersData } = useQuery({
    queryKey: ['partners-list-form'],
    queryFn: () => apiClient.get<any>('partners').then((r: any) => r?.data ?? r),
  })
  const partners: Partner[] = partnersData ?? []

  const { data: existing } = useQuery({
    queryKey: ['vacancy', id],
    queryFn: () => vacancyService.getById(id!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (existing) {
      setPartnerId(existing.partner_id)
      setTitle(existing.title)
      setDescription(existing.description)
      setRequirements(existing.requirements)
      setQuota(existing.quota)
      if (existing.salary?.min) setSalaryMin(String(existing.salary.min))
      if (existing.salary?.max) setSalaryMax(String(existing.salary.max))
    }
  }, [existing])

  const createMut = useMutation({
    mutationFn: (p: CreateVacancyPayload) => vacancyService.create(p),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['vacancies'] }); navigate('/admin/talent-pool/vacancies') },
    onError: () => setError('Gagal menyimpan lowongan.'),
  })

  const updateMut = useMutation({
    mutationFn: (p: UpdateVacancyPayload) => vacancyService.update(id!, p),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['vacancy', id] }); navigate(`/admin/talent-pool/vacancies/${id}`) },
    onError: () => setError('Gagal memperbarui lowongan.'),
  })

  const salary = (salaryMin || salaryMax)
    ? { min: salaryMin ? Number(salaryMin) : undefined, max: salaryMax ? Number(salaryMax) : undefined, currency: 'IDR' }
    : undefined

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    if (!title || !partnerId || quota < 1) { setError('Partner, judul, dan quota wajib diisi.'); return }
    if (isEdit) {
      updateMut.mutate({ title, description, requirements, salary, quota })
    } else {
      createMut.mutate({ partner_id: partnerId, title, description, requirements, salary, quota, posted_by_role: postedByRole })
    }
  }

  const isLoading = createMut.isPending || updateMut.isPending

  return (
    <div className={styles.page}>
      <h1 className={styles.title}>{isEdit ? 'Edit Lowongan' : 'Buat Lowongan'}</h1>
      <form className={styles.form} onSubmit={handleSubmit}>
        {!isEdit && (
          <div className={styles.field}>
            <label>Partner *</label>
            <select value={partnerId} onChange={e => setPartnerId(e.target.value)} required>
              <option value="">Pilih partner...</option>
              {partners.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
          </div>
        )}
        <div className={styles.field}>
          <label>Judul Posisi *</label>
          <input value={title} onChange={e => setTitle(e.target.value)} placeholder="e.g. Frontend Developer" required />
        </div>
        <div className={styles.field}>
          <label>Deskripsi</label>
          <textarea value={description} onChange={e => setDescription(e.target.value)} rows={4} />
        </div>
        <div className={styles.field}>
          <label>Persyaratan</label>
          <textarea value={requirements} onChange={e => setRequirements(e.target.value)} rows={4} />
        </div>
        <div className={styles.row2}>
          <div className={styles.field}>
            <label>Quota *</label>
            <input type="number" min={1} value={quota} onChange={e => setQuota(Number(e.target.value))} required />
          </div>
          {!isEdit && (
            <div className={styles.field}>
              <label>Dibuat oleh</label>
              <select value={postedByRole} onChange={e => setPostedByRole(e.target.value)}>
                <option value="staff">Staff</option>
                <option value="partner">Partner</option>
              </select>
            </div>
          )}
        </div>
        <div className={styles.row2}>
          <div className={styles.field}>
            <label>Gaji Min (IDR)</label>
            <input type="number" value={salaryMin} onChange={e => setSalaryMin(e.target.value)} placeholder="Opsional" />
          </div>
          <div className={styles.field}>
            <label>Gaji Max (IDR)</label>
            <input type="number" value={salaryMax} onChange={e => setSalaryMax(e.target.value)} placeholder="Opsional" />
          </div>
        </div>
        {error && <div className={styles.error}>{error}</div>}
        <div className={styles.actions}>
          <button type="button" className={styles.btnSecondary} onClick={() => navigate(-1)}>Batal</button>
          <button type="submit" className={styles.btnPrimary} disabled={isLoading}>
            {isLoading ? 'Menyimpan...' : 'Simpan'}
          </button>
        </div>
      </form>
    </div>
  )
}
```

- [ ] **Step 2: CSS module**

```css
/* web-dashboard/src/pages/TalentPool/VacancyFormPage.module.css */
.page { padding: 24px; max-width: 640px; }
.title { font-size: 20px; font-weight: 700; margin-bottom: 24px; }
.form { display: flex; flex-direction: column; gap: 16px; }
.field { display: flex; flex-direction: column; gap: 6px; }
.field label { font-size: 13px; font-weight: 600; color: #374151; }
.field input, .field select, .field textarea { padding: 8px 12px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 14px; }
.field textarea { resize: vertical; }
.row2 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.error { color: #dc2626; font-size: 13px; }
.actions { display: flex; gap: 12px; justify-content: flex-end; }
.btnPrimary { background: #2563eb; color: #fff; border: none; border-radius: 6px; padding: 9px 20px; cursor: pointer; font-size: 14px; }
.btnPrimary:disabled { opacity: 0.5; cursor: not-allowed; }
.btnSecondary { background: #fff; color: #374151; border: 1px solid #d1d5db; border-radius: 6px; padding: 9px 20px; cursor: pointer; font-size: 14px; }
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/TalentPool/VacancyFormPage.tsx web-dashboard/src/pages/TalentPool/VacancyFormPage.module.css
git commit -m "feat(vacancy): add VacancyFormPage (create + edit)"
```

---

## Task 10: Frontend — VacancyDetailPage

**Files:**
- Create: `web-dashboard/src/pages/TalentPool/components/ApplicationStatusBadge.tsx`
- Create: `web-dashboard/src/pages/TalentPool/components/RecommendTalentModal.tsx`
- Create: `web-dashboard/src/pages/TalentPool/VacancyDetailPage.tsx`
- Create: `web-dashboard/src/pages/TalentPool/VacancyDetailPage.module.css`

- [ ] **Step 1: ApplicationStatusBadge**

```tsx
// web-dashboard/src/pages/TalentPool/components/ApplicationStatusBadge.tsx
import type { ApplicationStatus } from '@/types/vacancy.types'

const CONFIG: Record<ApplicationStatus, { label: string; color: string }> = {
  applied:   { label: 'Applied',    color: '#6b7280' },
  reviewed:  { label: 'Reviewed',   color: '#d97706' },
  interview: { label: 'Interview',  color: '#2563eb' },
  hired:     { label: 'Hired',      color: '#16a34a' },
  rejected:  { label: 'Rejected',   color: '#dc2626' },
}

export function ApplicationStatusBadge({ status }: { status: ApplicationStatus }) {
  const cfg = CONFIG[status] ?? { label: status, color: '#6b7280' }
  return (
    <span style={{
      display: 'inline-block',
      padding: '2px 10px',
      borderRadius: 9999,
      fontSize: 12,
      fontWeight: 600,
      color: '#fff',
      background: cfg.color,
    }}>
      {cfg.label}
    </span>
  )
}
```

- [ ] **Step 2: RecommendTalentModal**

```tsx
// web-dashboard/src/pages/TalentPool/components/RecommendTalentModal.tsx
import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { talentPoolService } from '@/services/talentpool.service'
import { vacancyService } from '@/services/vacancy.service'

interface Props {
  vacancyId: string
  onClose: () => void
}

export function RecommendTalentModal({ vacancyId, onClose }: Props) {
  const qc = useQueryClient()
  const [selectedId, setSelectedId] = useState('')
  const [error, setError] = useState('')

  const { data } = useQuery({
    queryKey: ['talentpool-active'],
    queryFn: () => talentPoolService.list({ status: 'active', limit: 100 }),
  })
  const talents = data?.data ?? []

  const mut = useMutation({
    mutationFn: () => vacancyService.createApplication(vacancyId, {
      talent_pool_id: selectedId,
      applicant_type: 'recommended',
    }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['vacancy-applications', vacancyId] })
      onClose()
    },
    onError: () => setError('Gagal merekomendasikan talent.'),
  })

  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 999,
    }}>
      <div style={{ background: '#fff', borderRadius: 12, padding: 24, width: 440, maxHeight: '80vh', overflow: 'auto' }}>
        <h2 style={{ margin: '0 0 16px', fontSize: 16, fontWeight: 700 }}>Rekomendasikan Talent</h2>
        <select
          style={{ width: '100%', padding: '8px 12px', border: '1px solid #d1d5db', borderRadius: 6, fontSize: 14, marginBottom: 16 }}
          value={selectedId}
          onChange={e => setSelectedId(e.target.value)}
        >
          <option value="">Pilih talent...</option>
          {talents.map((t: any) => (
            <option key={t.id} value={t.id}>{t.participant_name} — {t.participant_email}</option>
          ))}
        </select>
        {error && <div style={{ color: '#dc2626', fontSize: 13, marginBottom: 8 }}>{error}</div>}
        <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
          <button
            style={{ padding: '8px 16px', borderRadius: 6, border: '1px solid #d1d5db', cursor: 'pointer', background: '#fff' }}
            onClick={onClose}
          >Batal</button>
          <button
            style={{ padding: '8px 16px', borderRadius: 6, border: 'none', background: '#2563eb', color: '#fff', cursor: 'pointer' }}
            disabled={!selectedId || mut.isPending}
            onClick={() => mut.mutate()}
          >
            {mut.isPending ? 'Mengirim...' : 'Rekomendasikan'}
          </button>
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 3: VacancyDetailPage**

```tsx
// web-dashboard/src/pages/TalentPool/VacancyDetailPage.tsx
import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { vacancyService } from '@/services/vacancy.service'
import { VacancyStatusBadge } from './components/VacancyStatusBadge'
import { ApplicationStatusBadge } from './components/ApplicationStatusBadge'
import { RecommendTalentModal } from './components/RecommendTalentModal'
import type { ApplicationStatus } from '@/types/vacancy.types'
import styles from './VacancyDetailPage.module.css'

type Tab = 'info' | 'applications'

export default function VacancyDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const qc = useQueryClient()
  const [activeTab, setActiveTab] = useState<Tab>('info')
  const [showModal, setShowModal] = useState(false)

  const { data: vacancy, isLoading } = useQuery({
    queryKey: ['vacancy', id],
    queryFn: () => vacancyService.getById(id!),
    enabled: Boolean(id),
  })

  const { data: appsData } = useQuery({
    queryKey: ['vacancy-applications', id],
    queryFn: () => vacancyService.listApplications(id!),
    enabled: activeTab === 'applications' && Boolean(id),
  })
  const applications = appsData?.data ?? []

  const statusMut = useMutation({
    mutationFn: (status: string) => vacancyService.updateStatus(id!, status),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['vacancy', id] }),
  })

  const appStatusMut = useMutation({
    mutationFn: ({ appId, status }: { appId: string; status: ApplicationStatus }) =>
      vacancyService.updateApplicationStatus(appId, { status, notes: '' }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['vacancy-applications', id] }),
  })

  if (isLoading) return <div style={{ padding: 24 }}>Memuat...</div>
  if (!vacancy) return <div style={{ padding: 24 }}>Lowongan tidak ditemukan.</div>

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <button className={styles.back} onClick={() => navigate('/admin/talent-pool/vacancies')}>← Kembali</button>
        <div className={styles.headerRight}>
          <VacancyStatusBadge status={vacancy.status} />
          {vacancy.status === 'draft' && (
            <button className={styles.btnAction} onClick={() => statusMut.mutate('open')}>Publish (Open)</button>
          )}
          {vacancy.status === 'open' && (
            <button className={styles.btnAction} onClick={() => statusMut.mutate('closed')}>Tutup Lowongan</button>
          )}
          <button className={styles.btnEdit} onClick={() => navigate(`/admin/talent-pool/vacancies/${id}/edit`)}>Edit</button>
        </div>
      </div>

      <h1 className={styles.title}>{vacancy.title}</h1>

      <div className={styles.tabs}>
        <button className={activeTab === 'info' ? styles.tabActive : styles.tab} onClick={() => setActiveTab('info')}>Informasi</button>
        <button className={activeTab === 'applications' ? styles.tabActive : styles.tab} onClick={() => setActiveTab('applications')}>Aplikasi</button>
      </div>

      {activeTab === 'info' && (
        <div className={styles.infoSection}>
          <div className={styles.field}><span className={styles.label}>Quota</span><span>{vacancy.quota}</span></div>
          <div className={styles.field}><span className={styles.label}>Diposting oleh</span><span>{vacancy.posted_by_role}</span></div>
          {vacancy.salary && (
            <div className={styles.field}>
              <span className={styles.label}>Gaji</span>
              <span>{vacancy.salary.currency} {vacancy.salary.min?.toLocaleString()} – {vacancy.salary.max?.toLocaleString()}</span>
            </div>
          )}
          {vacancy.description && (
            <div className={styles.fieldBlock}><span className={styles.label}>Deskripsi</span><p>{vacancy.description}</p></div>
          )}
          {vacancy.requirements && (
            <div className={styles.fieldBlock}><span className={styles.label}>Persyaratan</span><p>{vacancy.requirements}</p></div>
          )}
        </div>
      )}

      {activeTab === 'applications' && (
        <div className={styles.appsSection}>
          <div className={styles.appsHeader}>
            <span>{applications.length} Pelamar</span>
            {vacancy.status === 'open' && (
              <button className={styles.btnPrimary} onClick={() => setShowModal(true)}>+ Rekomendasikan Talent</button>
            )}
          </div>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Talent Pool ID</th>
                <th>Tipe</th>
                <th>Status</th>
                <th>Tanggal Apply</th>
                <th>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {applications.length === 0 && (
                <tr><td colSpan={5} style={{ textAlign: 'center', color: '#9ca3af', padding: 24 }}>Belum ada pelamar.</td></tr>
              )}
              {applications.map(app => (
                <tr key={app.id}>
                  <td>{app.talent_pool_id.slice(0, 8)}…</td>
                  <td>{app.applicant_type}</td>
                  <td><ApplicationStatusBadge status={app.status} /></td>
                  <td>{new Date(app.applied_at * 1000).toLocaleDateString('id-ID')}</td>
                  <td>
                    {app.status === 'applied' && <button className={styles.btnSm} onClick={() => appStatusMut.mutate({ appId: app.id, status: 'reviewed' })}>Review</button>}
                    {app.status === 'reviewed' && <button className={styles.btnSm} onClick={() => appStatusMut.mutate({ appId: app.id, status: 'interview' })}>Interview</button>}
                    {app.status === 'interview' && (
                      <>
                        <button className={styles.btnSmSuccess} onClick={() => appStatusMut.mutate({ appId: app.id, status: 'hired' })}>Hire</button>
                        <button className={styles.btnSmDanger} onClick={() => appStatusMut.mutate({ appId: app.id, status: 'rejected' })}>Reject</button>
                      </>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {showModal && <RecommendTalentModal vacancyId={id!} onClose={() => setShowModal(false)} />}
    </div>
  )
}
```

- [ ] **Step 4: CSS module**

```css
/* web-dashboard/src/pages/TalentPool/VacancyDetailPage.module.css */
.page { padding: 24px; max-width: 900px; }
.header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
.headerRight { display: flex; align-items: center; gap: 8px; }
.back { background: none; border: none; color: #2563eb; cursor: pointer; font-size: 14px; padding: 0; }
.title { font-size: 22px; font-weight: 700; margin: 0 0 16px; }
.btnAction { background: #2563eb; color: #fff; border: none; border-radius: 6px; padding: 6px 14px; cursor: pointer; font-size: 13px; }
.btnEdit { background: #fff; color: #374151; border: 1px solid #d1d5db; border-radius: 6px; padding: 6px 14px; cursor: pointer; font-size: 13px; }
.tabs { display: flex; gap: 0; border-bottom: 2px solid #e5e7eb; margin-bottom: 20px; }
.tab { background: none; border: none; padding: 10px 20px; font-size: 14px; cursor: pointer; color: #6b7280; border-bottom: 2px solid transparent; margin-bottom: -2px; }
.tabActive { background: none; border: none; padding: 10px 20px; font-size: 14px; cursor: pointer; color: #2563eb; font-weight: 600; border-bottom: 2px solid #2563eb; margin-bottom: -2px; }
.infoSection { display: flex; flex-direction: column; gap: 14px; }
.field { display: flex; gap: 12px; align-items: baseline; }
.fieldBlock { display: flex; flex-direction: column; gap: 4px; }
.label { font-size: 13px; font-weight: 600; color: #6b7280; min-width: 120px; }
.appsSection { display: flex; flex-direction: column; gap: 12px; }
.appsHeader { display: flex; align-items: center; justify-content: space-between; }
.btnPrimary { background: #2563eb; color: #fff; border: none; border-radius: 6px; padding: 7px 14px; cursor: pointer; font-size: 13px; }
.table { width: 100%; border-collapse: collapse; }
.table th { text-align: left; padding: 10px 12px; font-size: 13px; color: #6b7280; border-bottom: 1px solid #e5e7eb; }
.table td { padding: 12px; font-size: 14px; border-bottom: 1px solid #f3f4f6; }
.btnSm { background: #fff; border: 1px solid #d1d5db; border-radius: 4px; padding: 4px 10px; cursor: pointer; font-size: 12px; margin-right: 4px; }
.btnSmSuccess { background: #16a34a; color: #fff; border: none; border-radius: 4px; padding: 4px 10px; cursor: pointer; font-size: 12px; margin-right: 4px; }
.btnSmDanger { background: #dc2626; color: #fff; border: none; border-radius: 4px; padding: 4px 10px; cursor: pointer; font-size: 12px; }
```

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/pages/TalentPool/components/ApplicationStatusBadge.tsx web-dashboard/src/pages/TalentPool/components/RecommendTalentModal.tsx web-dashboard/src/pages/TalentPool/VacancyDetailPage.tsx web-dashboard/src/pages/TalentPool/VacancyDetailPage.module.css
git commit -m "feat(vacancy): add VacancyDetailPage with tabs and RecommendTalentModal"
```

---

## Task 11: Routing + Nav

**Files:**
- Modify: App.tsx / router config — tambah 4 routes
- Modify: Sidebar nav — tambah sub-item "Lowongan"

- [ ] **Step 1: Cari router file**

```bash
grep -rn "TalentPool\|talentpool\|talent-pool" web-dashboard/src/App.tsx web-dashboard/src/router.tsx web-dashboard/src/routes.tsx 2>/dev/null | head -20
```

- [ ] **Step 2: Tambah routes**

Di file yang ditemukan (App.tsx atau router.tsx), tambahkan 4 routes baru di bawah route TalentPool yang sudah ada:

```tsx
import VacancyListPage from '@/pages/TalentPool/VacancyListPage'
import VacancyFormPage from '@/pages/TalentPool/VacancyFormPage'
import VacancyDetailPage from '@/pages/TalentPool/VacancyDetailPage'

// Routes baru:
{ path: '/admin/talent-pool/vacancies', element: <VacancyListPage /> },
{ path: '/admin/talent-pool/vacancies/new', element: <VacancyFormPage /> },
{ path: '/admin/talent-pool/vacancies/:id', element: <VacancyDetailPage /> },
{ path: '/admin/talent-pool/vacancies/:id/edit', element: <VacancyFormPage /> },
```

- [ ] **Step 3: Cari nav/sidebar file**

```bash
grep -rn "TalentPool\|talent-pool\|Lowongan\|Pipeline" web-dashboard/src/components/ web-dashboard/src/layouts/ 2>/dev/null | grep -i "nav\|sidebar\|menu" | head -20
```

- [ ] **Step 4: Tambah nav item**

Di file sidebar yang ditemukan, tambahkan sub-item "Lowongan" di bawah sub-item TalentPool yang sudah ada:

```tsx
{ label: 'Lowongan', path: '/admin/talent-pool/vacancies' }
```

- [ ] **Step 5: Build frontend check**

```bash
cd web-dashboard && npm run build 2>&1 | tail -20
```

Expected: Build succeeds, no TypeScript errors.

- [ ] **Step 6: Commit**

```bash
git add -p
git commit -m "feat(vacancy): wire vacancy routes and add nav sub-item"
```

---

## Self-Review Checklist

- [x] Migration: tabel vacancies + vacancy_applications + indexes
- [x] Domain: Vacancy + VacancyApplication entities, status transitions, business rules
- [x] Repository: full CRUD + CountHired + ExistsApplication
- [x] Commands: create, update, update_status, delete, create_application, update_application_status
- [x] Auto-placed: hired → TalentPool.MarkPlaced ✓
- [x] Auto-filled: hired_count >= quota → vacancy.status = filled ✓
- [x] Error mapping: 409 duplicate, 422 invalid transition/talent not active
- [x] Queries: list_vacancies, get_vacancy, list_applications (per vacancy + all)
- [x] HTTP Handler: all 10 endpoints + RegisterVacancyRoutes
- [x] Frontend: types, service, 3 pages, 3 components
- [x] Routing + nav wired
