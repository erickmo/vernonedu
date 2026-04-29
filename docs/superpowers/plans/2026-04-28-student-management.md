# Student Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add complete student management to the `identity` domain — CRUD, profile management, advanced search/filter, and RBAC for admin + student self-service.

**Architecture:** Split student logic into dedicated files (`repository_student.go`, `service_student.go`, `handler_student.go`) inside the existing `identity` domain. `Repository` interface stays in `repository.go`; student methods on `*Service` and `*Handler` live in the new files. All methods belong to the same structs — just split across files.

**Tech Stack:** Go 1.22, Chi v5, pgx v5, Uber FX, testify/require, `//go:build integration` tests against a real Postgres.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `backend/domains/identity/model.go` | Add `StudentFilter`, `UpdateStudentInput`, `UpdateStudentProfileInput` |
| Modify | `backend/domains/identity/repository.go` | Replace `ListStudents` with new student repo methods in interface; remove student impl |
| Create | `backend/domains/identity/repository_student.go` | Student repo implementation (moved + new) |
| Modify | `backend/domains/identity/service.go` | Remove student-only methods; update `Register` to auto-create profile |
| Create | `backend/domains/identity/service_student.go` | Student service methods on `*Service` |
| Modify | `backend/domains/identity/handler.go` | Remove `ListStudents`, `GetStudent`; bridge call during migration |
| Create | `backend/domains/identity/handler_student.go` | Student HTTP handlers on `*Handler` |
| Modify | `backend/domains/identity/module.go` | Add new routes + RBAC |
| Create | `backend/domains/identity/service_student_integration_test.go` | Service-layer integration tests |
| Create | `backend/domains/identity/handler_student_test.go` | HTTP-layer RBAC tests |

---

## Task 1: Scaffolding — stubs, interface, model types

**Files:**
- Modify: `backend/domains/identity/model.go`
- Modify: `backend/domains/identity/repository.go`
- Create: `backend/domains/identity/repository_student.go`
- Create: `backend/domains/identity/service_student.go`
- Modify: `backend/domains/identity/service.go`
- Modify: `backend/domains/identity/handler.go`

- [ ] **Step 1.1: Add types to model.go**

Append to the end of `backend/domains/identity/model.go`:

```go
// StudentFilter holds parameters for filtered student queries.
type StudentFilter struct {
	Source          *StudentSource
	PartnerID       *uuid.UUID
	Search          string
	ProfileComplete *bool
	SortBy          string
	SortDir         string
	Limit           int
	Offset          int
}

// UpdateStudentInput carries fields for admin student update.
type UpdateStudentInput struct {
	Name      string
	Email     string
	Phone     string
	Source    StudentSource
	PartnerID *uuid.UUID
}

// UpdateStudentProfileInput carries profile update fields.
type UpdateStudentProfileInput struct {
	DateOfBirth *time.Time
	Gender      *string
	IDType      *string
	IDNumber    *string
	Address     *string
	City        *string
	Province    *string
	PostalCode  *string
}
```

- [ ] **Step 1.2: Update Repository interface in repository.go**

Replace the four student lines in the `Repository` interface:
```go
// OLD — remove these four lines:
CreateStudent(ctx context.Context, s *Student) error
GetStudentByID(ctx context.Context, id uuid.UUID) (*Student, error)
GetStudentByUserID(ctx context.Context, userID uuid.UUID) (*Student, error)
ListStudents(ctx context.Context, limit, offset int) ([]*Student, error)
```
With:
```go
// NEW — replace with these nine lines:
CreateStudent(ctx context.Context, s *Student) error
GetStudentByID(ctx context.Context, id uuid.UUID) (*Student, error)
GetStudentByUserID(ctx context.Context, userID uuid.UUID) (*Student, error)
ListStudentsFiltered(ctx context.Context, f StudentFilter) ([]*Student, error)
CountStudentsFiltered(ctx context.Context, f StudentFilter) (int, error)
UpdateStudent(ctx context.Context, s *Student) error
CreateStudentProfile(ctx context.Context, p *StudentProfile) error
GetStudentProfile(ctx context.Context, studentID uuid.UUID) (*StudentProfile, error)
UpdateStudentProfile(ctx context.Context, p *StudentProfile) error
```

Also delete the four `func (r *repository) CreateStudent`, `GetStudentByID`, `GetStudentByUserID`, and `ListStudents` implementations from `repository.go` (they move to `repository_student.go`).

- [ ] **Step 1.3: Create repository_student.go**

Create `backend/domains/identity/repository_student.go`:

```go
package identity

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// ─── Moved from repository.go ────────────────────────────────────────────────

func (r *repository) CreateStudent(ctx context.Context, s *Student) error {
	query := `
		INSERT INTO identity.students (id, user_id, name, email, phone, source, partner_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		s.ID, s.UserID, s.Name, s.Email, s.Phone, s.Source, s.PartnerID,
	).Scan(&s.CreatedAt, &s.UpdatedAt)
	if err != nil {
		return fmt.Errorf("identity.CreateStudent: %w", err)
	}
	return nil
}

func (r *repository) GetStudentByID(ctx context.Context, id uuid.UUID) (*Student, error) {
	query := `SELECT id, user_id, name, email, phone, source, partner_id, created_at, updated_at
	          FROM identity.students WHERE id = $1`

	s := &Student{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&s.ID, &s.UserID, &s.Name, &s.Email, &s.Phone, &s.Source, &s.PartnerID,
		&s.CreatedAt, &s.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("identity.GetStudentByID: %w", err)
	}
	return s, nil
}

func (r *repository) GetStudentByUserID(ctx context.Context, userID uuid.UUID) (*Student, error) {
	query := `SELECT id, user_id, name, email, phone, source, partner_id, created_at, updated_at
	          FROM identity.students WHERE user_id = $1`

	s := &Student{}
	err := r.pool.QueryRow(ctx, query, userID).Scan(
		&s.ID, &s.UserID, &s.Name, &s.Email, &s.Phone, &s.Source, &s.PartnerID,
		&s.CreatedAt, &s.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("identity.GetStudentByUserID: %w", err)
	}
	return s, nil
}

// ─── New implementations (stubs — filled in Task 4) ─────────────────────────

func (r *repository) ListStudentsFiltered(_ context.Context, _ StudentFilter) ([]*Student, error) {
	return nil, nil
}

func (r *repository) CountStudentsFiltered(_ context.Context, _ StudentFilter) (int, error) {
	return 0, nil
}

func (r *repository) UpdateStudent(_ context.Context, _ *Student) error {
	return nil
}

func (r *repository) CreateStudentProfile(_ context.Context, _ *StudentProfile) error {
	return nil
}

func (r *repository) GetStudentProfile(_ context.Context, _ uuid.UUID) (*StudentProfile, error) {
	return nil, nil
}

func (r *repository) UpdateStudentProfile(_ context.Context, _ *StudentProfile) error {
	return nil
}

// ─── Query helpers ───────────────────────────────────────────────────────────

func buildStudentWhere(f StudentFilter) ([]string, []interface{}) {
	var where []string
	var args []interface{}
	n := 1

	if f.Source != nil {
		where = append(where, fmt.Sprintf("s.source = $%d", n))
		args = append(args, *f.Source)
		n++
	}
	if f.PartnerID != nil {
		where = append(where, fmt.Sprintf("s.partner_id = $%d", n))
		args = append(args, *f.PartnerID)
		n++
	}
	if f.Search != "" {
		where = append(where, fmt.Sprintf("(s.name ILIKE $%d OR s.email ILIKE $%d)", n, n+1))
		args = append(args, "%"+f.Search+"%", "%"+f.Search+"%")
		n += 2
	}
	if f.ProfileComplete != nil {
		where = append(where, fmt.Sprintf("p.profile_complete = $%d", n))
		args = append(args, *f.ProfileComplete)
		n++
	}
	_ = n
	return where, args
}

func studentWhereClause(where []string) string {
	if len(where) == 0 {
		return ""
	}
	return "WHERE " + strings.Join(where, " AND ")
}

func studentSortCol(sortBy string) string {
	switch sortBy {
	case "name":
		return "s.name"
	case "email":
		return "s.email"
	default:
		return "s.created_at"
	}
}
```

- [ ] **Step 1.4: Create service_student.go stubs**

Create `backend/domains/identity/service_student.go`:

```go
package identity

import (
	"context"

	"github.com/google/uuid"
)

// GetStudentByID fetches student by primary key.
func (s *Service) GetStudentByID(ctx context.Context, id uuid.UUID) (*Student, error) {
	return s.repo.GetStudentByID(ctx, id)
}

// GetStudentByUserID fetches student linked to a user.
func (s *Service) GetStudentByUserID(ctx context.Context, userID uuid.UUID) (*Student, error) {
	return s.repo.GetStudentByUserID(ctx, userID)
}

// ListStudentsFiltered paginates and filters the student list.
func (s *Service) ListStudentsFiltered(ctx context.Context, f StudentFilter) ([]*Student, error) {
	if f.Limit <= 0 || f.Limit > 100 {
		f.Limit = 20
	}
	return s.repo.ListStudentsFiltered(ctx, f)
}

// CountStudentsFiltered returns total matching students.
func (s *Service) CountStudentsFiltered(ctx context.Context, f StudentFilter) (int, error) {
	return s.repo.CountStudentsFiltered(ctx, f)
}

// UpdateStudent updates student core fields.
func (s *Service) UpdateStudent(ctx context.Context, id uuid.UUID, in UpdateStudentInput) (*Student, error) {
	return nil, nil // stub — implemented in Task 4
}

// GetStudentProfile fetches the profile for a student.
func (s *Service) GetStudentProfile(ctx context.Context, studentID uuid.UUID) (*StudentProfile, error) {
	return s.repo.GetStudentProfile(ctx, studentID)
}

// UpdateStudentProfile updates profile fields and recomputes profile_complete.
func (s *Service) UpdateStudentProfile(ctx context.Context, studentID uuid.UUID, in UpdateStudentProfileInput) (*StudentProfile, error) {
	return nil, nil // stub — implemented in Task 4
}
```

- [ ] **Step 1.5: Remove student methods from service.go**

Delete these three methods from `backend/domains/identity/service.go`:
- `func (s *Service) GetStudentByID(...)`
- `func (s *Service) GetStudentByUserID(...)`
- `func (s *Service) ListStudents(...)`

- [ ] **Step 1.6: Update handler.go — bridge ListStudents call**

In `handler.go`, update `ListStudents` to call the new service method:

```go
func (h *Handler) ListStudents(w http.ResponseWriter, r *http.Request) {
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))

	students, err := h.svc.ListStudentsFiltered(r.Context(), StudentFilter{
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(students)
}
```

(Keep `GetStudent` in handler.go for now — it already calls `h.svc.GetStudentByID` which is still available via service_student.go.)

- [ ] **Step 1.7: Verify build**

```bash
cd backend && go build ./...
```

Expected: no errors.

- [ ] **Step 1.8: Run existing tests to verify no regression**

```bash
cd backend && go test -tags=integration ./domains/identity/... -v -count=1
```

Expected: all existing tests PASS.

- [ ] **Step 1.9: Commit**

```bash
git add backend/domains/identity/
git commit -m "refactor(identity): scaffold student split — stubs, interface, model types"
```

---

## Task 2: TDD — Register auto-creates StudentProfile

**Files:**
- Modify: `backend/domains/identity/service_integration_test.go`
- Modify: `backend/domains/identity/service.go`
- Modify: `backend/domains/identity/repository_student.go`

- [ ] **Step 2.1: Write failing test**

Add to `backend/domains/identity/service_integration_test.go`:

```go
func TestRegister_AutoCreatesStudentProfile(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	user, err := svc.Register(ctx, identity.RegisterInput{
		Email:    "profiletest@test.local",
		Password: "secret123",
		Name:     "Profile Test",
		Phone:    "0812",
		Role:     identity.RoleStudent,
		Source:   identity.SourceB2C,
	})
	require.NoError(t, err)

	student, err := svc.GetStudentByUserID(ctx, user.ID)
	require.NoError(t, err)

	profile, err := svc.GetStudentProfile(ctx, student.ID)
	require.NoError(t, err)
	require.NotNil(t, profile)
	require.Equal(t, student.ID, profile.StudentID)
	require.False(t, profile.ProfileComplete)
}
```

- [ ] **Step 2.2: Run test to confirm it fails**

```bash
cd backend && go test -tags=integration ./domains/identity/... -run TestRegister_AutoCreatesStudentProfile -v
```

Expected: FAIL — `profile` is nil (stub returns nil, nil).

- [ ] **Step 2.3: Implement CreateStudentProfile in repository_student.go**

Replace the `CreateStudentProfile` stub:

```go
func (r *repository) CreateStudentProfile(ctx context.Context, p *StudentProfile) error {
	query := `
		INSERT INTO identity.student_profiles
		  (id, student_id, date_of_birth, gender, id_type, id_number,
		   address, city, province, postal_code, profile_complete)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		p.ID, p.StudentID, p.DateOfBirth, p.Gender, p.IDType, p.IDNumber,
		p.Address, p.City, p.Province, p.PostalCode, p.ProfileComplete,
	).Scan(&p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		return fmt.Errorf("identity.CreateStudentProfile: %w", err)
	}
	return nil
}
```

Replace the `GetStudentProfile` stub:

```go
func (r *repository) GetStudentProfile(ctx context.Context, studentID uuid.UUID) (*StudentProfile, error) {
	query := `
		SELECT id, student_id, date_of_birth, gender, id_type, id_number,
		       address, city, province, postal_code, profile_complete, created_at, updated_at
		FROM identity.student_profiles WHERE student_id = $1`

	p := &StudentProfile{}
	err := r.pool.QueryRow(ctx, query, studentID).Scan(
		&p.ID, &p.StudentID, &p.DateOfBirth, &p.Gender, &p.IDType, &p.IDNumber,
		&p.Address, &p.City, &p.Province, &p.PostalCode, &p.ProfileComplete,
		&p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("identity.GetStudentProfile: %w", err)
	}
	return p, nil
}
```

- [ ] **Step 2.4: Update Register in service.go to auto-create profile**

In `service.go`, after the `CreateStudent` block inside `Register`, add:

```go
if in.Role == RoleStudent {
	student := &Student{
		ID:     uuid.New(),
		UserID: user.ID,
		Name:   in.Name,
		Email:  in.Email,
		Phone:  in.Phone,
		Source: in.Source,
	}
	if err := s.repo.CreateStudent(ctx, student); err != nil {
		return nil, err
	}
	// Auto-create empty profile row.
	profile := &StudentProfile{
		ID:        uuid.New(),
		StudentID: student.ID,
	}
	if err := s.repo.CreateStudentProfile(ctx, profile); err != nil {
		return nil, err
	}
}
```

- [ ] **Step 2.5: Run test to confirm it passes**

```bash
cd backend && go test -tags=integration ./domains/identity/... -run TestRegister_AutoCreatesStudentProfile -v
```

Expected: PASS.

- [ ] **Step 2.6: Run all identity tests to confirm no regression**

```bash
cd backend && go test -tags=integration ./domains/identity/... -v -count=1
```

Expected: all PASS.

- [ ] **Step 2.7: Commit**

```bash
git add backend/domains/identity/service.go backend/domains/identity/repository_student.go backend/domains/identity/service_integration_test.go
git commit -m "feat(identity): auto-create student_profiles on register"
```

---

## Task 3: Write failing integration tests for all new student service methods

**Files:**
- Create: `backend/domains/identity/service_student_integration_test.go`

- [ ] **Step 3.1: Create test file**

Create `backend/domains/identity/service_student_integration_test.go`:

```go
//go:build integration

package identity_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"

	"github.com/vernonedu/vernonedu2/backend/domains/identity"
)

// seedTwoStudents registers two students and returns them.
func seedTwoStudents(t *testing.T, svc *identity.Service) (*identity.Student, *identity.Student) {
	t.Helper()
	ctx := context.Background()

	u1, err := svc.Register(ctx, identity.RegisterInput{
		Email: "s1@test.local", Password: "pass", Name: "Alice", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	s1, err := svc.GetStudentByUserID(ctx, u1.ID)
	require.NoError(t, err)

	partnerID := uuid.New()
	u2, err := svc.Register(ctx, identity.RegisterInput{
		Email: "s2@test.local", Password: "pass", Name: "Bob", Phone: "0812",
		Role: identity.RoleStudent, Source: identity.SourceB2B,
	})
	require.NoError(t, err)
	s2, err := svc.GetStudentByUserID(ctx, u2.ID)
	require.NoError(t, err)

	// Assign partner_id directly via UpdateStudent
	s2.PartnerID = &partnerID
	err = svc.UpdateStudent(ctx, s2.ID, identity.UpdateStudentInput{
		Name: s2.Name, Email: s2.Email, Phone: s2.Phone,
		Source: identity.SourceB2B, PartnerID: &partnerID,
	})
	// This will fail (stub) but we only need the seed for filter tests — ignore for now
	_ = err

	return s1, s2
}

func TestListStudentsFiltered_FilterBySource(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	// Register one b2c and one b2b student
	_, err := svc.Register(ctx, identity.RegisterInput{
		Email: "b2c@test.local", Password: "pass", Name: "B2C Student", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	_, err = svc.Register(ctx, identity.RegisterInput{
		Email: "b2b@test.local", Password: "pass", Name: "B2B Student", Phone: "0812",
		Role: identity.RoleStudent, Source: identity.SourceB2B,
	})
	require.NoError(t, err)

	src := identity.SourceB2C
	results, err := svc.ListStudentsFiltered(ctx, identity.StudentFilter{Source: &src, Limit: 20})
	require.NoError(t, err)
	require.Len(t, results, 1)
	require.Equal(t, identity.SourceB2C, results[0].Source)
}

func TestListStudentsFiltered_SearchByName(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	_, err := svc.Register(ctx, identity.RegisterInput{
		Email: "charlie@test.local", Password: "pass", Name: "Charlie Brown", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	_, err = svc.Register(ctx, identity.RegisterInput{
		Email: "dave@test.local", Password: "pass", Name: "Dave Smith", Phone: "0812",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)

	results, err := svc.ListStudentsFiltered(ctx, identity.StudentFilter{Search: "charlie", Limit: 20})
	require.NoError(t, err)
	require.Len(t, results, 1)
	require.Contains(t, results[0].Name, "Charlie")
}

func TestListStudentsFiltered_SearchByEmail(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	_, err := svc.Register(ctx, identity.RegisterInput{
		Email: "unique.email@test.local", Password: "pass", Name: "Email Test", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	_, err = svc.Register(ctx, identity.RegisterInput{
		Email: "other@test.local", Password: "pass", Name: "Other Student", Phone: "0812",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)

	results, err := svc.ListStudentsFiltered(ctx, identity.StudentFilter{Search: "unique.email", Limit: 20})
	require.NoError(t, err)
	require.Len(t, results, 1)
	require.Equal(t, "unique.email@test.local", results[0].Email)
}

func TestListStudentsFiltered_FilterByProfileComplete(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "pc@test.local", Password: "pass", Name: "Profile Complete", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	student, err := svc.GetStudentByUserID(ctx, u.ID)
	require.NoError(t, err)

	dob := time.Date(2000, 1, 1, 0, 0, 0, 0, time.UTC)
	gender := "male"
	idType := "ktp"
	idNumber := "1234"
	addr := "Jl. Test 1"
	city := "Jakarta"
	province := "DKI Jakarta"
	postal := "12345"
	_, err = svc.UpdateStudentProfile(ctx, student.ID, identity.UpdateStudentProfileInput{
		DateOfBirth: &dob, Gender: &gender, IDType: &idType, IDNumber: &idNumber,
		Address: &addr, City: &city, Province: &province, PostalCode: &postal,
	})
	require.NoError(t, err)

	// Also register an incomplete student
	_, err = svc.Register(ctx, identity.RegisterInput{
		Email: "incomplete@test.local", Password: "pass", Name: "Incomplete", Phone: "0812",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)

	complete := true
	results, err := svc.ListStudentsFiltered(ctx, identity.StudentFilter{ProfileComplete: &complete, Limit: 20})
	require.NoError(t, err)
	require.Len(t, results, 1)
	require.Equal(t, student.ID, results[0].ID)
}

func TestListStudentsFiltered_SortByNameAsc(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	for _, name := range []string{"Zara", "Alice", "Mike"} {
		_, err := svc.Register(ctx, identity.RegisterInput{
			Email: name + "@test.local", Password: "pass", Name: name, Phone: "0811",
			Role: identity.RoleStudent, Source: identity.SourceB2C,
		})
		require.NoError(t, err)
	}

	results, err := svc.ListStudentsFiltered(ctx, identity.StudentFilter{
		SortBy: "name", SortDir: "asc", Limit: 20,
	})
	require.NoError(t, err)
	require.Len(t, results, 3)
	require.Equal(t, "Alice", results[0].Name)
	require.Equal(t, "Mike", results[1].Name)
	require.Equal(t, "Zara", results[2].Name)
}

func TestCountStudentsFiltered(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	for i := 0; i < 3; i++ {
		_, err := svc.Register(ctx, identity.RegisterInput{
			Email: fmt.Sprintf("count%d@test.local", i), Password: "pass",
			Name: fmt.Sprintf("Count %d", i), Phone: "0811",
			Role: identity.RoleStudent, Source: identity.SourceB2C,
		})
		require.NoError(t, err)
	}

	total, err := svc.CountStudentsFiltered(ctx, identity.StudentFilter{})
	require.NoError(t, err)
	require.Equal(t, 3, total)
}

func TestUpdateStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "update@test.local", Password: "pass", Name: "Original Name", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	student, err := svc.GetStudentByUserID(ctx, u.ID)
	require.NoError(t, err)

	updated, err := svc.UpdateStudent(ctx, student.ID, identity.UpdateStudentInput{
		Name: "Updated Name", Email: "updated@test.local", Phone: "0999",
		Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	require.Equal(t, "Updated Name", updated.Name)
	require.Equal(t, "updated@test.local", updated.Email)
}

func TestGetStudentProfile(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "getprofile@test.local", Password: "pass", Name: "Get Profile", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	student, err := svc.GetStudentByUserID(ctx, u.ID)
	require.NoError(t, err)

	profile, err := svc.GetStudentProfile(ctx, student.ID)
	require.NoError(t, err)
	require.NotNil(t, profile)
	require.Equal(t, student.ID, profile.StudentID)
	require.False(t, profile.ProfileComplete)
}

func TestUpdateStudentProfile_SetsProfileComplete(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "fullprofile@test.local", Password: "pass", Name: "Full Profile", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	student, err := svc.GetStudentByUserID(ctx, u.ID)
	require.NoError(t, err)

	dob := time.Date(1995, 6, 15, 0, 0, 0, 0, time.UTC)
	gender := "female"
	idType := "ktp"
	idNumber := "3201"
	addr := "Jl. Merdeka 10"
	city := "Bandung"
	province := "Jawa Barat"
	postal := "40111"

	profile, err := svc.UpdateStudentProfile(ctx, student.ID, identity.UpdateStudentProfileInput{
		DateOfBirth: &dob, Gender: &gender, IDType: &idType, IDNumber: &idNumber,
		Address: &addr, City: &city, Province: &province, PostalCode: &postal,
	})
	require.NoError(t, err)
	require.True(t, profile.ProfileComplete)
	require.Equal(t, &dob, profile.DateOfBirth)
	require.Equal(t, &gender, profile.Gender)
}

func TestUpdateStudentProfile_IncompleteDoesNotSetFlag(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "partial@test.local", Password: "pass", Name: "Partial", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)
	student, err := svc.GetStudentByUserID(ctx, u.ID)
	require.NoError(t, err)

	// Only fill some fields — should not set profile_complete
	city := "Surabaya"
	profile, err := svc.UpdateStudentProfile(ctx, student.ID, identity.UpdateStudentProfileInput{
		City: &city,
	})
	require.NoError(t, err)
	require.False(t, profile.ProfileComplete)
}
```

- [ ] **Step 3.2: Run tests to confirm they fail**

```bash
cd backend && go test -tags=integration ./domains/identity/... -run "TestListStudentsFiltered|TestCountStudentsFiltered|TestUpdateStudent|TestGetStudentProfile|TestUpdateStudentProfile" -v
```

Expected: most tests FAIL (stubs return nil results or wrong values).

---

## Task 4: Implement repository + service methods

**Files:**
- Modify: `backend/domains/identity/repository_student.go`
- Modify: `backend/domains/identity/service_student.go`

- [ ] **Step 4.1: Implement ListStudentsFiltered in repository_student.go**

Replace the `ListStudentsFiltered` stub:

```go
func (r *repository) ListStudentsFiltered(ctx context.Context, f StudentFilter) ([]*Student, error) {
	where, args := buildStudentWhere(f)

	col := studentSortCol(f.SortBy)
	dir := "DESC"
	if strings.EqualFold(f.SortDir, "asc") {
		dir = "ASC"
	}

	n := len(args) + 1
	query := fmt.Sprintf(`
		SELECT s.id, s.user_id, s.name, s.email, s.phone, s.source, s.partner_id, s.created_at, s.updated_at
		FROM identity.students s
		LEFT JOIN identity.student_profiles p ON p.student_id = s.id
		%s
		ORDER BY %s %s
		LIMIT $%d OFFSET $%d`,
		studentWhereClause(where), col, dir, n, n+1)

	args = append(args, f.Limit, f.Offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("identity.ListStudentsFiltered: %w", err)
	}
	defer rows.Close()

	var students []*Student
	for rows.Next() {
		s := &Student{}
		if err := rows.Scan(
			&s.ID, &s.UserID, &s.Name, &s.Email, &s.Phone, &s.Source,
			&s.PartnerID, &s.CreatedAt, &s.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("identity.ListStudentsFiltered scan: %w", err)
		}
		students = append(students, s)
	}
	return students, rows.Err()
}
```

- [ ] **Step 4.2: Implement CountStudentsFiltered**

Replace the `CountStudentsFiltered` stub:

```go
func (r *repository) CountStudentsFiltered(ctx context.Context, f StudentFilter) (int, error) {
	where, args := buildStudentWhere(f)

	query := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM identity.students s
		LEFT JOIN identity.student_profiles p ON p.student_id = s.id
		%s`, studentWhereClause(where))

	var count int
	if err := r.pool.QueryRow(ctx, query, args...).Scan(&count); err != nil {
		return 0, fmt.Errorf("identity.CountStudentsFiltered: %w", err)
	}
	return count, nil
}
```

- [ ] **Step 4.3: Implement UpdateStudent**

Replace the `UpdateStudent` stub:

```go
func (r *repository) UpdateStudent(ctx context.Context, s *Student) error {
	query := `
		UPDATE identity.students
		SET name=$1, email=$2, phone=$3, source=$4, partner_id=$5
		WHERE id=$6 RETURNING updated_at`

	err := r.pool.QueryRow(ctx, query,
		s.Name, s.Email, s.Phone, s.Source, s.PartnerID, s.ID,
	).Scan(&s.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("identity.UpdateStudent: %w", err)
	}
	return nil
}
```

- [ ] **Step 4.4: Implement UpdateStudentProfile**

Replace the `UpdateStudentProfile` stub:

```go
func (r *repository) UpdateStudentProfile(ctx context.Context, p *StudentProfile) error {
	query := `
		UPDATE identity.student_profiles
		SET date_of_birth=$1, gender=$2, id_type=$3, id_number=$4,
		    address=$5, city=$6, province=$7, postal_code=$8, profile_complete=$9
		WHERE student_id=$10 RETURNING updated_at`

	err := r.pool.QueryRow(ctx, query,
		p.DateOfBirth, p.Gender, p.IDType, p.IDNumber,
		p.Address, p.City, p.Province, p.PostalCode, p.ProfileComplete,
		p.StudentID,
	).Scan(&p.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("identity.UpdateStudentProfile: %w", err)
	}
	return nil
}
```

- [ ] **Step 4.5: Implement service methods in service_student.go**

Replace the `UpdateStudent` and `UpdateStudentProfile` stubs, and add `isProfileComplete`:

```go
// UpdateStudent updates student core fields.
func (s *Service) UpdateStudent(ctx context.Context, id uuid.UUID, in UpdateStudentInput) (*Student, error) {
	student, err := s.repo.GetStudentByID(ctx, id)
	if err != nil {
		return nil, err
	}
	student.Name = in.Name
	student.Email = in.Email
	student.Phone = in.Phone
	student.Source = in.Source
	student.PartnerID = in.PartnerID
	if err := s.repo.UpdateStudent(ctx, student); err != nil {
		return nil, err
	}
	return student, nil
}

// UpdateStudentProfile updates profile fields and recomputes profile_complete.
func (s *Service) UpdateStudentProfile(ctx context.Context, studentID uuid.UUID, in UpdateStudentProfileInput) (*StudentProfile, error) {
	profile, err := s.repo.GetStudentProfile(ctx, studentID)
	if err != nil {
		return nil, err
	}
	profile.DateOfBirth = in.DateOfBirth
	profile.Gender = in.Gender
	profile.IDType = in.IDType
	profile.IDNumber = in.IDNumber
	profile.Address = in.Address
	profile.City = in.City
	profile.Province = in.Province
	profile.PostalCode = in.PostalCode
	profile.ProfileComplete = isProfileComplete(profile)
	if err := s.repo.UpdateStudentProfile(ctx, profile); err != nil {
		return nil, err
	}
	return profile, nil
}

func isProfileComplete(p *StudentProfile) bool {
	return p.DateOfBirth != nil && p.Gender != nil && p.IDType != nil &&
		p.IDNumber != nil && p.Address != nil && p.City != nil &&
		p.Province != nil && p.PostalCode != nil
}
```

- [ ] **Step 4.6: Run all tests**

```bash
cd backend && go test -tags=integration ./domains/identity/... -v -count=1
```

Expected: ALL tests PASS (existing + new).

- [ ] **Step 4.7: Commit**

```bash
git add backend/domains/identity/repository_student.go backend/domains/identity/service_student.go backend/domains/identity/service_student_integration_test.go
git commit -m "feat(identity): implement student CRUD, profile management, filtered list"
```

---

## Task 5: Create handler_student.go + clean handler.go

**Files:**
- Modify: `backend/domains/identity/handler.go`
- Create: `backend/domains/identity/handler_student.go`

- [ ] **Step 5.1: Remove student methods from handler.go**

Delete these two methods from `backend/domains/identity/handler.go`:
- `func (h *Handler) ListStudents(...)`
- `func (h *Handler) GetStudent(...)`

Also remove unused `strconv` import if it's no longer used elsewhere in handler.go (check first).

- [ ] **Step 5.2: Create handler_student.go**

Create `backend/domains/identity/handler_student.go`:

```go
package identity

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// ─── Admin endpoints ──────────────────────────────────────────────────────────

func (h *Handler) ListStudents(w http.ResponseWriter, r *http.Request) {
	f := StudentFilter{
		Search:  r.URL.Query().Get("search"),
		SortBy:  r.URL.Query().Get("sort_by"),
		SortDir: r.URL.Query().Get("sort_dir"),
	}
	if src := r.URL.Query().Get("source"); src != "" {
		s := StudentSource(src)
		f.Source = &s
	}
	if pidStr := r.URL.Query().Get("partner_id"); pidStr != "" {
		pid, err := uuid.Parse(pidStr)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid partner_id"))
			return
		}
		f.PartnerID = &pid
	}
	if pcStr := r.URL.Query().Get("profile_complete"); pcStr != "" {
		pc := pcStr == "true"
		f.ProfileComplete = &pc
	}
	f.Limit, _ = strconv.Atoi(r.URL.Query().Get("limit"))
	f.Offset, _ = strconv.Atoi(r.URL.Query().Get("offset"))

	students, err := h.svc.ListStudentsFiltered(r.Context(), f)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	total, err := h.svc.CountStudentsFiltered(r.Context(), f)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"data":   students,
		"total":  total,
		"limit":  f.Limit,
		"offset": f.Offset,
	})
}

func (h *Handler) GetStudent(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid student id"))
		return
	}
	student, err := h.svc.GetStudentByID(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(student)
}

func (h *Handler) UpdateStudent(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid student id"))
		return
	}
	var req struct {
		Name      string        `json:"name"`
		Email     string        `json:"email"`
		Phone     string        `json:"phone"`
		Source    StudentSource `json:"source"`
		PartnerID *uuid.UUID    `json:"partner_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.Name == "" || req.Email == "" {
		apperrors.Render(w, apperrors.Validationf("name, email are required"))
		return
	}
	student, err := h.svc.UpdateStudent(r.Context(), id, UpdateStudentInput{
		Name: req.Name, Email: req.Email, Phone: req.Phone,
		Source: req.Source, PartnerID: req.PartnerID,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(student)
}

func (h *Handler) GetStudentProfileByID(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid student id"))
		return
	}
	profile, err := h.svc.GetStudentProfile(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(profile)
}

func (h *Handler) UpdateStudentProfileByAdmin(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid student id"))
		return
	}
	h.handleProfileUpdate(w, r, id)
}

// ─── Student self-service endpoints ──────────────────────────────────────────

func (h *Handler) GetMyStudent(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	student, err := h.svc.GetStudentByUserID(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(student)
}

func (h *Handler) UpdateMyStudentProfile(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	student, err := h.svc.GetStudentByUserID(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	h.handleProfileUpdate(w, r, student.ID)
}

// ─── Shared helper ────────────────────────────────────────────────────────────

func (h *Handler) handleProfileUpdate(w http.ResponseWriter, r *http.Request, studentID uuid.UUID) {
	var req struct {
		DateOfBirth *string `json:"date_of_birth"`
		Gender      *string `json:"gender"`
		IDType      *string `json:"id_type"`
		IDNumber    *string `json:"id_number"`
		Address     *string `json:"address"`
		City        *string `json:"city"`
		Province    *string `json:"province"`
		PostalCode  *string `json:"postal_code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	var dob *time.Time
	if req.DateOfBirth != nil {
		t, err := time.Parse("2006-01-02", *req.DateOfBirth)
		if err != nil {
			apperrors.Render(w, apperrors.Validationf("invalid date_of_birth format, use YYYY-MM-DD"))
			return
		}
		dob = &t
	}

	profile, err := h.svc.UpdateStudentProfile(r.Context(), studentID, UpdateStudentProfileInput{
		DateOfBirth: dob, Gender: req.Gender, IDType: req.IDType, IDNumber: req.IDNumber,
		Address: req.Address, City: req.City, Province: req.Province, PostalCode: req.PostalCode,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(profile)
}
```

- [ ] **Step 5.3: Verify build**

```bash
cd backend && go build ./...
```

Expected: no errors.

- [ ] **Step 5.4: Commit**

```bash
git add backend/domains/identity/handler.go backend/domains/identity/handler_student.go
git commit -m "refactor(identity): move student handlers to handler_student.go"
```

---

## Task 6: Update module.go — routes + RBAC

**Files:**
- Modify: `backend/domains/identity/module.go`

- [ ] **Step 6.1: Update module.go**

Replace the entire `RegisterRoutes` function with:

```go
const (
	roleAdmin          = "admin"
	roleCEO            = "ceo"
	roleVernonEduAdmin = "vernonedu_admin"
	roleStudent        = "student"
)

// RegisterRoutes mounts identity HTTP routes on the Chi router.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW         := mw.JWT(cfg.JWT.Secret)
	manageStudents := mw.RequireRole(roleAdmin, roleCEO, roleVernonEduAdmin)
	studentSelf    := mw.RequireRole(roleStudent)

	r.Post("/api/v1/auth/register", h.Register)
	r.Post("/api/v1/auth/login", h.Login)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Get("/api/v1/auth/me", h.GetMe)

		// Admin — student management
		r.With(manageStudents).Get("/api/v1/students", h.ListStudents)
		r.With(manageStudents).Get("/api/v1/students/{id}", h.GetStudent)
		r.With(manageStudents).Put("/api/v1/students/{id}", h.UpdateStudent)
		r.With(manageStudents).Get("/api/v1/students/{id}/profile", h.GetStudentProfileByID)
		r.With(manageStudents).Put("/api/v1/students/{id}/profile", h.UpdateStudentProfileByAdmin)

		// Student — self-service
		r.With(studentSelf).Get("/api/v1/me/student", h.GetMyStudent)
		r.With(studentSelf).Put("/api/v1/me/student/profile", h.UpdateMyStudentProfile)

		r.Delete("/api/v1/users/{id}", h.DeactivateUser)
		r.Get("/api/v1/departments", h.ListDepartments)
	})
}
```

- [ ] **Step 6.2: Build + existing tests**

```bash
cd backend && go build ./... && go test -tags=integration ./domains/identity/... -v -count=1
```

Expected: build passes, all tests PASS.

- [ ] **Step 6.3: Commit**

```bash
git add backend/domains/identity/module.go
git commit -m "feat(identity): add student management routes with RBAC"
```

---

## Task 7: Write handler RBAC tests

**Files:**
- Create: `backend/domains/identity/handler_student_test.go`

- [ ] **Step 7.1: Create handler_student_test.go**

Create `backend/domains/identity/handler_student_test.go`:

```go
//go:build integration

package identity_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/identity"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildStudentTestRouter(svc *identity.Service, role string) http.Handler {
	h := identity.NewHandler(svc, &config.Config{})
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: uuid.New(), Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	manageStudents := mw.RequireRole("admin", "ceo", "vernonedu_admin")
	studentSelf    := mw.RequireRole("student")

	r.With(manageStudents).Get("/api/v1/students", h.ListStudents)
	r.With(manageStudents).Get("/api/v1/students/{id}", h.GetStudent)
	r.With(manageStudents).Put("/api/v1/students/{id}", h.UpdateStudent)
	r.With(manageStudents).Get("/api/v1/students/{id}/profile", h.GetStudentProfileByID)
	r.With(manageStudents).Put("/api/v1/students/{id}/profile", h.UpdateStudentProfileByAdmin)
	r.With(studentSelf).Get("/api/v1/me/student", h.GetMyStudent)
	r.With(studentSelf).Put("/api/v1/me/student/profile", h.UpdateMyStudentProfile)

	return r
}

func TestStudentList_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/students", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestStudentList_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/students", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestUpdateStudent_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "student")

	req := httptest.NewRequest(http.MethodPut, "/api/v1/students/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestUpdateStudentProfileByAdmin_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "student")

	req := httptest.NewRequest(http.MethodPut, "/api/v1/students/"+uuid.New().String()+"/profile", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestGetMyStudent_ForbiddenForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/me/student", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestUpdateMyStudentProfile_ForbiddenForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	router := buildStudentTestRouter(svc, "admin")

	req := httptest.NewRequest(http.MethodPut, "/api/v1/me/student/profile", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestUpdateMyStudentProfile_AllowedForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	truncateIdentity(t, pool)

	svc := newTestService(t, pool)
	ctx := context.Background()

	// Register a student and get their user ID
	u, err := svc.Register(ctx, identity.RegisterInput{
		Email: "selfservice@test.local", Password: "pass", Name: "Self Service", Phone: "0811",
		Role: identity.RoleStudent, Source: identity.SourceB2C,
	})
	require.NoError(t, err)

	// Build router that injects this specific user's context
	h := identity.NewHandler(svc, &config.Config{})
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: u.ID, Role: "student"}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	studentSelf := mw.RequireRole("student")
	r.With(studentSelf).Put("/api/v1/me/student/profile", h.UpdateMyStudentProfile)

	body := `{"city":"Jakarta","province":"DKI Jakarta"}`
	req := httptest.NewRequest(http.MethodPut, "/api/v1/me/student/profile", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)

	var profile identity.StudentProfile
	require.NoError(t, json.NewDecoder(w.Body).Decode(&profile))
	require.NotNil(t, profile.City)
	require.Equal(t, "Jakarta", *profile.City)
}
```

- [ ] **Step 7.2: Run handler tests**

```bash
cd backend && go test -tags=integration ./domains/identity/... -run "TestStudent|TestUpdateMy|TestGetMy" -v -count=1
```

Expected: ALL PASS.

- [ ] **Step 7.3: Run full identity test suite**

```bash
cd backend && go test -tags=integration ./domains/identity/... -v -count=1
```

Expected: ALL PASS.

- [ ] **Step 7.4: Commit**

```bash
git add backend/domains/identity/handler_student_test.go
git commit -m "test(identity): add student HTTP RBAC enforcement tests"
```
