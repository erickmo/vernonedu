# Leads: Phone Mandatory + Source Entity + Interest Multi-Link — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make phone mandatory, convert source to a managed entity, and replace the free-text interest field with a multi-link to MasterCourse/CourseType/CourseBatch.

**Architecture:** New `lead_sources` and `lead_interests` DB tables. New LeadSource and LeadInterest domain structs + repos. Five new commands, one new query. Updated lead handler + settings handler. Frontend: new Settings pages for source management, updated Lead form/detail/list pages.

**Tech Stack:** Go (Chi, sqlx, Uber FX), React 18 + TypeScript, TanStack Query, FormPageTemplate / ListPageTemplate / DetailPageTemplate widgets.

**Spec:** `docs/superpowers/specs/2026-05-06-leads-phone-source-interest-design.md`

---

## File Map

### API — New files
- `api/migrations/078_lead_sources_and_interests.sql`
- `api/internal/command/create_lead_source/command.go`
- `api/internal/command/create_lead_source/handler.go`
- `api/internal/command/update_lead_source/command.go`
- `api/internal/command/update_lead_source/handler.go`
- `api/internal/command/delete_lead_source/command.go`
- `api/internal/command/delete_lead_source/handler.go`
- `api/internal/command/add_lead_interest/command.go`
- `api/internal/command/add_lead_interest/handler.go`
- `api/internal/command/remove_lead_interest/command.go`
- `api/internal/command/remove_lead_interest/handler.go`
- `api/internal/query/list_lead_sources/query.go`
- `api/internal/query/list_lead_sources/handler.go`
- `api/infrastructure/database/lead_source_repository.go`
- `api/infrastructure/database/lead_interest_repository.go`

### API — Modified files
- `api/internal/domain/lead/lead.go`
- `api/internal/domain/lead/lead_test.go`
- `api/internal/command/create_lead/command.go`
- `api/internal/command/create_lead/handler.go`
- `api/internal/command/update_lead/command.go`
- `api/internal/command/update_lead/handler.go`
- `api/internal/query/get_lead/handler.go`
- `api/internal/query/list_lead/handler.go`
- `api/internal/query/list_lead/query.go`
- `api/infrastructure/database/lead_repository.go`
- `api/internal/delivery/http/lead_handler.go`
- `api/internal/delivery/http/settings_handler.go`
- `api/cmd/api/main.go`

### Frontend — New files
- `web-dashboard/src/services/lead-source.service.ts`
- `web-dashboard/src/pages/Settings/LeadSourceListPage.tsx`
- `web-dashboard/src/pages/Settings/LeadSourceFormPage.tsx`

### Frontend — Modified files
- `web-dashboard/src/services/lead.service.ts`
- `web-dashboard/src/app/routes.tsx`
- `web-dashboard/src/pages/Leads/LeadFormPage.tsx`
- `web-dashboard/src/pages/Leads/LeadDetailPage.tsx`
- `web-dashboard/src/pages/Leads/LeadListPage.tsx`

---

## Task 1: DB Migration

**Files:**
- Create: `api/migrations/078_lead_sources_and_interests.sql`

- [ ] **Step 1: Write migration file**

```sql
-- 078_lead_sources_and_interests.sql

-- Lead sources entity table
CREATE TABLE lead_sources (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT        NOT NULL,
    is_active  BOOLEAN     NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default sources (mirrors old enum)
INSERT INTO lead_sources (name) VALUES
    ('Referral'),
    ('Media Sosial'),
    ('Walk In'),
    ('Website'),
    ('Lainnya');

-- Lead interests: multi-link to course entities
CREATE TABLE lead_interests (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id     UUID        NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    entity_type TEXT        NOT NULL CHECK (entity_type IN ('master_course', 'course_type', 'course_batch')),
    entity_id   UUID        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lead_interests_lead_id ON lead_interests(lead_id);

-- Update leads table: drop old string columns, add FK
ALTER TABLE leads DROP COLUMN IF EXISTS interest;
ALTER TABLE leads DROP COLUMN IF EXISTS source;
ALTER TABLE leads ADD COLUMN source_id UUID REFERENCES lead_sources(id) ON DELETE SET NULL;
```

- [ ] **Step 2: Apply migration**

```bash
cd api && make migrate-up
```

Expected: `Applying migration 078_lead_sources_and_interests.sql... OK`

- [ ] **Step 3: Commit**

```bash
git add api/migrations/078_lead_sources_and_interests.sql
git commit -m "feat(leads): add lead_sources and lead_interests tables"
```

---

## Task 2: Domain Model

**Files:**
- Modify: `api/internal/domain/lead/lead.go`
- Modify: `api/internal/domain/lead/lead_test.go`

- [ ] **Step 1: Write failing test**

In `api/internal/domain/lead/lead_test.go`, replace the test file content:

```go
package lead_test

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

func TestNewLead_Success(t *testing.T) {
	sourceID := uuid.New()
	l, err := lead.NewLead("Alice", "alice@example.com", "08123456789", &sourceID, "notes", nil)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if l.Name != "Alice" {
		t.Errorf("expected name Alice, got %s", l.Name)
	}
	if l.Status != "new" {
		t.Errorf("expected status new, got %s", l.Status)
	}
	if l.SourceID == nil || *l.SourceID != sourceID {
		t.Errorf("expected source_id %v, got %v", sourceID, l.SourceID)
	}
}

func TestNewLead_EmptyPhone_ReturnsError(t *testing.T) {
	_, err := lead.NewLead("Bob", "", "", nil, "", nil)
	if err == nil {
		t.Fatal("expected error for empty phone")
	}
	if err != lead.ErrPhoneRequired {
		t.Errorf("expected ErrPhoneRequired, got %v", err)
	}
}

func TestNewLead_EmptyName_ReturnsError(t *testing.T) {
	_, err := lead.NewLead("", "email@example.com", "0812345", nil, "", nil)
	if err == nil {
		t.Fatal("expected error for empty name")
	}
	if err != lead.ErrInvalidName {
		t.Errorf("expected ErrInvalidName, got %v", err)
	}
}

func TestNewLead_NilSourceID(t *testing.T) {
	l, err := lead.NewLead("Carol", "carol@example.com", "081234", nil, "", nil)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if l.SourceID != nil {
		t.Errorf("expected nil source_id, got %v", l.SourceID)
	}
}

func TestNewLead_WithPicID(t *testing.T) {
	picID := uuid.New()
	l, err := lead.NewLead("Dave", "dave@example.com", "081234", nil, "", &picID)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if l.PicID == nil || *l.PicID != picID {
		t.Errorf("expected pic_id %v, got %v", picID, l.PicID)
	}
}

func TestNewLeadSource_Success(t *testing.T) {
	s := lead.NewLeadSource("Referral")
	if s.Name != "Referral" {
		t.Errorf("expected name Referral, got %s", s.Name)
	}
	if !s.IsActive {
		t.Error("expected is_active true")
	}
	if s.ID == uuid.Nil {
		t.Error("expected non-nil ID")
	}
}

func TestNewLeadInterest_Success(t *testing.T) {
	leadID := uuid.New()
	entityID := uuid.New()
	i := lead.NewLeadInterest(leadID, "master_course", entityID)
	if i.LeadID != leadID {
		t.Errorf("expected lead_id %v", leadID)
	}
	if i.EntityType != "master_course" {
		t.Errorf("expected entity_type master_course, got %s", i.EntityType)
	}
	if i.EntityID != entityID {
		t.Errorf("expected entity_id %v", entityID)
	}
}

func TestNewCrmLog_Success(t *testing.T) {
	leadID := uuid.New()
	contactedByID := uuid.New()
	followUp := time.Now().Add(24 * time.Hour)

	crmLog := lead.NewCrmLog(leadID, contactedByID, "phone", "interested", &followUp)

	if crmLog.LeadID != leadID {
		t.Errorf("expected lead_id %v", leadID)
	}
	if crmLog.ContactMethod != "phone" {
		t.Errorf("expected contact_method phone, got %s", crmLog.ContactMethod)
	}
	if crmLog.FollowUpDate == nil {
		t.Fatal("expected follow_up_date to be set")
	}
}

func TestNewCrmLog_NilFollowUpDate(t *testing.T) {
	crmLog := lead.NewCrmLog(uuid.New(), uuid.New(), "email", "no response", nil)
	if crmLog.FollowUpDate != nil {
		t.Errorf("expected nil follow_up_date")
	}
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd api && go test ./internal/domain/lead/... -v 2>&1 | head -30
```

Expected: FAIL (ErrPhoneRequired undefined, NewLead signature mismatch, etc.)

- [ ] **Step 3: Update domain model**

Replace `api/internal/domain/lead/lead.go`:

```go
package lead

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName  = errors.New("invalid lead name")
	ErrPhoneRequired = errors.New("phone is required")
	ErrLeadNotFound = errors.New("lead not found")
	ErrSourceNotFound = errors.New("lead source not found")
	ErrInterestNotFound = errors.New("lead interest not found")
)

type Lead struct {
	ID        uuid.UUID
	Name      string
	Email     string
	Phone     string
	SourceID  *uuid.UUID
	Notes     string
	Status    string
	PicID     *uuid.UUID
	CreatedAt time.Time
	UpdatedAt time.Time
}

func NewLead(name, email, phone string, sourceID *uuid.UUID, notes string, picID *uuid.UUID) (*Lead, error) {
	if name == "" {
		return nil, ErrInvalidName
	}
	if phone == "" {
		return nil, ErrPhoneRequired
	}
	return &Lead{
		ID:        uuid.New(),
		Name:      name,
		Email:     email,
		Phone:     phone,
		SourceID:  sourceID,
		Notes:     notes,
		Status:    "new",
		PicID:     picID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

type LeadSource struct {
	ID        uuid.UUID
	Name      string
	IsActive  bool
	CreatedAt time.Time
	UpdatedAt time.Time
}

func NewLeadSource(name string) *LeadSource {
	return &LeadSource{
		ID:        uuid.New(),
		Name:      name,
		IsActive:  true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

type LeadInterest struct {
	ID         uuid.UUID
	LeadID     uuid.UUID
	EntityType string
	EntityID   uuid.UUID
	EntityName string
	CreatedAt  time.Time
}

func NewLeadInterest(leadID uuid.UUID, entityType string, entityID uuid.UUID) *LeadInterest {
	return &LeadInterest{
		ID:         uuid.New(),
		LeadID:     leadID,
		EntityType: entityType,
		EntityID:   entityID,
		CreatedAt:  time.Now(),
	}
}

type CrmLog struct {
	ID            uuid.UUID
	LeadID        uuid.UUID
	ContactedByID uuid.UUID
	ContactMethod string
	Response      string
	FollowUpDate  *time.Time
	CreatedAt     time.Time
}

func NewCrmLog(leadID, contactedByID uuid.UUID, contactMethod, response string, followUpDate *time.Time) *CrmLog {
	return &CrmLog{
		ID:            uuid.New(),
		LeadID:        leadID,
		ContactedByID: contactedByID,
		ContactMethod: contactMethod,
		Response:      response,
		FollowUpDate:  followUpDate,
		CreatedAt:     time.Now(),
	}
}

type WriteRepository interface {
	Save(ctx context.Context, l *Lead) error
	Update(ctx context.Context, l *Lead) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Lead, error)
	List(ctx context.Context, offset, limit int, status, sourceID, search, sortBy, sortDir string) ([]*Lead, int, error)
}

type SourceWriteRepository interface {
	SaveSource(ctx context.Context, s *LeadSource) error
	UpdateSource(ctx context.Context, s *LeadSource) error
	DeleteSource(ctx context.Context, id uuid.UUID) error
}

type SourceReadRepository interface {
	GetSourceByID(ctx context.Context, id uuid.UUID) (*LeadSource, error)
	ListSources(ctx context.Context) ([]*LeadSource, error)
}

type InterestWriteRepository interface {
	SaveInterest(ctx context.Context, i *LeadInterest) error
	DeleteInterest(ctx context.Context, leadID, interestID uuid.UUID) error
}

type InterestReadRepository interface {
	ListInterests(ctx context.Context, leadID uuid.UUID) ([]*LeadInterest, error)
}

type CrmLogWriteRepository interface {
	SaveCrmLog(ctx context.Context, log *CrmLog) error
}

type CrmLogReadRepository interface {
	ListCrmLogs(ctx context.Context, leadID uuid.UUID) ([]*CrmLog, error)
}
```

- [ ] **Step 4: Run tests**

```bash
cd api && go test ./internal/domain/lead/... -v
```

Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add api/internal/domain/lead/lead.go api/internal/domain/lead/lead_test.go
git commit -m "feat(leads): update domain model — phone required, source entity, interests"
```

---

## Task 3: Lead Repository (update)

**Files:**
- Modify: `api/infrastructure/database/lead_repository.go`

- [ ] **Step 1: Replace lead_repository.go**

```go
package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadRepository struct {
	db *sqlx.DB
}

func NewLeadRepository(db *sqlx.DB) *LeadRepository {
	return &LeadRepository{db: db}
}

type leadRow struct {
	ID        string         `db:"id"`
	Name      string         `db:"name"`
	Email     string         `db:"email"`
	Phone     string         `db:"phone"`
	SourceID  sql.NullString `db:"source_id"`
	Notes     string         `db:"notes"`
	Status    string         `db:"status"`
	PicID     sql.NullString `db:"pic_id"`
	CreatedAt time.Time      `db:"created_at"`
	UpdatedAt time.Time      `db:"updated_at"`
}

func (row *leadRow) toDomain() (*lead.Lead, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse lead id: %w", err)
	}

	var sourceID *uuid.UUID
	if row.SourceID.Valid && row.SourceID.String != "" {
		parsed, err := uuid.Parse(row.SourceID.String)
		if err != nil {
			return nil, fmt.Errorf("failed to parse lead source_id: %w", err)
		}
		sourceID = &parsed
	}

	var picID *uuid.UUID
	if row.PicID.Valid && row.PicID.String != "" {
		parsed, err := uuid.Parse(row.PicID.String)
		if err != nil {
			return nil, fmt.Errorf("failed to parse lead pic_id: %w", err)
		}
		picID = &parsed
	}

	return &lead.Lead{
		ID:        id,
		Name:      row.Name,
		Email:     row.Email,
		Phone:     row.Phone,
		SourceID:  sourceID,
		Notes:     row.Notes,
		Status:    row.Status,
		PicID:     picID,
		CreatedAt: row.CreatedAt,
		UpdatedAt: row.UpdatedAt,
	}, nil
}

func (r *LeadRepository) Save(ctx context.Context, l *lead.Lead) error {
	var sourceID, picID interface{}
	if l.SourceID != nil {
		sourceID = l.SourceID.String()
	}
	if l.PicID != nil {
		picID = l.PicID.String()
	}
	query := `
		INSERT INTO leads (id, name, email, phone, source_id, notes, status, pic_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	_, err := r.db.ExecContext(ctx, query,
		l.ID.String(), l.Name, l.Email, l.Phone, sourceID, l.Notes, l.Status, picID,
		l.CreatedAt, l.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save lead: %w", err)
	}
	return nil
}

func (r *LeadRepository) Update(ctx context.Context, l *lead.Lead) error {
	var sourceID, picID interface{}
	if l.SourceID != nil {
		sourceID = l.SourceID.String()
	}
	if l.PicID != nil {
		picID = l.PicID.String()
	}
	query := `
		UPDATE leads
		SET name=$1, email=$2, phone=$3, source_id=$4, notes=$5, status=$6, pic_id=$7, updated_at=$8
		WHERE id=$9
	`
	_, err := r.db.ExecContext(ctx, query,
		l.Name, l.Email, l.Phone, sourceID, l.Notes, l.Status, picID, l.UpdatedAt,
		l.ID.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to update lead: %w", err)
	}
	return nil
}

func (r *LeadRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM leads WHERE id=$1`, id.String())
	if err != nil {
		return fmt.Errorf("failed to delete lead: %w", err)
	}
	return nil
}

func (r *LeadRepository) GetByID(ctx context.Context, id uuid.UUID) (*lead.Lead, error) {
	var row leadRow
	query := `SELECT id, name, email, phone, source_id, notes, status, pic_id, created_at, updated_at FROM leads WHERE id=$1`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get lead: %w", err)
	}
	return row.toDomain()
}

var leadListSortCols = map[string]string{
	"name":       "name",
	"status":     "status",
	"created_at": "created_at",
	"updated_at": "updated_at",
}

func (r *LeadRepository) List(ctx context.Context, offset, limit int, status, sourceID, search, sortBy, sortDir string) ([]*lead.Lead, int, error) {
	searchPattern := ""
	if search != "" {
		searchPattern = "%" + search + "%"
	}

	var total int
	countQuery := `
		SELECT COUNT(*) FROM leads
		WHERE ($1='' OR status=$1)
		AND ($2='' OR source_id::text=$2)
		AND ($3='' OR name ILIKE $3)
	`
	if err := r.db.GetContext(ctx, &total, countQuery, status, sourceID, searchPattern); err != nil {
		return nil, 0, fmt.Errorf("failed to count leads: %w", err)
	}

	var rows []leadRow
	orderBy := buildOrderBy(sortBy, sortDir, leadListSortCols, "created_at DESC")
	query := fmt.Sprintf(`
		SELECT id, name, email, phone, source_id, notes, status, pic_id, created_at, updated_at
		FROM leads
		WHERE ($1='' OR status=$1)
		AND ($2='' OR source_id::text=$2)
		AND ($3='' OR name ILIKE $3)
		%s
		LIMIT $4 OFFSET $5
	`, orderBy)
	if err := r.db.SelectContext(ctx, &rows, query, status, sourceID, searchPattern, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list leads: %w", err)
	}

	leads := make([]*lead.Lead, 0, len(rows))
	for _, row := range rows {
		l, err := row.toDomain()
		if err != nil {
			return nil, 0, err
		}
		leads = append(leads, l)
	}
	return leads, total, nil
}

// ─── CRM Logs ──────────────────────────────────────────────────────────────

type leadCrmLogRow struct {
	ID            string       `db:"id"`
	LeadID        string       `db:"lead_id"`
	ContactedByID string       `db:"contacted_by_id"`
	ContactMethod string       `db:"contact_method"`
	Response      string       `db:"response"`
	FollowUpDate  sql.NullTime `db:"follow_up_date"`
	CreatedAt     time.Time    `db:"created_at"`
}

func (row *leadCrmLogRow) toDomain() (*lead.CrmLog, error) {
	id, _ := uuid.Parse(row.ID)
	leadID, _ := uuid.Parse(row.LeadID)
	contactedByID, _ := uuid.Parse(row.ContactedByID)

	var followUpDate *time.Time
	if row.FollowUpDate.Valid {
		t := row.FollowUpDate.Time
		followUpDate = &t
	}

	return &lead.CrmLog{
		ID:            id,
		LeadID:        leadID,
		ContactedByID: contactedByID,
		ContactMethod: row.ContactMethod,
		Response:      row.Response,
		FollowUpDate:  followUpDate,
		CreatedAt:     row.CreatedAt,
	}, nil
}

func (r *LeadRepository) SaveCrmLog(ctx context.Context, l *lead.CrmLog) error {
	var followUpDate interface{}
	if l.FollowUpDate != nil {
		followUpDate = *l.FollowUpDate
	}
	query := `
		INSERT INTO lead_crm_logs (id, lead_id, contacted_by_id, contact_method, response, follow_up_date, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err := r.db.ExecContext(ctx, query,
		l.ID.String(), l.LeadID.String(), l.ContactedByID.String(),
		l.ContactMethod, l.Response, followUpDate, l.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save crm log: %w", err)
	}
	return nil
}

func (r *LeadRepository) ListCrmLogs(ctx context.Context, leadID uuid.UUID) ([]*lead.CrmLog, error) {
	var rows []leadCrmLogRow
	query := `
		SELECT id, lead_id, contacted_by_id, contact_method, response, follow_up_date, created_at
		FROM lead_crm_logs
		WHERE lead_id=$1
		ORDER BY created_at DESC
	`
	if err := r.db.SelectContext(ctx, &rows, query, leadID.String()); err != nil {
		return nil, fmt.Errorf("failed to list crm logs: %w", err)
	}

	logs := make([]*lead.CrmLog, 0, len(rows))
	for _, row := range rows {
		l, err := row.toDomain()
		if err != nil {
			return nil, err
		}
		logs = append(logs, l)
	}
	return logs, nil
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd api && go build ./infrastructure/database/... 2>&1
```

Expected: no errors (may fail until domain model is updated — do Tasks 2 and 3 together)

- [ ] **Step 3: Commit**

```bash
git add api/infrastructure/database/lead_repository.go
git commit -m "feat(leads): update LeadRepository — source_id FK, remove interest/source string"
```

---

## Task 4: LeadSource Repository

**Files:**
- Create: `api/infrastructure/database/lead_source_repository.go`

- [ ] **Step 1: Write lead_source_repository.go**

```go
package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadSourceRepository struct {
	db *sqlx.DB
}

func NewLeadSourceRepository(db *sqlx.DB) *LeadSourceRepository {
	return &LeadSourceRepository{db: db}
}

type leadSourceRow struct {
	ID        string    `db:"id"`
	Name      string    `db:"name"`
	IsActive  bool      `db:"is_active"`
	CreatedAt time.Time `db:"created_at"`
	UpdatedAt time.Time `db:"updated_at"`
}

func (row *leadSourceRow) toDomain() (*lead.LeadSource, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse lead_source id: %w", err)
	}
	return &lead.LeadSource{
		ID:        id,
		Name:      row.Name,
		IsActive:  row.IsActive,
		CreatedAt: row.CreatedAt,
		UpdatedAt: row.UpdatedAt,
	}, nil
}

func (r *LeadSourceRepository) SaveSource(ctx context.Context, s *lead.LeadSource) error {
	query := `
		INSERT INTO lead_sources (id, name, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
	`
	_, err := r.db.ExecContext(ctx, query, s.ID.String(), s.Name, s.IsActive, s.CreatedAt, s.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save lead source: %w", err)
	}
	return nil
}

func (r *LeadSourceRepository) UpdateSource(ctx context.Context, s *lead.LeadSource) error {
	query := `UPDATE lead_sources SET name=$1, is_active=$2, updated_at=$3 WHERE id=$4`
	_, err := r.db.ExecContext(ctx, query, s.Name, s.IsActive, s.UpdatedAt, s.ID.String())
	if err != nil {
		return fmt.Errorf("failed to update lead source: %w", err)
	}
	return nil
}

func (r *LeadSourceRepository) DeleteSource(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM lead_sources WHERE id=$1`, id.String())
	if err != nil {
		return fmt.Errorf("failed to delete lead source: %w", err)
	}
	return nil
}

func (r *LeadSourceRepository) GetSourceByID(ctx context.Context, id uuid.UUID) (*lead.LeadSource, error) {
	var row leadSourceRow
	query := `SELECT id, name, is_active, created_at, updated_at FROM lead_sources WHERE id=$1`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get lead source: %w", err)
	}
	return row.toDomain()
}

func (r *LeadSourceRepository) ListSources(ctx context.Context) ([]*lead.LeadSource, error) {
	var rows []leadSourceRow
	query := `SELECT id, name, is_active, created_at, updated_at FROM lead_sources ORDER BY name`
	if err := r.db.SelectContext(ctx, &rows, query); err != nil {
		return nil, fmt.Errorf("failed to list lead sources: %w", err)
	}
	sources := make([]*lead.LeadSource, 0, len(rows))
	for _, row := range rows {
		s, err := row.toDomain()
		if err != nil {
			return nil, err
		}
		sources = append(sources, s)
	}
	return sources, nil
}
```

- [ ] **Step 2: Compile check**

```bash
cd api && go build ./infrastructure/database/... 2>&1
```

Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add api/infrastructure/database/lead_source_repository.go
git commit -m "feat(leads): add LeadSourceRepository"
```

---

## Task 5: LeadInterest Repository

**Files:**
- Create: `api/infrastructure/database/lead_interest_repository.go`

- [ ] **Step 1: Write lead_interest_repository.go**

```go
package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadInterestRepository struct {
	db *sqlx.DB
}

func NewLeadInterestRepository(db *sqlx.DB) *LeadInterestRepository {
	return &LeadInterestRepository{db: db}
}

type leadInterestRow struct {
	ID         string    `db:"id"`
	LeadID     string    `db:"lead_id"`
	EntityType string    `db:"entity_type"`
	EntityID   string    `db:"entity_id"`
	EntityName string    `db:"entity_name"`
	CreatedAt  time.Time `db:"created_at"`
}

func (row *leadInterestRow) toDomain() (*lead.LeadInterest, error) {
	id, _ := uuid.Parse(row.ID)
	leadID, _ := uuid.Parse(row.LeadID)
	entityID, _ := uuid.Parse(row.EntityID)
	return &lead.LeadInterest{
		ID:         id,
		LeadID:     leadID,
		EntityType: row.EntityType,
		EntityID:   entityID,
		EntityName: row.EntityName,
		CreatedAt:  row.CreatedAt,
	}, nil
}

func (r *LeadInterestRepository) SaveInterest(ctx context.Context, i *lead.LeadInterest) error {
	query := `
		INSERT INTO lead_interests (id, lead_id, entity_type, entity_id, created_at)
		VALUES ($1, $2, $3, $4, $5)
	`
	_, err := r.db.ExecContext(ctx, query,
		i.ID.String(), i.LeadID.String(), i.EntityType, i.EntityID.String(), i.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save lead interest: %w", err)
	}
	return nil
}

func (r *LeadInterestRepository) DeleteInterest(ctx context.Context, leadID, interestID uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`DELETE FROM lead_interests WHERE id=$1 AND lead_id=$2`,
		interestID.String(), leadID.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to delete lead interest: %w", err)
	}
	return nil
}

func (r *LeadInterestRepository) ListInterests(ctx context.Context, leadID uuid.UUID) ([]*lead.LeadInterest, error) {
	var rows []leadInterestRow
	query := `
		SELECT
			li.id, li.lead_id, li.entity_type, li.entity_id, li.created_at,
			COALESCE(mc.course_name, ct.type_name, cb.name, '') AS entity_name
		FROM lead_interests li
		LEFT JOIN master_courses mc ON li.entity_type = 'master_course' AND li.entity_id = mc.id
		LEFT JOIN course_types ct   ON li.entity_type = 'course_type'   AND li.entity_id = ct.id
		LEFT JOIN course_batches cb  ON li.entity_type = 'course_batch'  AND li.entity_id = cb.id
		WHERE li.lead_id = $1
		ORDER BY li.created_at
	`
	if err := r.db.SelectContext(ctx, &rows, query, leadID.String()); err != nil {
		return nil, fmt.Errorf("failed to list lead interests: %w", err)
	}
	interests := make([]*lead.LeadInterest, 0, len(rows))
	for _, row := range rows {
		i, err := row.toDomain()
		if err != nil {
			return nil, err
		}
		interests = append(interests, i)
	}
	return interests, nil
}
```

- [ ] **Step 2: Compile check**

```bash
cd api && go build ./infrastructure/database/... 2>&1
```

Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add api/infrastructure/database/lead_interest_repository.go
git commit -m "feat(leads): add LeadInterestRepository"
```

---

## Task 6: Updated Lead Commands

**Files:**
- Modify: `api/internal/command/create_lead/command.go`
- Modify: `api/internal/command/create_lead/handler.go`
- Modify: `api/internal/command/update_lead/command.go`
- Modify: `api/internal/command/update_lead/handler.go`

- [ ] **Step 1: Update create_lead/command.go**

```go
package create_lead

import "github.com/google/uuid"

type CreateLeadCommand struct {
	Name     string     `validate:"required"`
	Email    string
	Phone    string     `validate:"required"`
	SourceID *uuid.UUID
	Notes    string
	PicID    *uuid.UUID
}
```

- [ ] **Step 2: Update create_lead/handler.go**

```go
package create_lead

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

var ErrInvalidCommand = errors.New("invalid create lead command")

type Handler struct {
	leadWriteRepo lead.WriteRepository
	eventBus      eventbus.EventBus
}

func NewHandler(leadWriteRepo lead.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{leadWriteRepo: leadWriteRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	createCmd, ok := cmd.(*CreateLeadCommand)
	if !ok {
		return ErrInvalidCommand
	}

	newLead, err := lead.NewLead(
		createCmd.Name,
		createCmd.Email,
		createCmd.Phone,
		createCmd.SourceID,
		createCmd.Notes,
		createCmd.PicID,
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to create lead")
		return err
	}

	if err := h.leadWriteRepo.Save(ctx, newLead); err != nil {
		log.Error().Err(err).Msg("failed to save lead")
		return err
	}

	event := &lead.LeadCreatedEvent{
		EventType: "LeadCreated",
		LeadID:    newLead.ID,
		Timestamp: time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish LeadCreated event")
		return err
	}

	log.Info().Str("lead_id", newLead.ID.String()).Msg("lead created successfully")
	return nil
}
```

- [ ] **Step 3: Update update_lead/command.go**

```go
package update_lead

import "github.com/google/uuid"

type UpdateLeadCommand struct {
	ID       uuid.UUID  `validate:"required"`
	Name     string     `validate:"required"`
	Email    string
	Phone    string     `validate:"required"`
	SourceID *uuid.UUID
	Notes    string
	Status   string
	PicID    *uuid.UUID
}
```

- [ ] **Step 4: Update update_lead/handler.go**

```go
package update_lead

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

var ErrInvalidCommand = errors.New("invalid update lead command")

type Handler struct {
	leadReadRepo  lead.ReadRepository
	leadWriteRepo lead.WriteRepository
	eventBus      eventbus.EventBus
}

func NewHandler(leadWriteRepo lead.WriteRepository, leadReadRepo lead.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{leadReadRepo: leadReadRepo, leadWriteRepo: leadWriteRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	updateCmd, ok := cmd.(*UpdateLeadCommand)
	if !ok {
		return ErrInvalidCommand
	}

	existingLead, err := h.leadReadRepo.GetByID(ctx, updateCmd.ID)
	if err != nil {
		if errors.Is(err, lead.ErrLeadNotFound) {
			return lead.ErrLeadNotFound
		}
		log.Error().Err(err).Str("lead_id", updateCmd.ID.String()).Msg("failed to get lead")
		return err
	}

	if updateCmd.Phone == "" {
		return lead.ErrPhoneRequired
	}

	existingLead.Name = updateCmd.Name
	existingLead.Email = updateCmd.Email
	existingLead.Phone = updateCmd.Phone
	existingLead.SourceID = updateCmd.SourceID
	existingLead.Notes = updateCmd.Notes
	existingLead.Status = updateCmd.Status
	existingLead.PicID = updateCmd.PicID
	existingLead.UpdatedAt = time.Now()

	if err := h.leadWriteRepo.Update(ctx, existingLead); err != nil {
		log.Error().Err(err).Msg("failed to update lead")
		return err
	}

	event := &lead.LeadUpdatedEvent{
		EventType: "LeadUpdated",
		LeadID:    existingLead.ID,
		Timestamp: time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish LeadUpdated event")
		return err
	}

	log.Info().Str("lead_id", existingLead.ID.String()).Msg("lead updated successfully")
	return nil
}
```

- [ ] **Step 5: Compile check**

```bash
cd api && go build ./internal/command/create_lead/... ./internal/command/update_lead/... 2>&1
```

Expected: no errors

- [ ] **Step 6: Commit**

```bash
git add api/internal/command/create_lead/ api/internal/command/update_lead/
git commit -m "feat(leads): update create/update lead commands — phone required, source_id"
```

---

## Task 7: Lead Source Commands

**Files:**
- Create: `api/internal/command/create_lead_source/command.go`
- Create: `api/internal/command/create_lead_source/handler.go`
- Create: `api/internal/command/update_lead_source/command.go`
- Create: `api/internal/command/update_lead_source/handler.go`
- Create: `api/internal/command/delete_lead_source/command.go`
- Create: `api/internal/command/delete_lead_source/handler.go`

- [ ] **Step 1: create_lead_source/command.go**

```go
package create_lead_source

import "errors"

var ErrInvalidCommand = errors.New("invalid create lead source command")

type CreateLeadSourceCommand struct {
	Name string `validate:"required"`
}
```

- [ ] **Step 2: create_lead_source/handler.go**

```go
package create_lead_source

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	sourceWriteRepo lead.SourceWriteRepository
}

func NewHandler(sourceWriteRepo lead.SourceWriteRepository) *Handler {
	return &Handler{sourceWriteRepo: sourceWriteRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateLeadSourceCommand)
	if !ok {
		return ErrInvalidCommand
	}
	s := lead.NewLeadSource(c.Name)
	if err := h.sourceWriteRepo.SaveSource(ctx, s); err != nil {
		log.Error().Err(err).Msg("failed to save lead source")
		return err
	}
	log.Info().Str("source_id", s.ID.String()).Msg("lead source created")
	return nil
}
```

- [ ] **Step 3: update_lead_source/command.go**

```go
package update_lead_source

import (
	"errors"

	"github.com/google/uuid"
)

var ErrInvalidCommand = errors.New("invalid update lead source command")

type UpdateLeadSourceCommand struct {
	ID       uuid.UUID `validate:"required"`
	Name     string    `validate:"required"`
	IsActive bool
}
```

- [ ] **Step 4: update_lead_source/handler.go**

```go
package update_lead_source

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	sourceReadRepo  lead.SourceReadRepository
	sourceWriteRepo lead.SourceWriteRepository
}

func NewHandler(sourceWriteRepo lead.SourceWriteRepository, sourceReadRepo lead.SourceReadRepository) *Handler {
	return &Handler{sourceWriteRepo: sourceWriteRepo, sourceReadRepo: sourceReadRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateLeadSourceCommand)
	if !ok {
		return ErrInvalidCommand
	}
	s, err := h.sourceReadRepo.GetSourceByID(ctx, c.ID)
	if err != nil {
		return lead.ErrSourceNotFound
	}
	s.Name = c.Name
	s.IsActive = c.IsActive
	s.UpdatedAt = time.Now()
	if err := h.sourceWriteRepo.UpdateSource(ctx, s); err != nil {
		log.Error().Err(err).Msg("failed to update lead source")
		return err
	}
	log.Info().Str("source_id", s.ID.String()).Msg("lead source updated")
	return nil
}
```

- [ ] **Step 5: delete_lead_source/command.go**

```go
package delete_lead_source

import (
	"errors"

	"github.com/google/uuid"
)

var ErrInvalidCommand = errors.New("invalid delete lead source command")

type DeleteLeadSourceCommand struct {
	ID uuid.UUID `validate:"required"`
}
```

- [ ] **Step 6: delete_lead_source/handler.go**

```go
package delete_lead_source

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	sourceWriteRepo lead.SourceWriteRepository
}

func NewHandler(sourceWriteRepo lead.SourceWriteRepository) *Handler {
	return &Handler{sourceWriteRepo: sourceWriteRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteLeadSourceCommand)
	if !ok {
		return ErrInvalidCommand
	}
	if err := h.sourceWriteRepo.DeleteSource(ctx, c.ID); err != nil {
		log.Error().Err(err).Str("source_id", c.ID.String()).Msg("failed to delete lead source")
		return err
	}
	log.Info().Str("source_id", c.ID.String()).Msg("lead source deleted")
	return nil
}
```

- [ ] **Step 7: Compile check**

```bash
cd api && go build ./internal/command/create_lead_source/... ./internal/command/update_lead_source/... ./internal/command/delete_lead_source/... 2>&1
```

Expected: no errors

- [ ] **Step 8: Commit**

```bash
git add api/internal/command/create_lead_source/ api/internal/command/update_lead_source/ api/internal/command/delete_lead_source/
git commit -m "feat(leads): add lead source CRUD commands"
```

---

## Task 8: Lead Interest Commands

**Files:**
- Create: `api/internal/command/add_lead_interest/command.go`
- Create: `api/internal/command/add_lead_interest/handler.go`
- Create: `api/internal/command/remove_lead_interest/command.go`
- Create: `api/internal/command/remove_lead_interest/handler.go`

- [ ] **Step 1: add_lead_interest/command.go**

```go
package add_lead_interest

import (
	"errors"

	"github.com/google/uuid"
)

var ErrInvalidCommand = errors.New("invalid add lead interest command")

type AddLeadInterestCommand struct {
	LeadID     uuid.UUID `validate:"required"`
	EntityType string    `validate:"required"`
	EntityID   uuid.UUID `validate:"required"`
}
```

- [ ] **Step 2: add_lead_interest/handler.go**

```go
package add_lead_interest

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	interestWriteRepo lead.InterestWriteRepository
}

func NewHandler(interestWriteRepo lead.InterestWriteRepository) *Handler {
	return &Handler{interestWriteRepo: interestWriteRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*AddLeadInterestCommand)
	if !ok {
		return ErrInvalidCommand
	}
	i := lead.NewLeadInterest(c.LeadID, c.EntityType, c.EntityID)
	if err := h.interestWriteRepo.SaveInterest(ctx, i); err != nil {
		log.Error().Err(err).Msg("failed to save lead interest")
		return err
	}
	log.Info().Str("interest_id", i.ID.String()).Msg("lead interest added")
	return nil
}
```

- [ ] **Step 3: remove_lead_interest/command.go**

```go
package remove_lead_interest

import (
	"errors"

	"github.com/google/uuid"
)

var ErrInvalidCommand = errors.New("invalid remove lead interest command")

type RemoveLeadInterestCommand struct {
	LeadID     uuid.UUID `validate:"required"`
	InterestID uuid.UUID `validate:"required"`
}
```

- [ ] **Step 4: remove_lead_interest/handler.go**

```go
package remove_lead_interest

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	interestWriteRepo lead.InterestWriteRepository
}

func NewHandler(interestWriteRepo lead.InterestWriteRepository) *Handler {
	return &Handler{interestWriteRepo: interestWriteRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*RemoveLeadInterestCommand)
	if !ok {
		return ErrInvalidCommand
	}
	if err := h.interestWriteRepo.DeleteInterest(ctx, c.LeadID, c.InterestID); err != nil {
		log.Error().Err(err).Msg("failed to delete lead interest")
		return err
	}
	log.Info().Str("interest_id", c.InterestID.String()).Msg("lead interest removed")
	return nil
}
```

- [ ] **Step 5: Compile check**

```bash
cd api && go build ./internal/command/add_lead_interest/... ./internal/command/remove_lead_interest/... 2>&1
```

Expected: no errors

- [ ] **Step 6: Commit**

```bash
git add api/internal/command/add_lead_interest/ api/internal/command/remove_lead_interest/
git commit -m "feat(leads): add lead interest add/remove commands"
```

---

## Task 9: Query — list_lead_sources

**Files:**
- Create: `api/internal/query/list_lead_sources/query.go`
- Create: `api/internal/query/list_lead_sources/handler.go`

- [ ] **Step 1: query.go**

```go
package list_lead_sources

import "errors"

var ErrInvalidQuery = errors.New("invalid list lead sources query")

type ListLeadSourcesQuery struct{}
```

- [ ] **Step 2: handler.go**

```go
package list_lead_sources

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadSourceReadModel struct {
	ID       uuid.UUID `json:"id"`
	Name     string    `json:"name"`
	IsActive bool      `json:"is_active"`
}

type Handler struct {
	sourceReadRepo lead.SourceReadRepository
}

func NewHandler(sourceReadRepo lead.SourceReadRepository) *Handler {
	return &Handler{sourceReadRepo: sourceReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	if _, ok := query.(*ListLeadSourcesQuery); !ok {
		return nil, ErrInvalidQuery
	}
	sources, err := h.sourceReadRepo.ListSources(ctx)
	if err != nil {
		log.Error().Err(err).Msg("failed to list lead sources")
		return nil, err
	}
	readModels := make([]*LeadSourceReadModel, len(sources))
	for i, s := range sources {
		readModels[i] = &LeadSourceReadModel{
			ID:       s.ID,
			Name:     s.Name,
			IsActive: s.IsActive,
		}
	}
	return readModels, nil
}
```

- [ ] **Step 3: Compile check**

```bash
cd api && go build ./internal/query/list_lead_sources/... 2>&1
```

Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add api/internal/query/list_lead_sources/
git commit -m "feat(leads): add list_lead_sources query"
```

---

## Task 10: Query — get_lead (update)

**Files:**
- Modify: `api/internal/query/get_lead/handler.go`

- [ ] **Step 1: Replace get_lead/handler.go**

```go
package get_lead

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

var ErrInvalidQuery = errors.New("invalid get lead query")

type LeadSourceRM struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}

type LeadInterestRM struct {
	ID         uuid.UUID `json:"id"`
	EntityType string    `json:"entity_type"`
	EntityID   uuid.UUID `json:"entity_id"`
	EntityName string    `json:"entity_name"`
}

type LeadReadModel struct {
	ID        uuid.UUID        `json:"id"`
	Name      string           `json:"name"`
	Email     string           `json:"email"`
	Phone     string           `json:"phone"`
	Source    *LeadSourceRM    `json:"source"`
	Interests []*LeadInterestRM `json:"interests"`
	Notes     string           `json:"notes"`
	Status    string           `json:"status"`
	PicID     *uuid.UUID       `json:"pic_id"`
	CreatedAt int64            `json:"created_at"`
	UpdatedAt int64            `json:"updated_at"`
}

type Handler struct {
	leadReadRepo     lead.ReadRepository
	sourceReadRepo   lead.SourceReadRepository
	interestReadRepo lead.InterestReadRepository
}

func NewHandler(leadReadRepo lead.ReadRepository, sourceReadRepo lead.SourceReadRepository, interestReadRepo lead.InterestReadRepository) *Handler {
	return &Handler{
		leadReadRepo:     leadReadRepo,
		sourceReadRepo:   sourceReadRepo,
		interestReadRepo: interestReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetLeadQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	l, err := h.leadReadRepo.GetByID(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Str("lead_id", q.ID.String()).Msg("failed to get lead")
		return nil, err
	}

	var sourceRM *LeadSourceRM
	if l.SourceID != nil {
		s, err := h.sourceReadRepo.GetSourceByID(ctx, *l.SourceID)
		if err == nil {
			sourceRM = &LeadSourceRM{ID: s.ID, Name: s.Name}
		}
	}

	rawInterests, err := h.interestReadRepo.ListInterests(ctx, l.ID)
	if err != nil {
		log.Error().Err(err).Str("lead_id", q.ID.String()).Msg("failed to list lead interests")
		return nil, err
	}

	interests := make([]*LeadInterestRM, len(rawInterests))
	for i, ri := range rawInterests {
		interests[i] = &LeadInterestRM{
			ID:         ri.ID,
			EntityType: ri.EntityType,
			EntityID:   ri.EntityID,
			EntityName: ri.EntityName,
		}
	}

	return &LeadReadModel{
		ID:        l.ID,
		Name:      l.Name,
		Email:     l.Email,
		Phone:     l.Phone,
		Source:    sourceRM,
		Interests: interests,
		Notes:     l.Notes,
		Status:    l.Status,
		PicID:     l.PicID,
		CreatedAt: l.CreatedAt.Unix(),
		UpdatedAt: l.UpdatedAt.Unix(),
	}, nil
}
```

- [ ] **Step 2: Compile check**

```bash
cd api && go build ./internal/query/get_lead/... 2>&1
```

Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add api/internal/query/get_lead/
git commit -m "feat(leads): update get_lead query — source object + interests array"
```

---

## Task 11: Query — list_lead (update)

**Files:**
- Modify: `api/internal/query/list_lead/query.go`
- Modify: `api/internal/query/list_lead/handler.go`

- [ ] **Step 1: Update list_lead/query.go**

```go
package list_lead

import "errors"

var ErrInvalidQuery = errors.New("invalid list lead query")

type ListLeadQuery struct {
	Offset   int
	Limit    int
	Status   string
	SourceID string
	Search   string
	SortBy   string
	SortDir  string
}
```

- [ ] **Step 2: Update list_lead/handler.go**

```go
package list_lead

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
)

type LeadSourceRM struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}

type LeadReadModel struct {
	ID        uuid.UUID     `json:"id"`
	Name      string        `json:"name"`
	Email     string        `json:"email"`
	Phone     string        `json:"phone"`
	Source    *LeadSourceRM `json:"source"`
	Notes     string        `json:"notes"`
	Status    string        `json:"status"`
	PicID     *uuid.UUID    `json:"pic_id"`
	CreatedAt int64         `json:"created_at"`
	UpdatedAt int64         `json:"updated_at"`
}

type ListResult struct {
	Data   []*LeadReadModel `json:"data"`
	Total  int              `json:"total"`
	Offset int              `json:"offset"`
	Limit  int              `json:"limit"`
}

type Handler struct {
	leadReadRepo   lead.ReadRepository
	sourceReadRepo lead.SourceReadRepository
}

func NewHandler(leadReadRepo lead.ReadRepository, sourceReadRepo lead.SourceReadRepository) *Handler {
	return &Handler{leadReadRepo: leadReadRepo, sourceReadRepo: sourceReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListLeadQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	leads, total, err := h.leadReadRepo.List(ctx, q.Offset, q.Limit, q.Status, q.SourceID, q.Search, q.SortBy, q.SortDir)
	if err != nil {
		log.Error().Err(err).Msg("failed to list leads")
		return nil, err
	}

	// Preload all sources for batch lookup
	allSources, _ := h.sourceReadRepo.ListSources(ctx)
	sourceMap := make(map[uuid.UUID]*lead.LeadSource, len(allSources))
	for _, s := range allSources {
		sourceMap[s.ID] = s
	}

	readModels := make([]*LeadReadModel, len(leads))
	for i, l := range leads {
		var sourceRM *LeadSourceRM
		if l.SourceID != nil {
			if s, ok := sourceMap[*l.SourceID]; ok {
				sourceRM = &LeadSourceRM{ID: s.ID, Name: s.Name}
			}
		}
		readModels[i] = &LeadReadModel{
			ID:        l.ID,
			Name:      l.Name,
			Email:     l.Email,
			Phone:     l.Phone,
			Source:    sourceRM,
			Notes:     l.Notes,
			Status:    l.Status,
			PicID:     l.PicID,
			CreatedAt: l.CreatedAt.Unix(),
			UpdatedAt: l.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
```

- [ ] **Step 3: Compile check**

```bash
cd api && go build ./internal/query/list_lead/... 2>&1
```

Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add api/internal/query/list_lead/
git commit -m "feat(leads): update list_lead query — source object, remove interest filter"
```

---

## Task 12: HTTP Handler — Lead (update)

**Files:**
- Modify: `api/internal/delivery/http/lead_handler.go`

- [ ] **Step 1: Update request structs, add interest endpoints**

Replace `CreateLeadRequest`, `UpdateLeadRequest`, and add interest methods. Modify the top portion of the file (requests + handler struct stay, methods updated):

In `lead_handler.go`, replace `CreateLeadRequest` and `UpdateLeadRequest`:

```go
type CreateLeadRequest struct {
	Name     string  `json:"name" validate:"required"`
	Email    string  `json:"email"`
	Phone    string  `json:"phone" validate:"required"`
	SourceID *string `json:"source_id"`
	Notes    string  `json:"notes"`
	PicID    *string `json:"pic_id"`
}

type UpdateLeadRequest struct {
	Name     string  `json:"name" validate:"required"`
	Email    string  `json:"email"`
	Phone    string  `json:"phone" validate:"required"`
	SourceID *string `json:"source_id"`
	Notes    string  `json:"notes"`
	Status   string  `json:"status"`
	PicID    *string `json:"pic_id"`
}

type AddLeadInterestRequest struct {
	EntityType string `json:"entity_type" validate:"required"`
	EntityID   string `json:"entity_id" validate:"required"`
}
```

Update the `Create` method body (parse `SourceID` instead of `Source/Interest`):

```go
func (h *LeadHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req CreateLeadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Name == "" || req.Phone == "" {
		writeError(w, http.StatusBadRequest, "name and phone are required")
		return
	}

	var sourceID *uuid.UUID
	if req.SourceID != nil && *req.SourceID != "" {
		parsed, err := uuid.Parse(*req.SourceID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid source_id")
			return
		}
		sourceID = &parsed
	}

	var picID *uuid.UUID
	if req.PicID != nil && *req.PicID != "" {
		parsed, err := uuid.Parse(*req.PicID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid pic_id")
			return
		}
		picID = &parsed
	}

	cmd := &createlead.CreateLeadCommand{
		Name:     req.Name,
		Email:    req.Email,
		Phone:    req.Phone,
		SourceID: sourceID,
		Notes:    req.Notes,
		PicID:    picID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute create lead command")
		writeError(w, http.StatusInternalServerError, "failed to create lead")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "lead created successfully"})
}
```

Update the `Update` method body similarly (replace `Interest/Source` with `SourceID`):

```go
func (h *LeadHandler) Update(w http.ResponseWriter, r *http.Request) {
	leadIDStr := chi.URLParam(r, "id")
	leadID, err := uuid.Parse(leadIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid lead id")
		return
	}

	var req UpdateLeadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Phone == "" {
		writeError(w, http.StatusBadRequest, "phone is required")
		return
	}

	var sourceID *uuid.UUID
	if req.SourceID != nil && *req.SourceID != "" {
		parsed, err := uuid.Parse(*req.SourceID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid source_id")
			return
		}
		sourceID = &parsed
	}

	var picID *uuid.UUID
	if req.PicID != nil && *req.PicID != "" {
		parsed, err := uuid.Parse(*req.PicID)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid pic_id")
			return
		}
		picID = &parsed
	}

	cmd := &updatelead.UpdateLeadCommand{
		ID:       leadID,
		Name:     req.Name,
		Email:    req.Email,
		Phone:    req.Phone,
		SourceID: sourceID,
		Notes:    req.Notes,
		Status:   req.Status,
		PicID:    picID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to execute update lead command")
		writeError(w, http.StatusInternalServerError, "failed to update lead")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "lead updated successfully"})
}
```

Update the `List` method to use `source_id` query param instead of `source`/`interest`:

```go
func (h *LeadHandler) List(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 10
	}
	status   := r.URL.Query().Get("status")
	sourceID := r.URL.Query().Get("source_id")
	search   := r.URL.Query().Get("search")

	sort := sortutil.Parse(r.URL.Query().Get("sort"))
	var sortBy, sortDir string
	if sort != nil {
		sortBy = sort.Column
		sortDir = sort.Dir
	}

	query := &listlead.ListLeadQuery{
		Offset:   offset,
		Limit:    limit,
		Status:   status,
		SourceID: sourceID,
		Search:   search,
		SortBy:   sortBy,
		SortDir:  sortDir,
	}
	result, err := h.qryBus.Execute(r.Context(), query)
	if err != nil {
		log.Error().Err(err).Msg("failed to execute list lead query")
		writeError(w, http.StatusInternalServerError, "failed to list leads")
		return
	}
	writeJSON(w, http.StatusOK, result)
}
```

Add two new methods at the bottom of the file (before `RegisterLeadRoutes`):

```go
func (h *LeadHandler) AddInterest(w http.ResponseWriter, r *http.Request) {
	leadIDStr := chi.URLParam(r, "id")
	leadID, err := uuid.Parse(leadIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid lead id")
		return
	}

	var req AddLeadInterestRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	entityID, err := uuid.Parse(req.EntityID)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid entity_id")
		return
	}

	validTypes := map[string]bool{"master_course": true, "course_type": true, "course_batch": true}
	if !validTypes[req.EntityType] {
		writeError(w, http.StatusBadRequest, "entity_type must be master_course, course_type, or course_batch")
		return
	}

	cmd := &addleadinterest.AddLeadInterestCommand{
		LeadID:     leadID,
		EntityType: req.EntityType,
		EntityID:   entityID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to add lead interest")
		writeError(w, http.StatusInternalServerError, "failed to add interest")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "interest added"})
}

func (h *LeadHandler) RemoveInterest(w http.ResponseWriter, r *http.Request) {
	leadIDStr := chi.URLParam(r, "id")
	leadID, err := uuid.Parse(leadIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid lead id")
		return
	}

	interestIDStr := chi.URLParam(r, "interestId")
	interestID, err := uuid.Parse(interestIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid interest id")
		return
	}

	cmd := &removeleadinterest.RemoveLeadInterestCommand{
		LeadID:     leadID,
		InterestID: interestID,
	}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to remove lead interest")
		writeError(w, http.StatusInternalServerError, "failed to remove interest")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "interest removed"})
}
```

Add to `RegisterLeadRoutes`:

```go
r.Post("/api/v1/leads/{id}/interests", h.AddInterest)
r.Delete("/api/v1/leads/{id}/interests/{interestId}", h.RemoveInterest)
```

Add imports at top of file:
```go
addleadinterest    "github.com/vernonedu/entrepreneurship-api/internal/command/add_lead_interest"
removeleadinterest "github.com/vernonedu/entrepreneurship-api/internal/command/remove_lead_interest"
```

- [ ] **Step 2: Compile check**

```bash
cd api && go build ./internal/delivery/http/... 2>&1
```

Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add api/internal/delivery/http/lead_handler.go
git commit -m "feat(leads): update lead HTTP handler — source_id, phone required, interest endpoints"
```

---

## Task 13: HTTP Handler — Settings (lead sources)

**Files:**
- Modify: `api/internal/delivery/http/settings_handler.go`

- [ ] **Step 1: Add lead source request structs and methods**

Add at the end of settings_handler.go (before the package if there's no trailing code), then add routes. Add these imports:

```go
createleadsource "github.com/vernonedu/entrepreneurship-api/internal/command/create_lead_source"
deleteleadsource "github.com/vernonedu/entrepreneurship-api/internal/command/delete_lead_source"
updateleadsource "github.com/vernonedu/entrepreneurship-api/internal/command/update_lead_source"
listleadsources  "github.com/vernonedu/entrepreneurship-api/internal/query/list_lead_sources"
```

Add request structs:

```go
type CreateLeadSourceRequest struct {
	Name string `json:"name" validate:"required"`
}

type UpdateLeadSourceRequest struct {
	Name     string `json:"name" validate:"required"`
	IsActive bool   `json:"is_active"`
}
```

Add methods:

```go
func (h *SettingsHandler) ListLeadSources(w http.ResponseWriter, r *http.Request) {
	result, err := h.qryBus.Execute(r.Context(), &listleadsources.ListLeadSourcesQuery{})
	if err != nil {
		log.Error().Err(err).Msg("failed to list lead sources")
		writeError(w, http.StatusInternalServerError, "failed to list lead sources")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *SettingsHandler) CreateLeadSource(w http.ResponseWriter, r *http.Request) {
	var req CreateLeadSourceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &createleadsource.CreateLeadSourceCommand{Name: req.Name}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to create lead source")
		writeError(w, http.StatusInternalServerError, "failed to create lead source")
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"message": "lead source created"})
}

func (h *SettingsHandler) UpdateLeadSource(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}
	var req UpdateLeadSourceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	cmd := &updateleadsource.UpdateLeadSourceCommand{ID: id, Name: req.Name, IsActive: req.IsActive}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to update lead source")
		writeError(w, http.StatusInternalServerError, "failed to update lead source")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "lead source updated"})
}

func (h *SettingsHandler) DeleteLeadSource(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid id")
		return
	}
	cmd := &deleteleadsource.DeleteLeadSourceCommand{ID: id}
	if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
		log.Error().Err(err).Msg("failed to delete lead source")
		writeError(w, http.StatusInternalServerError, "failed to delete lead source")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "lead source deleted"})
}
```

In `RegisterSettingsRoutes`, add:

```go
r.Get("/api/v1/settings/lead-sources", h.ListLeadSources)
r.Post("/api/v1/settings/lead-sources", h.CreateLeadSource)
r.Put("/api/v1/settings/lead-sources/{id}", h.UpdateLeadSource)
r.Delete("/api/v1/settings/lead-sources/{id}", h.DeleteLeadSource)
```

- [ ] **Step 2: Compile check**

```bash
cd api && go build ./internal/delivery/http/... 2>&1
```

Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add api/internal/delivery/http/settings_handler.go
git commit -m "feat(leads): add lead source CRUD to settings handler"
```

---

## Task 14: Wire Everything in main.go

**Files:**
- Modify: `api/cmd/api/main.go`

- [ ] **Step 1: Add imports at top of main.go**

Find the lead command imports section (around line 102) and add:

```go
addleadinterest    "github.com/vernonedu/entrepreneurship-api/internal/command/add_lead_interest"
createleadsource   "github.com/vernonedu/entrepreneurship-api/internal/command/create_lead_source"
deleteleadsource   "github.com/vernonedu/entrepreneurship-api/internal/command/delete_lead_source"
removeleadinterest "github.com/vernonedu/entrepreneurship-api/internal/command/remove_lead_interest"
updateleadsource   "github.com/vernonedu/entrepreneurship-api/internal/command/update_lead_source"
listleadsources    "github.com/vernonedu/entrepreneurship-api/internal/query/list_lead_sources"
```

- [ ] **Step 2: Add repo providers**

Find the DB provider section (around line 493, where `LeadRepository` is provided). Add after it:

```go
func(db *sqlx.DB) *database.LeadSourceRepository {
    return database.NewLeadSourceRepository(db)
},
func(db *sqlx.DB) *database.LeadInterestRepository {
    return database.NewLeadInterestRepository(db)
},
```

- [ ] **Step 3: Add to Providers struct**

Find the `Providers` struct (around line 996) and add:

```go
LeadSourceRepo    *database.LeadSourceRepository
LeadInterestRepo  *database.LeadInterestRepository
```

- [ ] **Step 4: Register new commands and queries**

Find the `// ===== LEAD =====` section (around line 1557) and after the existing lead registrations, add:

```go
// Lead sources
if err := p.CmdBus.Register(&createleadsource.CreateLeadSourceCommand{},
    createleadsource.NewHandler(p.LeadSourceRepo)); err != nil {
    return err
}
if err := p.CmdBus.Register(&updateleadsource.UpdateLeadSourceCommand{},
    updateleadsource.NewHandler(p.LeadSourceRepo, p.LeadSourceRepo)); err != nil {
    return err
}
if err := p.CmdBus.Register(&deleteleadsource.DeleteLeadSourceCommand{},
    deleteleadsource.NewHandler(p.LeadSourceRepo)); err != nil {
    return err
}
listLeadSourcesH := listleadsources.NewHandler(p.LeadSourceRepo)
if err := p.QryBus.Register(&listleadsources.ListLeadSourcesQuery{}, adaptQueryHandler(listLeadSourcesH.Handle)); err != nil {
    return err
}

// Lead interests
if err := p.CmdBus.Register(&addleadinterest.AddLeadInterestCommand{},
    addleadinterest.NewHandler(p.LeadInterestRepo)); err != nil {
    return err
}
if err := p.CmdBus.Register(&removeleadinterest.RemoveLeadInterestCommand{},
    removeleadinterest.NewHandler(p.LeadInterestRepo)); err != nil {
    return err
}
```

- [ ] **Step 5: Update get_lead and list_lead handler construction**

Find:
```go
getLeadH := getlead.NewHandler(p.LeadRepo)
```
Replace with:
```go
getLeadH := getlead.NewHandler(p.LeadRepo, p.LeadSourceRepo, p.LeadInterestRepo)
```

Find:
```go
listLeadH := listlead.NewHandler(p.LeadRepo)
```
Replace with:
```go
listLeadH := listlead.NewHandler(p.LeadRepo, p.LeadSourceRepo)
```

- [ ] **Step 6: Full compile check**

```bash
cd api && go build ./... 2>&1
```

Expected: no errors

- [ ] **Step 7: Commit**

```bash
git add api/cmd/api/main.go
git commit -m "feat(leads): wire lead source and interest repos/commands/queries in main.go"
```

---

## Task 15: Frontend — lead-source.service.ts

**Files:**
- Create: `web-dashboard/src/services/lead-source.service.ts`

- [ ] **Step 1: Create the service**

```typescript
import { apiClient } from './api.client'

export interface LeadSource {
  id: string
  name: string
  is_active: boolean
}

export const leadSourceService = {
  list: (): Promise<LeadSource[]> =>
    apiClient.get<LeadSource[]>('settings/lead-sources').then((r: any) => r?.data ?? r ?? []),

  create: (data: { name: string }) =>
    apiClient.post('settings/lead-sources', data),

  update: (id: string, data: { name: string; is_active: boolean }) =>
    apiClient.put(`settings/lead-sources/${id}`, data),

  delete: (id: string) =>
    apiClient.delete(`settings/lead-sources/${id}`),
}
```

- [ ] **Step 2: Commit**

```bash
git add web-dashboard/src/services/lead-source.service.ts
git commit -m "feat(leads): add lead-source.service.ts"
```

---

## Task 16: Frontend — lead.service.ts (update)

**Files:**
- Modify: `web-dashboard/src/services/lead.service.ts`

- [ ] **Step 1: Update lead.service.ts**

```typescript
import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

function toPaginated<T>(raw: unknown, fallback: T[]): PaginatedResponse<T> {
  const r = raw as Record<string, unknown>
  if (r && typeof r === 'object' && 'items' in r) return r as unknown as PaginatedResponse<T>
  const list = Array.isArray(raw) ? raw : fallback
  return { items: list as T[], total: list.length, limit: 9999, offset: 0 }
}

function unwrap<T>(res: unknown): T {
  const r = res as Record<string, unknown>
  return (r?.data ?? res) as T
}

function buildQS(params?: Record<string, any>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') q.set(k, Array.isArray(v) ? JSON.stringify(v) : String(v))
  })
  const s = q.toString()
  return s ? `?${s}` : ''
}

export const leadService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> => {
    const qs = buildQS(params)
    return apiClient.get<any>(`leads${qs}`).then(r => toPaginated(unwrap(r), []))
  },

  getById: (id: string) =>
    apiClient.get<any>(`leads/${id}`).then(r => unwrap(r)),

  create: (data: {
    name: string
    phone: string
    email?: string
    source_id?: string
    notes?: string
  }) => apiClient.post<any>('leads', data),

  update: (id: string, data: {
    name: string
    phone: string
    email?: string
    source_id?: string
    status?: string
    notes?: string
  }) => apiClient.put<any>(`leads/${id}`, data),

  delete: (id: string) =>
    apiClient.delete(`leads/${id}`),

  getCrmLogs: (id: string) =>
    apiClient.get<any>(`leads/${id}/crm-logs`).then(r => unwrap(r)),

  addCrmLog: (id: string, data: any) =>
    apiClient.post<any>(`leads/${id}/crm-logs`, data),

  convertToStudent: (id: string) =>
    apiClient.post<any>(`leads/${id}/convert`, {}),

  addInterest: (leadId: string, data: { entity_type: string; entity_id: string }) =>
    apiClient.post<any>(`leads/${leadId}/interests`, data),

  removeInterest: (leadId: string, interestId: string) =>
    apiClient.delete(`leads/${leadId}/interests/${interestId}`),
}
```

- [ ] **Step 2: Commit**

```bash
git add web-dashboard/src/services/lead.service.ts
git commit -m "feat(leads): update lead.service — phone required, source_id, interest methods"
```

---

## Task 17: Frontend — LeadSourceListPage + LeadSourceFormPage

**Files:**
- Create: `web-dashboard/src/pages/Settings/LeadSourceListPage.tsx`
- Create: `web-dashboard/src/pages/Settings/LeadSourceFormPage.tsx`

- [ ] **Step 1: Create LeadSourceListPage.tsx**

```tsx
import { useNavigate } from 'react-router-dom'
import { Pencil, Tag } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { leadSourceService, type LeadSource } from '@/services/lead-source.service'

const columns: ColumnDef<LeadSource>[] = [
  {
    key: 'name',
    header: 'Nama Sumber',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Tag size={16} />
        </div>
        <span style={{ fontWeight: 600 }}>{row.name}</span>
      </div>
    ),
  },
  {
    key: 'is_active',
    header: 'Status',
    width: 120,
    render: (_v, row) => (
      <span style={{
        display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
        fontSize: 'var(--font-xs)', fontWeight: 600,
        background: row.is_active ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
        color: row.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
      }}>
        {row.is_active ? 'Aktif' : 'Nonaktif'}
      </span>
    ),
  },
]

export default function LeadSourceListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<LeadSource>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/settings/lead-sources/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<LeadSource>
      title="Sumber Lead"
      addLabel="Tambah Sumber"
      onAdd={() => navigate('/settings/lead-sources/new')}
      queryKey="lead-sources"
      fetcher={() => leadSourceService.list().then(items => ({ items, total: items.length, limit: 9999, offset: 0 }))}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/settings/lead-sources/${row.id}/edit`)}
      searchPlaceholder="Cari sumber..."
      exportFilename="lead-sources"
      emptyTitle="Belum ada sumber lead"
      emptyDescription="Tambahkan sumber untuk melacak dari mana prospek mengetahui layanan Anda."
      helpTitle="Sumber Lead"
      helpText="Sumber lead adalah kategori asal prospek (contoh: Referral, Website). Digunakan saat membuat atau mengedit lead."
      deleteConfig={{
        onDelete: (row) => leadSourceService.delete(row.id) as Promise<void>,
        dialogTitle: 'Hapus Sumber Lead?',
        dialogBody: (row) => `"${row.name}" akan dihapus. Lead yang sudah menggunakan sumber ini tidak akan terpengaruh.`,
        successMessage: (row) => `Sumber "${row.name}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus sumber lead',
      }}
      hidePagination
    />
  )
}
```

- [ ] **Step 2: Create LeadSourceFormPage.tsx**

```tsx
import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Tag } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { leadSourceService } from '@/services/lead-source.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

export default function LeadSourceFormPage() {
  const navigate = useNavigate()
  const { sourceId } = useParams<{ sourceId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(sourceId)

  const [name, setName] = useState('')
  const [isActive, setIsActive] = useState(true)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: source } = useQuery({
    queryKey: ['lead-source', sourceId],
    queryFn: async () => {
      const all = await leadSourceService.list()
      return all.find(s => s.id === sourceId) ?? null
    },
    enabled: isEdit,
  })

  useEffect(() => {
    if (source) {
      setName(source.name ?? '')
      setIsActive(source.is_active ?? true)
    }
  }, [source])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama wajib diisi'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')
    try {
      if (isEdit) {
        await leadSourceService.update(sourceId!, { name: name.trim(), is_active: isActive })
        toast.success('Sumber lead berhasil diperbarui')
      } else {
        await leadSourceService.create({ name: name.trim() })
        toast.success('Sumber lead berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['lead-sources'] })
      navigate('/settings/lead-sources')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Sumber Lead' : 'Tambah Sumber Lead'}
      icon={<Tag size={20} />}
      onBack={() => navigate('/settings/lead-sources')}
      tabs={[{
        id: 'general',
        label: 'Informasi',
        content: (
          <FormGrid>
            <FormColumn>
              <Field label="Nama Sumber" required error={errors.name}>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="cth. Referral, Website"
                  className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                  autoFocus
                />
              </Field>
              {isEdit && (
                <Field label="Status">
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                    <input
                      type="checkbox"
                      checked={isActive}
                      onChange={(e) => setIsActive(e.target.checked)}
                    />
                    <span>Aktif</span>
                  </label>
                </Field>
              )}
            </FormColumn>
          </FormGrid>
        ),
      }]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/settings/lead-sources')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Settings/LeadSourceListPage.tsx web-dashboard/src/pages/Settings/LeadSourceFormPage.tsx
git commit -m "feat(leads): add LeadSource list and form pages in Settings"
```

---

## Task 18: Frontend — routes.tsx (update)

**Files:**
- Modify: `web-dashboard/src/app/routes.tsx`

- [ ] **Step 1: Add lead source lazy imports**

After the existing settings imports (around line 154), add:

```tsx
const LeadSourceListPage = lazy(() => import('@/pages/Settings/LeadSourceListPage'))
const LeadSourceFormPage = lazy(() => import('@/pages/Settings/LeadSourceFormPage'))
```

- [ ] **Step 2: Add routes**

After `{ path: 'settings', element: <S><SettingsPage /></S> }`, add:

```tsx
{ path: 'settings/lead-sources',                    element: <S><LeadSourceListPage /></S> },
{ path: 'settings/lead-sources/new',                element: <S><LeadSourceFormPage /></S> },
{ path: 'settings/lead-sources/:sourceId/edit',     element: <S><LeadSourceFormPage /></S> },
```

- [ ] **Step 3: Verify TypeScript**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | head -20
```

Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add web-dashboard/src/app/routes.tsx
git commit -m "feat(leads): add settings/lead-sources routes"
```

---

## Task 19: Frontend — LeadFormPage (update)

**Files:**
- Modify: `web-dashboard/src/pages/Leads/LeadFormPage.tsx`

- [ ] **Step 1: Replace LeadFormPage.tsx**

```tsx
import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { User, X, Plus } from 'lucide-react'
import { useQuery, useQueryClient, useMutation } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { leadService } from '@/services/lead.service'
import { leadSourceService } from '@/services/lead-source.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const ENTITY_TYPES = [
  { value: 'master_course', label: 'Master Course' },
  { value: 'course_type', label: 'Course Type' },
  { value: 'course_batch', label: 'Batch' },
]

const STATUS_OPTIONS = [
  { value: 'new', label: 'Baru' },
  { value: 'contacted', label: 'Dihubungi' },
  { value: 'interested', label: 'Tertarik' },
  { value: 'negotiating', label: 'Negosiasi' },
  { value: 'enrolled', label: 'Terdaftar' },
  { value: 'not_interested', label: 'Tidak Tertarik' },
]

const ENTITY_TYPE_LABELS: Record<string, string> = {
  master_course: 'Master Course',
  course_type: 'Course Type',
  course_batch: 'Batch',
}

export default function LeadFormPage() {
  const navigate = useNavigate()
  const { leadId } = useParams<{ leadId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(leadId)

  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [sourceId, setSourceId] = useState('')
  const [status, setStatus] = useState('new')
  const [notes, setNotes] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  // Interest picker state
  const [interestEntityType, setInterestEntityType] = useState('master_course')
  const [interestEntityId, setInterestEntityId] = useState('')

  const { data: lead } = useQuery({
    queryKey: ['lead', leadId],
    queryFn: () => leadService.getById(leadId!),
    enabled: isEdit,
  })

  const { data: sources = [] } = useQuery({
    queryKey: ['lead-sources'],
    queryFn: () => leadSourceService.list(),
  })

  const activeSources = sources.filter((s) => s.is_active)

  const { data: masterCourses = [] } = useQuery({
    queryKey: ['master-courses-simple'],
    queryFn: () => fetch('/api/v1/master-courses?limit=200').then(r => r.json()).then((d: any) => d?.data ?? []),
    enabled: isEdit,
  })

  const { data: courseTypes = [] } = useQuery({
    queryKey: ['course-types-simple'],
    queryFn: () => fetch('/api/v1/course-types?limit=200').then(r => r.json()).then((d: any) => d?.data ?? []),
    enabled: isEdit,
  })

  const { data: courseBatches = [] } = useQuery({
    queryKey: ['course-batches-simple'],
    queryFn: () => fetch('/api/v1/course-batches?limit=200').then(r => r.json()).then((d: any) => d?.data ?? []),
    enabled: isEdit,
  })

  useEffect(() => {
    if (lead) {
      setName((lead as any).name ?? '')
      setEmail((lead as any).email ?? '')
      setPhone((lead as any).phone ?? '')
      setSourceId((lead as any).source?.id ?? '')
      setStatus((lead as any).status ?? 'new')
      setNotes((lead as any).notes ?? '')
    }
  }, [lead])

  const interests: any[] = (lead as any)?.interests ?? []

  const addInterestMutation = useMutation({
    mutationFn: () => leadService.addInterest(leadId!, {
      entity_type: interestEntityType,
      entity_id: interestEntityId,
    }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lead', leadId] })
      setInterestEntityId('')
      toast.success('Minat ditambahkan')
    },
    onError: () => toast.error('Gagal menambah minat'),
  })

  const removeInterestMutation = useMutation({
    mutationFn: (interestId: string) => leadService.removeInterest(leadId!, interestId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lead', leadId] })
      toast.success('Minat dihapus')
    },
    onError: () => toast.error('Gagal menghapus minat'),
  })

  function getEntityOptions() {
    if (interestEntityType === 'master_course') return (masterCourses as any[]).map((c: any) => ({ value: c.id, label: c.course_name ?? c.name }))
    if (interestEntityType === 'course_type') return (courseTypes as any[]).map((c: any) => ({ value: c.id, label: c.type_name ?? c.name }))
    return (courseBatches as any[]).map((c: any) => ({ value: c.id, label: c.name }))
  }

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama wajib diisi'
    else if (name.trim().length < 2) e.name = 'Minimal 2 karakter'
    if (!phone.trim()) e.phone = 'Telepon wajib diisi'
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) e.email = 'Format email tidak valid'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')
    try {
      const payload = {
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim() || undefined,
        source_id: sourceId || undefined,
        notes: notes.trim() || undefined,
        ...(isEdit && { status }),
      }
      if (isEdit) {
        await leadService.update(leadId!, payload)
        toast.success('Lead berhasil diperbarui')
      } else {
        await leadService.create(payload)
        toast.success('Lead berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['leads'] })
      navigate(isEdit ? `/leads/${leadId}` : '/leads')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const interestsSection = isEdit ? (
    <FormColumn style={{ gridColumn: '1 / -1' }}>
      <Field label="Minat" hint="Kursus atau batch yang diminati lead ini.">
        {/* Existing interests */}
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 12 }}>
          {interests.length === 0 && (
            <span style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Belum ada minat</span>
          )}
          {interests.map((i: any) => (
            <span key={i.id} style={{
              display: 'inline-flex', alignItems: 'center', gap: 6,
              padding: '4px 10px', borderRadius: 'var(--radius-full)',
              background: 'var(--color-primary-subtle)', color: 'var(--color-primary)',
              fontSize: 'var(--font-xs)', fontWeight: 600,
            }}>
              <span style={{ opacity: 0.7 }}>[{ENTITY_TYPE_LABELS[i.entity_type] ?? i.entity_type}]</span>
              {i.entity_name ?? i.entity_id}
              <button
                type="button"
                onClick={() => removeInterestMutation.mutate(i.id)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, lineHeight: 1, color: 'inherit' }}
              >
                <X size={12} />
              </button>
            </span>
          ))}
        </div>
        {/* Add new interest */}
        <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
          <select
            value={interestEntityType}
            onChange={(e) => { setInterestEntityType(e.target.value); setInterestEntityId('') }}
            className={formStyles.select}
            style={{ width: 150 }}
          >
            {ENTITY_TYPES.map(t => (
              <option key={t.value} value={t.value}>{t.label}</option>
            ))}
          </select>
          <select
            value={interestEntityId}
            onChange={(e) => setInterestEntityId(e.target.value)}
            className={formStyles.select}
            style={{ flex: 1, minWidth: 200 }}
          >
            <option value="">Pilih...</option>
            {getEntityOptions().map((opt: any) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
          <button
            type="button"
            onClick={() => interestEntityId && addInterestMutation.mutate()}
            disabled={!interestEntityId || addInterestMutation.isPending}
            style={{
              display: 'flex', alignItems: 'center', gap: 4,
              padding: '6px 14px', borderRadius: 'var(--radius-md)',
              background: 'var(--color-primary)', color: '#fff',
              border: 'none', cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 600,
              opacity: (!interestEntityId || addInterestMutation.isPending) ? 0.5 : 1,
            }}
          >
            <Plus size={14} /> Tambah
          </button>
        </div>
      </Field>
    </FormColumn>
  ) : null

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Lead' : 'Tambah Lead'}
      icon={<User size={20} />}
      onBack={() => navigate(isEdit ? `/leads/${leadId}` : '/leads')}
      tabs={[{
        id: 'general',
        label: 'Informasi Utama',
        content: (
          <FormGrid>
            <FormColumn>
              <Field label="Nama" required error={errors.name}>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Nama lengkap prospek"
                  className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                  autoFocus
                />
              </Field>
              <Field label="Telepon" required error={errors.phone} hint="Digunakan untuk menghubungi prospek.">
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="+62 xxx xxxx xxxx"
                  className={`${formStyles.input} ${errors.phone ? formStyles.inputError : ''}`}
                />
              </Field>
              <Field label="Email" error={errors.email} hint="Opsional.">
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="contoh@email.com"
                  className={`${formStyles.input} ${errors.email ? formStyles.inputError : ''}`}
                />
              </Field>
            </FormColumn>
            <FormColumn>
              <Field label="Sumber" hint="Dari mana prospek mengetahui layanan kami.">
                <select
                  value={sourceId}
                  onChange={(e) => setSourceId(e.target.value)}
                  className={formStyles.select}
                >
                  <option value="">— Pilih Sumber —</option>
                  {activeSources.map((s) => (
                    <option key={s.id} value={s.id}>{s.name}</option>
                  ))}
                </select>
              </Field>
              {isEdit && (
                <Field label="Status" hint="Tahap prospek saat ini.">
                  <select
                    value={status}
                    onChange={(e) => setStatus(e.target.value)}
                    className={formStyles.select}
                  >
                    {STATUS_OPTIONS.map((opt) => (
                      <option key={opt.value} value={opt.value}>{opt.label}</option>
                    ))}
                  </select>
                </Field>
              )}
            </FormColumn>
            {interestsSection}
            <FormColumn style={{ gridColumn: '1 / -1' }}>
              <Field label="Catatan" hint="Opsional.">
                <textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Catatan tambahan..."
                  rows={5}
                  className={formStyles.textarea}
                />
                <span style={{
                  fontSize: 'var(--font-min)', color: 'var(--color-text-tertiary)',
                  textAlign: 'right', display: 'block', marginTop: 2,
                }}>
                  {notes.length} karakter
                </span>
              </Field>
            </FormColumn>
          </FormGrid>
        ),
      }]}
      onSubmit={handleSubmit}
      onCancel={() => navigate(isEdit ? `/leads/${leadId}` : '/leads')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
```

- [ ] **Step 2: TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep -i "leads/LeadForm" | head -10
```

Expected: no errors for this file

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Leads/LeadFormPage.tsx
git commit -m "feat(leads): update LeadFormPage — phone required, source dropdown, interests section"
```

---

## Task 20: Frontend — LeadDetailPage (update)

**Files:**
- Modify: `web-dashboard/src/pages/Leads/LeadDetailPage.tsx`

- [ ] **Step 1: Update source and interests display**

In `LeadDetailPage.tsx`, update `detailContent` — replace `InfoCard label="Sumber"` and `InfoCard label="Minat"`:

```tsx
// Replace:
<InfoCard label="Sumber">{lead?.source || '—'}</InfoCard>
<InfoCard label="Minat">{lead?.interest || '—'}</InfoCard>

// With:
<InfoCard label="Sumber">{lead?.source?.name || '—'}</InfoCard>
```

Add interests section after the grid div in `detailContent`:

```tsx
{Array.isArray(lead?.interests) && lead.interests.length > 0 && (
  <div style={{ marginTop: 'var(--space-3)' }}>
    <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 8 }}>Minat</div>
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
      {lead.interests.map((i: any) => (
        <span key={i.id} style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          padding: '4px 10px', borderRadius: 'var(--radius-full)',
          background: 'var(--color-primary-subtle)', color: 'var(--color-primary)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
        }}>
          <span style={{ opacity: 0.7 }}>[{i.entity_type?.replace('_', ' ')}]</span>
          {i.entity_name ?? i.entity_id}
        </span>
      ))}
    </div>
  </div>
)}
```

- [ ] **Step 2: Commit**

```bash
git add web-dashboard/src/pages/Leads/LeadDetailPage.tsx
git commit -m "feat(leads): update LeadDetailPage — source object, interests chips"
```

---

## Task 21: Frontend — LeadListPage (update)

**Files:**
- Modify: `web-dashboard/src/pages/Leads/LeadListPage.tsx`

- [ ] **Step 1: Update source column and Lead interface**

In `LeadListPage.tsx`:

Replace interface:
```tsx
interface Lead {
  id: string
  name: string
  email: string
  phone: string
  source: { id: string; name: string } | null
  status: string
  notes: string
  created_at: number
}
```

Remove `SOURCE_LABELS` constant entirely.

Update source column render:
```tsx
{
  key: 'source',
  header: 'Sumber',
  sortable: false,
  width: 120,
  render: (_v, row) => row.source?.name ?? '—',
},
```

Remove interest column entirely (was `key: 'interest'`).

- [ ] **Step 2: TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "LeadList" | head -5
```

Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Leads/LeadListPage.tsx
git commit -m "feat(leads): update LeadListPage — source object, remove interest column"
```

---

## Task 22: Integration Smoke Test

- [ ] **Step 1: Start API**

```bash
cd api && make dev
```

Expected: server running on :8081 with no errors

- [ ] **Step 2: Verify lead sources seeded**

```bash
curl -s http://localhost:8081/api/v1/settings/lead-sources | python3 -m json.tool
```

Expected: array with Referral, Media Sosial, Walk In, Website, Lainnya

- [ ] **Step 3: Test create lead with phone required**

```bash
curl -s -X POST http://localhost:8081/api/v1/leads \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"name":"Test Lead","phone":""}' | python3 -m json.tool
```

Expected: 400 error (phone required)

- [ ] **Step 4: Start frontend**

```bash
cd web-dashboard && npm run dev
```

- [ ] **Step 5: Manual smoke test checklist**

- [ ] Navigate to Settings > Lead Sources — list shows 5 seeded sources
- [ ] Create a new source — appears in list
- [ ] Edit a source — name and active toggle work
- [ ] Navigate to Leads > Add Lead — phone is required (error shows on submit without phone)
- [ ] Source dropdown shows active sources from API
- [ ] Create lead succeeds
- [ ] Edit lead — interests section appears with type toggle + entity dropdown
- [ ] Add interest — chip appears immediately
- [ ] Remove interest — chip disappears
- [ ] Lead detail page — shows source name, interests chips
- [ ] Lead list — source column shows name (not enum key)

- [ ] **Step 6: Final commit**

```bash
git add .
git commit -m "feat(leads): complete — phone required, source entity, multi-link interests"
```
