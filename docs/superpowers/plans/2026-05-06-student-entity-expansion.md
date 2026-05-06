# Student Entity Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 12 new fields (address, city, province, postal_code, birth_date, gender, nik, photo_url, education_level, school_name, emergency_contact_name, emergency_contact_phone) to the Student entity across DB, Go API, and React frontend.

**Architecture:** DB migration adds nullable columns with empty-string defaults → Go domain struct gains fields → commands/queries/repository propagate them through the stack → frontend form adds 4 tabs.

**Tech Stack:** PostgreSQL migration (SQL), Go (sqlx, chi), React 18 + TypeScript + CSS Modules

---

## File Map

| File | Action |
|------|--------|
| `api/migrations/083_student_profile_fields.sql` | CREATE |
| `api/internal/domain/student/student.go` | MODIFY — add 12 fields to `Student` struct and `StudentDetail` |
| `api/internal/command/create_student/handler.go` | MODIFY — `CreateStudentCommand` + `Handle` |
| `api/internal/command/update_student/handler.go` | MODIFY — `UpdateStudentCommand` + `Handle` |
| `api/internal/query/get_student/handler.go` | MODIFY — `StudentDetailReadModel` + mapping |
| `api/internal/delivery/http/student_handler.go` | MODIFY — `CreateStudentRequest`, `UpdateStudentRequest` |
| `api/infrastructure/database/student_repository.go` | MODIFY — `studentRecord`, `toDomain`, `Save`, `Update`, `GetByID`, `GetDetail` |
| `web-dashboard/src/pages/Students/StudentFormPage.tsx` | MODIFY — 4 tabs with all new fields |

---

### Task 1: DB Migration

**Files:**
- Create: `api/migrations/083_student_profile_fields.sql`

- [ ] **Step 1: Create migration file**

```sql
-- 083_student_profile_fields.sql
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS address                VARCHAR(500) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS city                   VARCHAR(100) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS province               VARCHAR(100) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS postal_code            VARCHAR(10)  NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS birth_date             DATE,
  ADD COLUMN IF NOT EXISTS gender                 VARCHAR(10)  NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS nik                    VARCHAR(20)  NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS photo_url              TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS education_level        VARCHAR(10)  NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS school_name            VARCHAR(255) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS emergency_contact_name  VARCHAR(255) NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(50)  NOT NULL DEFAULT '';
```

- [ ] **Step 2: Apply migration**

```bash
PGPASSWORD=postgres psql -h localhost -U postgres -d entrepreneurship_db -f api/migrations/083_student_profile_fields.sql
```

Expected output: `ALTER TABLE`

- [ ] **Step 3: Verify columns exist**

```bash
PGPASSWORD=postgres psql -h localhost -U postgres -d entrepreneurship_db -c "\d students"
```

Expected: 12 new columns visible.

- [ ] **Step 4: Commit**

```bash
git add api/migrations/083_student_profile_fields.sql
git commit -m "feat(db): add profile fields to students table"
```

---

### Task 2: Go Domain — Student Struct

**Files:**
- Modify: `api/internal/domain/student/student.go`

- [ ] **Step 1: Add 12 fields to `Student` struct and update `StudentDetail`**

Replace the `Student` struct and `StudentDetail` struct in `api/internal/domain/student/student.go`:

```go
type Student struct {
	ID           uuid.UUID
	Name         string
	Email        string
	Phone        string
	DepartmentID *uuid.UUID
	JoinedAt     time.Time
	IsActive     bool
	// Profile fields
	Address               string
	City                  string
	Province              string
	PostalCode            string
	BirthDate             *time.Time
	Gender                string
	NIK                   string
	PhotoURL              string
	EducationLevel        string
	SchoolName            string
	EmergencyContactName  string
	EmergencyContactPhone string
	CreatedAt             time.Time
	UpdatedAt             time.Time
}
```

Replace `StudentDetail`:

```go
type StudentDetail struct {
	Student
	DepartmentName   string
	TotalEnrollments int
	CompletedCourses int
}
```

(`StudentDetail` embeds `Student`, so no change needed to the struct — new fields come automatically.)

- [ ] **Step 2: Build to confirm no compile errors**

```bash
cd api && go build ./...
```

Expected: no output (success).

- [ ] **Step 3: Commit**

```bash
git add api/internal/domain/student/student.go
git commit -m "feat(domain): add 12 profile fields to Student struct"
```

---

### Task 3: Go Commands — Create & Update

**Files:**
- Modify: `api/internal/command/create_student/handler.go`
- Modify: `api/internal/command/update_student/handler.go`

- [ ] **Step 1: Update `CreateStudentCommand` and its `Handle` in `create_student/handler.go`**

Replace the command struct and `Handle` method:

```go
type CreateStudentCommand struct {
	Name                  string `validate:"required,min=1"`
	Email                 string `validate:"required,email"`
	Phone                 string
	DepartmentID          string
	Address               string
	City                  string
	Province              string
	PostalCode            string
	BirthDate             string // "YYYY-MM-DD" or ""
	Gender                string
	NIK                   string
	PhotoURL              string
	EducationLevel        string
	SchoolName            string
	EmergencyContactName  string
	EmergencyContactPhone string
}
```

Replace `Handle`:

```go
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateStudentCommand)
	if !ok {
		return ErrInvalidCommand
	}

	var deptID *uuid.UUID
	if c.DepartmentID != "" {
		id, err := uuid.Parse(c.DepartmentID)
		if err == nil {
			deptID = &id
		}
	}

	s, err := student.NewStudent(c.Name, c.Email, c.Phone, deptID)
	if err != nil {
		return err
	}

	s.Address = c.Address
	s.City = c.City
	s.Province = c.Province
	s.PostalCode = c.PostalCode
	s.Gender = c.Gender
	s.NIK = c.NIK
	s.PhotoURL = c.PhotoURL
	s.EducationLevel = c.EducationLevel
	s.SchoolName = c.SchoolName
	s.EmergencyContactName = c.EmergencyContactName
	s.EmergencyContactPhone = c.EmergencyContactPhone

	if c.BirthDate != "" {
		t, err := time.Parse("2006-01-02", c.BirthDate)
		if err == nil {
			s.BirthDate = &t
		}
	}

	if err := h.writeRepo.Save(ctx, s); err != nil {
		log.Error().Err(err).Msg("failed to save student")
		return err
	}

	_ = h.eventBus.Publish(ctx, &student.StudentCreated{StudentID: s.ID, Name: s.Name, Timestamp: time.Now().Unix()})
	log.Info().Str("student_id", s.ID.String()).Msg("student created")
	return nil
}
```

- [ ] **Step 2: Update `UpdateStudentCommand` and its `Handle` in `update_student/handler.go`**

Replace command struct:

```go
type UpdateStudentCommand struct {
	StudentID             uuid.UUID `validate:"required"`
	Name                  string    `validate:"required,min=1"`
	Email                 string    `validate:"required,email"`
	Phone                 string
	DepartmentID          string
	IsActive              bool
	Address               string
	City                  string
	Province              string
	PostalCode            string
	BirthDate             string // "YYYY-MM-DD" or ""
	Gender                string
	NIK                   string
	PhotoURL              string
	EducationLevel        string
	SchoolName            string
	EmergencyContactName  string
	EmergencyContactPhone string
}
```

Replace `Handle`:

```go
func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateStudentCommand)
	if !ok {
		return ErrInvalidCommand
	}

	s, err := h.readRepo.GetByID(ctx, c.StudentID)
	if err != nil {
		return err
	}

	s.Name = c.Name
	s.Email = c.Email
	s.Phone = c.Phone
	s.IsActive = c.IsActive
	s.Address = c.Address
	s.City = c.City
	s.Province = c.Province
	s.PostalCode = c.PostalCode
	s.Gender = c.Gender
	s.NIK = c.NIK
	s.PhotoURL = c.PhotoURL
	s.EducationLevel = c.EducationLevel
	s.SchoolName = c.SchoolName
	s.EmergencyContactName = c.EmergencyContactName
	s.EmergencyContactPhone = c.EmergencyContactPhone

	if c.BirthDate != "" {
		t, err := time.Parse("2006-01-02", c.BirthDate)
		if err == nil {
			s.BirthDate = &t
		}
	} else {
		s.BirthDate = nil
	}

	if c.DepartmentID != "" {
		id, err := uuid.Parse(c.DepartmentID)
		if err == nil {
			s.DepartmentID = &id
		}
	} else {
		s.DepartmentID = nil
	}
	s.UpdatedAt = time.Now()

	if err := h.writeRepo.Update(ctx, s); err != nil {
		log.Error().Err(err).Msg("failed to update student")
		return err
	}

	_ = h.eventBus.Publish(ctx, &student.StudentUpdated{StudentID: s.ID, Timestamp: time.Now().Unix()})
	log.Info().Str("student_id", s.ID.String()).Msg("student updated")
	return nil
}
```

- [ ] **Step 3: Build**

```bash
cd api && go build ./...
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add api/internal/command/create_student/handler.go api/internal/command/update_student/handler.go
git commit -m "feat(command): propagate 12 profile fields in create/update student commands"
```

---

### Task 4: Go Repository — studentRecord + queries

**Files:**
- Modify: `api/infrastructure/database/student_repository.go`

- [ ] **Step 1: Update `studentRecord` struct**

Replace the `studentRecord` struct:

```go
type studentRecord struct {
	ID           uuid.UUID  `db:"id"`
	Name         string     `db:"name"`
	Email        string     `db:"email"`
	Phone        string     `db:"phone"`
	DepartmentID *uuid.UUID `db:"department_id"`
	JoinedAt     time.Time  `db:"joined_at"`
	IsActive     bool       `db:"is_active"`
	// Profile fields
	Address               string     `db:"address"`
	City                  string     `db:"city"`
	Province              string     `db:"province"`
	PostalCode            string     `db:"postal_code"`
	BirthDate             *time.Time `db:"birth_date"`
	Gender                string     `db:"gender"`
	NIK                   string     `db:"nik"`
	PhotoURL              string     `db:"photo_url"`
	EducationLevel        string     `db:"education_level"`
	SchoolName            string     `db:"school_name"`
	EmergencyContactName  string     `db:"emergency_contact_name"`
	EmergencyContactPhone string     `db:"emergency_contact_phone"`
	CreatedAt             time.Time  `db:"created_at"`
	UpdatedAt             time.Time  `db:"updated_at"`
}
```

- [ ] **Step 2: Update `toDomain()` method**

Replace `toDomain`:

```go
func (rec *studentRecord) toDomain() *student.Student {
	return &student.Student{
		ID:                    rec.ID,
		Name:                  rec.Name,
		Email:                 rec.Email,
		Phone:                 rec.Phone,
		DepartmentID:          rec.DepartmentID,
		JoinedAt:              rec.JoinedAt,
		IsActive:              rec.IsActive,
		Address:               rec.Address,
		City:                  rec.City,
		Province:              rec.Province,
		PostalCode:            rec.PostalCode,
		BirthDate:             rec.BirthDate,
		Gender:                rec.Gender,
		NIK:                   rec.NIK,
		PhotoURL:              rec.PhotoURL,
		EducationLevel:        rec.EducationLevel,
		SchoolName:            rec.SchoolName,
		EmergencyContactName:  rec.EmergencyContactName,
		EmergencyContactPhone: rec.EmergencyContactPhone,
		CreatedAt:             rec.CreatedAt,
		UpdatedAt:             rec.UpdatedAt,
	}
}
```

- [ ] **Step 3: Update `Save` method**

Replace `Save`:

```go
func (r *StudentRepository) Save(ctx context.Context, s *student.Student) error {
	query := `
		INSERT INTO students (
			id, name, email, phone, department_id, joined_at, is_active,
			address, city, province, postal_code, birth_date, gender, nik, photo_url,
			education_level, school_name, emergency_contact_name, emergency_contact_phone,
			created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7,
			$8, $9, $10, $11, $12, $13, $14, $15,
			$16, $17, $18, $19,
			$20, $21
		)`
	_, err := r.db.ExecContext(ctx, query,
		s.ID, s.Name, s.Email, s.Phone, s.DepartmentID, s.JoinedAt, s.IsActive,
		s.Address, s.City, s.Province, s.PostalCode, s.BirthDate, s.Gender, s.NIK, s.PhotoURL,
		s.EducationLevel, s.SchoolName, s.EmergencyContactName, s.EmergencyContactPhone,
		s.CreatedAt, s.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save student: %w", err)
	}
	return nil
}
```

- [ ] **Step 4: Update `Update` method**

Replace `Update`:

```go
func (r *StudentRepository) Update(ctx context.Context, s *student.Student) error {
	query := `
		UPDATE students
		SET name = $1, email = $2, phone = $3, department_id = $4, is_active = $5,
		    address = $6, city = $7, province = $8, postal_code = $9, birth_date = $10,
		    gender = $11, nik = $12, photo_url = $13, education_level = $14,
		    school_name = $15, emergency_contact_name = $16, emergency_contact_phone = $17,
		    updated_at = $18
		WHERE id = $19`
	_, err := r.db.ExecContext(ctx, query,
		s.Name, s.Email, s.Phone, s.DepartmentID, s.IsActive,
		s.Address, s.City, s.Province, s.PostalCode, s.BirthDate,
		s.Gender, s.NIK, s.PhotoURL, s.EducationLevel,
		s.SchoolName, s.EmergencyContactName, s.EmergencyContactPhone,
		s.UpdatedAt, s.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update student: %w", err)
	}
	return nil
}
```

- [ ] **Step 5: Update `GetByID` SELECT query**

Replace the `GetByID` query string (keep surrounding code the same):

```go
func (r *StudentRepository) GetByID(ctx context.Context, id uuid.UUID) (*student.Student, error) {
	var rec studentRecord
	query := `
		SELECT id, name, email, phone, department_id, joined_at, is_active,
		       address, city, province, postal_code, birth_date, gender, nik, photo_url,
		       education_level, school_name, emergency_contact_name, emergency_contact_phone,
		       created_at, updated_at
		FROM students WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get student: %w", err)
	}
	return rec.toDomain(), nil
}
```

- [ ] **Step 6: Update `List` SELECT query**

Replace the `List` query string (keep surrounding logic the same):

```go
query := `
	SELECT id, name, email, phone, department_id, joined_at, is_active,
	       address, city, province, postal_code, birth_date, gender, nik, photo_url,
	       education_level, school_name, emergency_contact_name, emergency_contact_phone,
	       created_at, updated_at
	FROM students ORDER BY created_at DESC LIMIT $1 OFFSET $2`
```

- [ ] **Step 7: Update `ListWithCounts` SELECT query**

Replace the `query` fmt.Sprintf inside `ListWithCounts` (keep the GROUP BY and WHERE logic):

```go
query := fmt.Sprintf(`
	SELECT s.id, s.name, s.email, s.phone, s.department_id,
	       s.joined_at, s.is_active, s.created_at, s.updated_at,
	       s.address, s.city, s.province, s.postal_code, s.birth_date,
	       s.gender, s.nik, s.photo_url, s.education_level, s.school_name,
	       s.emergency_contact_name, s.emergency_contact_phone,
	       COUNT(CASE WHEN e.status = 'active' THEN 1 END)     AS active_batch_count,
	       COUNT(CASE WHEN e.status = 'completed' THEN 1 END)  AS completed_course_count
	FROM students s
	LEFT JOIN enrollments e ON e.student_id = s.id
	WHERE ($1='' OR s.name ILIKE $1)
	GROUP BY s.id, s.name, s.email, s.phone, s.department_id,
	         s.joined_at, s.is_active, s.created_at, s.updated_at,
	         s.address, s.city, s.province, s.postal_code, s.birth_date,
	         s.gender, s.nik, s.photo_url, s.education_level, s.school_name,
	         s.emergency_contact_name, s.emergency_contact_phone
	%s
	LIMIT $2 OFFSET $3`, orderBy)
```

- [ ] **Step 8: Update `GetDetail` SELECT query**

Replace the `query` inside `GetDetail`:

```go
query := `
	SELECT s.id, s.name, s.email, s.phone, s.department_id,
	       COALESCE(d.name, '') AS department_name,
	       s.joined_at, s.is_active, s.created_at, s.updated_at,
	       s.address, s.city, s.province, s.postal_code, s.birth_date,
	       s.gender, s.nik, s.photo_url, s.education_level, s.school_name,
	       s.emergency_contact_name, s.emergency_contact_phone,
	       COUNT(e.id)                                           AS total_enrollments,
	       COUNT(CASE WHEN e.status = 'completed' THEN 1 END)   AS completed_courses
	FROM students s
	LEFT JOIN departments d ON d.id = s.department_id
	LEFT JOIN enrollments e ON e.student_id = s.id
	WHERE s.id = $1
	GROUP BY s.id, s.name, s.email, s.phone, s.department_id, d.name,
	         s.joined_at, s.is_active, s.created_at, s.updated_at,
	         s.address, s.city, s.province, s.postal_code, s.birth_date,
	         s.gender, s.nik, s.photo_url, s.education_level, s.school_name,
	         s.emergency_contact_name, s.emergency_contact_phone`
```

- [ ] **Step 9: Build**

```bash
cd api && go build ./...
```

Expected: no output.

- [ ] **Step 10: Commit**

```bash
git add api/infrastructure/database/student_repository.go
git commit -m "feat(repo): add 12 profile fields to student repository queries"
```

---

### Task 5: Go Query Read Model

**Files:**
- Modify: `api/internal/query/get_student/handler.go`

- [ ] **Step 1: Update `StudentDetailReadModel` and its mapping**

Replace the full file content:

```go
package get_student

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
)

type GetStudentQuery struct {
	StudentID uuid.UUID
}

type StudentDetailReadModel struct {
	ID                    uuid.UUID `json:"id"`
	Name                  string    `json:"name"`
	Email                 string    `json:"email"`
	Phone                 string    `json:"phone"`
	DepartmentID          string    `json:"department_id"`
	DepartmentName        string    `json:"department_name"`
	JoinedAt              string    `json:"joined_at"`
	IsActive              bool      `json:"is_active"`
	TotalEnrollments      int       `json:"total_enrollments"`
	CompletedCourses      int       `json:"completed_courses"`
	Address               string    `json:"address"`
	City                  string    `json:"city"`
	Province              string    `json:"province"`
	PostalCode            string    `json:"postal_code"`
	BirthDate             string    `json:"birth_date"` // "YYYY-MM-DD" or ""
	Gender                string    `json:"gender"`
	NIK                   string    `json:"nik"`
	PhotoURL              string    `json:"photo_url"`
	EducationLevel        string    `json:"education_level"`
	SchoolName            string    `json:"school_name"`
	EmergencyContactName  string    `json:"emergency_contact_name"`
	EmergencyContactPhone string    `json:"emergency_contact_phone"`
	CreatedAt             int64     `json:"created_at"`
	UpdatedAt             int64     `json:"updated_at"`
}

type Handler struct {
	readRepo student.ReadRepository
}

func NewHandler(readRepo student.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetStudentQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	s, err := h.readRepo.GetDetail(ctx, q.StudentID)
	if err != nil {
		log.Error().Err(err).Str("student_id", q.StudentID.String()).Msg("failed to get student")
		return nil, err
	}

	deptID := ""
	if s.DepartmentID != nil {
		deptID = s.DepartmentID.String()
	}

	birthDate := ""
	if s.BirthDate != nil {
		birthDate = s.BirthDate.Format("2006-01-02")
	}

	return &StudentDetailReadModel{
		ID:                    s.ID,
		Name:                  s.Name,
		Email:                 s.Email,
		Phone:                 s.Phone,
		DepartmentID:          deptID,
		DepartmentName:        s.DepartmentName,
		JoinedAt:              s.JoinedAt.Format("2006-01-02T15:04:05Z07:00"),
		IsActive:              s.IsActive,
		TotalEnrollments:      s.TotalEnrollments,
		CompletedCourses:      s.CompletedCourses,
		Address:               s.Address,
		City:                  s.City,
		Province:              s.Province,
		PostalCode:            s.PostalCode,
		BirthDate:             birthDate,
		Gender:                s.Gender,
		NIK:                   s.NIK,
		PhotoURL:              s.PhotoURL,
		EducationLevel:        s.EducationLevel,
		SchoolName:            s.SchoolName,
		EmergencyContactName:  s.EmergencyContactName,
		EmergencyContactPhone: s.EmergencyContactPhone,
		CreatedAt:             s.CreatedAt.Unix(),
		UpdatedAt:             s.UpdatedAt.Unix(),
	}, nil
}
```

- [ ] **Step 2: Build**

```bash
cd api && go build ./...
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add api/internal/query/get_student/handler.go
git commit -m "feat(query): expose 12 profile fields in student detail read model"
```

---

### Task 6: HTTP Handler — Request Structs

**Files:**
- Modify: `api/internal/delivery/http/student_handler.go`

- [ ] **Step 1: Update `CreateStudentRequest` and `UpdateStudentRequest`**

Replace the two request structs (lines 46–59 in current file):

```go
type CreateStudentRequest struct {
	Name                  string `json:"name" validate:"required,min=1"`
	Email                 string `json:"email" validate:"required,email"`
	Phone                 string `json:"phone"`
	DepartmentID          string `json:"department_id"`
	Address               string `json:"address"`
	City                  string `json:"city"`
	Province              string `json:"province"`
	PostalCode            string `json:"postal_code"`
	BirthDate             string `json:"birth_date"` // "YYYY-MM-DD"
	Gender                string `json:"gender"`
	NIK                   string `json:"nik"`
	PhotoURL              string `json:"photo_url"`
	EducationLevel        string `json:"education_level"`
	SchoolName            string `json:"school_name"`
	EmergencyContactName  string `json:"emergency_contact_name"`
	EmergencyContactPhone string `json:"emergency_contact_phone"`
}

type UpdateStudentRequest struct {
	Name                  string `json:"name" validate:"required,min=1"`
	Email                 string `json:"email" validate:"required,email"`
	Phone                 string `json:"phone"`
	DepartmentID          string `json:"department_id"`
	IsActive              bool   `json:"is_active"`
	Address               string `json:"address"`
	City                  string `json:"city"`
	Province              string `json:"province"`
	PostalCode            string `json:"postal_code"`
	BirthDate             string `json:"birth_date"` // "YYYY-MM-DD"
	Gender                string `json:"gender"`
	NIK                   string `json:"nik"`
	PhotoURL              string `json:"photo_url"`
	EducationLevel        string `json:"education_level"`
	SchoolName            string `json:"school_name"`
	EmergencyContactName  string `json:"emergency_contact_name"`
	EmergencyContactPhone string `json:"emergency_contact_phone"`
}
```

- [ ] **Step 2: Update `Create` handler — pass new fields to command**

In the `Create` handler, replace the `cmd := &create_student.CreateStudentCommand{...}` block:

```go
cmd := &create_student.CreateStudentCommand{
	Name:                  req.Name,
	Email:                 req.Email,
	Phone:                 req.Phone,
	DepartmentID:          req.DepartmentID,
	Address:               req.Address,
	City:                  req.City,
	Province:              req.Province,
	PostalCode:            req.PostalCode,
	BirthDate:             req.BirthDate,
	Gender:                req.Gender,
	NIK:                   req.NIK,
	PhotoURL:              req.PhotoURL,
	EducationLevel:        req.EducationLevel,
	SchoolName:            req.SchoolName,
	EmergencyContactName:  req.EmergencyContactName,
	EmergencyContactPhone: req.EmergencyContactPhone,
}
```

- [ ] **Step 3: Update `Update` handler — pass new fields to command**

In the `Update` handler, replace the `cmd := &update_student.UpdateStudentCommand{...}` block:

```go
cmd := &update_student.UpdateStudentCommand{
	StudentID:             studentID,
	Name:                  req.Name,
	Email:                 req.Email,
	Phone:                 req.Phone,
	DepartmentID:          req.DepartmentID,
	IsActive:              req.IsActive,
	Address:               req.Address,
	City:                  req.City,
	Province:              req.Province,
	PostalCode:            req.PostalCode,
	BirthDate:             req.BirthDate,
	Gender:                req.Gender,
	NIK:                   req.NIK,
	PhotoURL:              req.PhotoURL,
	EducationLevel:        req.EducationLevel,
	SchoolName:            req.SchoolName,
	EmergencyContactName:  req.EmergencyContactName,
	EmergencyContactPhone: req.EmergencyContactPhone,
}
```

- [ ] **Step 4: Build**

```bash
cd api && go build ./...
```

Expected: no output.

- [ ] **Step 5: Run linter**

```bash
cd api && make lint 2>&1 | head -30
```

Expected: no new lint errors.

- [ ] **Step 6: Commit**

```bash
git add api/internal/delivery/http/student_handler.go
git commit -m "feat(http): propagate 12 profile fields in student create/update handlers"
```

---

### Task 7: Frontend — StudentFormPage 4 Tabs

**Files:**
- Modify: `web-dashboard/src/pages/Students/StudentFormPage.tsx`

- [ ] **Step 1: Replace `StudentFormPage.tsx` with 4-tab implementation**

Replace the full file:

```tsx
import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { User, Calendar, Clock } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
  Toggle,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { studentService } from '@/services/student.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const GENDER_OPTIONS = [
  { value: '', label: 'Pilih...' },
  { value: 'male', label: 'Laki-laki' },
  { value: 'female', label: 'Perempuan' },
]

const EDUCATION_OPTIONS = [
  { value: '', label: 'Pilih...' },
  { value: 'SD', label: 'SD' },
  { value: 'SMP', label: 'SMP' },
  { value: 'SMA', label: 'SMA/SMK' },
  { value: 'D1', label: 'D1' },
  { value: 'D2', label: 'D2' },
  { value: 'D3', label: 'D3' },
  { value: 'S1', label: 'S1' },
  { value: 'S2', label: 'S2' },
  { value: 'S3', label: 'S3' },
]

function formatDate(ts: number | undefined) {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(ts * 1000))
}

export default function StudentFormPage() {
  const navigate = useNavigate()
  const { studentId } = useParams<{ studentId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(studentId)

  // Tab 1 — Informasi Umum
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [gender, setGender] = useState('')
  const [birthDate, setBirthDate] = useState('')
  const [nik, setNik] = useState('')
  const [photoUrl, setPhotoUrl] = useState('')
  const [isActive, setIsActive] = useState(true)

  // Tab 2 — Alamat
  const [address, setAddress] = useState('')
  const [city, setCity] = useState('')
  const [province, setProvince] = useState('')
  const [postalCode, setPostalCode] = useState('')

  // Tab 3 — Pendidikan
  const [educationLevel, setEducationLevel] = useState('')
  const [schoolName, setSchoolName] = useState('')

  // Tab 4 — Kontak Darurat
  const [emergencyContactName, setEmergencyContactName] = useState('')
  const [emergencyContactPhone, setEmergencyContactPhone] = useState('')

  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: student } = useQuery({
    queryKey: ['student', studentId],
    queryFn: () => studentService.getById(studentId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (!student) return
    setName(student.name ?? '')
    setEmail(student.email ?? '')
    setPhone(student.phone ?? '')
    setGender(student.gender ?? '')
    setBirthDate(student.birth_date ?? '')
    setNik(student.nik ?? '')
    setPhotoUrl(student.photo_url ?? '')
    setIsActive(student.is_active ?? true)
    setAddress(student.address ?? '')
    setCity(student.city ?? '')
    setProvince(student.province ?? '')
    setPostalCode(student.postal_code ?? '')
    setEducationLevel(student.education_level ?? '')
    setSchoolName(student.school_name ?? '')
    setEmergencyContactName(student.emergency_contact_name ?? '')
    setEmergencyContactPhone(student.emergency_contact_phone ?? '')
  }, [student])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama siswa wajib diisi'
    else if (name.trim().length < 2) e.name = 'Minimal 2 karakter'
    if (!email.trim()) e.email = 'Email wajib diisi'
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) e.email = 'Format email tidak valid'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return
    setIsSubmitting(true)
    setServerError('')
    try {
      const base = {
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim() || undefined,
        gender: gender || undefined,
        birth_date: birthDate || undefined,
        nik: nik.trim() || undefined,
        photo_url: photoUrl.trim() || undefined,
        address: address.trim() || undefined,
        city: city.trim() || undefined,
        province: province.trim() || undefined,
        postal_code: postalCode.trim() || undefined,
        education_level: educationLevel || undefined,
        school_name: schoolName.trim() || undefined,
        emergency_contact_name: emergencyContactName.trim() || undefined,
        emergency_contact_phone: emergencyContactPhone.trim() || undefined,
      }
      if (isEdit) {
        await studentService.update(studentId!, { ...base, is_active: isActive })
        toast.success('Data siswa berhasil diperbarui')
      } else {
        await studentService.create(base)
        toast.success('Siswa berhasil ditambahkan')
      }
      await queryClient.invalidateQueries({ queryKey: ['students'] })
      navigate(isEdit ? `/students/${studentId}` : '/students')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const sidebarContent = (
    <FormColumn>
      {isEdit && student && (
        <Field label="Informasi">
          <div style={{
            padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            display: 'flex', flexDirection: 'column', gap: 'var(--space-3)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Calendar size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Dibuat</span>
              <span style={{ fontWeight: 500 }}>{formatDate(student.created_at)}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Clock size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Diperbarui</span>
              <span style={{ fontWeight: 500 }}>{formatDate(student.updated_at)}</span>
            </div>
          </div>
        </Field>
      )}
      {isEdit && (
        <Field label="Status Siswa" hint="Nonaktifkan jika siswa sudah alumni atau keluar.">
          <Toggle
            checked={isActive}
            onChange={setIsActive}
            label={isActive ? 'Aktif' : 'Alumni'}
          />
        </Field>
      )}
    </FormColumn>
  )

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Siswa' : 'Tambah Siswa'}
      icon={<User size={20} />}
      onBack={() => navigate(isEdit ? `/students/${studentId}` : '/students')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Umum',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Siswa" required error={errors.name}>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="cth. Budi Santoso"
                    className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field label="Email" required error={errors.email} hint="Email utama untuk notifikasi dan login.">
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="cth. budi@example.com"
                    className={`${formStyles.input} ${errors.email ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Telepon" hint="Nomor HP/WA untuk komunikasi.">
                  <input
                    type="tel"
                    inputMode="numeric"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value.replace(/[^0-9+]/g, ''))}
                    placeholder="cth. 08123456789"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Jenis Kelamin">
                  <select
                    value={gender}
                    onChange={(e) => setGender(e.target.value)}
                    className={formStyles.input}
                  >
                    {GENDER_OPTIONS.map(o => (
                      <option key={o.value} value={o.value}>{o.label}</option>
                    ))}
                  </select>
                </Field>
                <Field label="Tanggal Lahir">
                  <input
                    type="date"
                    value={birthDate}
                    onChange={(e) => setBirthDate(e.target.value)}
                    className={formStyles.input}
                  />
                </Field>
                <Field label="NIK" hint="Nomor Induk Kependudukan (KTP).">
                  <input
                    type="text"
                    inputMode="numeric"
                    value={nik}
                    onChange={(e) => setNik(e.target.value.replace(/[^0-9]/g, '').slice(0, 16))}
                    placeholder="16 digit NIK"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="URL Foto" hint="Link foto profil (opsional).">
                  <input
                    type="url"
                    value={photoUrl}
                    onChange={(e) => setPhotoUrl(e.target.value)}
                    placeholder="https://..."
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
              {sidebarContent}
            </FormGrid>
          ),
        },
        {
          id: 'address',
          label: 'Alamat',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Alamat Lengkap">
                  <textarea
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    placeholder="cth. Jl. Merdeka No. 10, RT 02/RW 05"
                    rows={3}
                    className={formStyles.input}
                    style={{ resize: 'vertical' }}
                  />
                </Field>
                <Field label="Kota">
                  <input
                    type="text"
                    value={city}
                    onChange={(e) => setCity(e.target.value)}
                    placeholder="cth. Jakarta Selatan"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Provinsi">
                  <input
                    type="text"
                    value={province}
                    onChange={(e) => setProvince(e.target.value)}
                    placeholder="cth. DKI Jakarta"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Kode Pos">
                  <input
                    type="text"
                    inputMode="numeric"
                    value={postalCode}
                    onChange={(e) => setPostalCode(e.target.value.replace(/[^0-9]/g, '').slice(0, 5))}
                    placeholder="cth. 12345"
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
        {
          id: 'education',
          label: 'Pendidikan',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Pendidikan Terakhir">
                  <select
                    value={educationLevel}
                    onChange={(e) => setEducationLevel(e.target.value)}
                    className={formStyles.input}
                  >
                    {EDUCATION_OPTIONS.map(o => (
                      <option key={o.value} value={o.value}>{o.label}</option>
                    ))}
                  </select>
                </Field>
                <Field label="Nama Sekolah / Universitas">
                  <input
                    type="text"
                    value={schoolName}
                    onChange={(e) => setSchoolName(e.target.value)}
                    placeholder="cth. Universitas Indonesia"
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
        {
          id: 'emergency',
          label: 'Kontak Darurat',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Kontak Darurat">
                  <input
                    type="text"
                    value={emergencyContactName}
                    onChange={(e) => setEmergencyContactName(e.target.value)}
                    placeholder="cth. Siti Rahayu (Ibu)"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Telepon Kontak Darurat">
                  <input
                    type="tel"
                    inputMode="numeric"
                    value={emergencyContactPhone}
                    onChange={(e) => setEmergencyContactPhone(e.target.value.replace(/[^0-9+]/g, ''))}
                    placeholder="cth. 08129876543"
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate(isEdit ? `/students/${studentId}` : '/students')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
```

- [ ] **Step 2: TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep StudentFormPage
```

Expected: no output (no errors).

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Students/StudentFormPage.tsx
git commit -m "feat(frontend): expand StudentFormPage to 4 tabs with 12 new profile fields"
```

---

### Task 8: End-to-End Verification

- [ ] **Step 1: Start API**

```bash
cd api && make dev
```

Expected: `starting server on :8081`

- [ ] **Step 2: Start frontend**

```bash
cd web-dashboard && npm run dev
```

Expected: `Local: http://localhost:3001/`

- [ ] **Step 3: Smoke test Create**

```bash
curl -s -X POST http://localhost:8081/api/v1/students \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "name": "Test Siswa",
    "email": "test@example.com",
    "phone": "08123456789",
    "gender": "male",
    "birth_date": "2000-01-15",
    "address": "Jl. Test No.1",
    "city": "Jakarta",
    "province": "DKI Jakarta",
    "postal_code": "12345",
    "education_level": "S1",
    "school_name": "UI",
    "emergency_contact_name": "Ibu Test",
    "emergency_contact_phone": "08199999999"
  }'
```

Expected: `{"message":"student created successfully"}`

- [ ] **Step 4: Smoke test Get**

```bash
STUDENT_ID=$(PGPASSWORD=postgres psql -h localhost -U postgres -d entrepreneurship_db -t -c "SELECT id FROM students WHERE email='test@example.com' LIMIT 1" | tr -d ' ')
curl -s http://localhost:8081/api/v1/students/$STUDENT_ID \
  -H "Authorization: Bearer <token>" | python3 -m json.tool | grep -E "city|province|education_level|birth_date"
```

Expected: all 4 fields present with correct values.

- [ ] **Step 5: Final commit if any fixes needed**

```bash
git add -p
git commit -m "fix(student): adjust after e2e verification"
```
