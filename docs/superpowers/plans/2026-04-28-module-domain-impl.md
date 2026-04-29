# Module Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the `module` domain — extract module entities from `catalog`, add `ClassModuleCoverage`, student access endpoints, and batch progress tracking.

**Architecture:** New `backend/domains/module/` package owns CourseModule, ModuleVersion, ModuleAsset, BatchModuleConfig, and ClassModuleCoverage. DB tables remain in `catalog` schema. Module entities are removed from catalog domain after the module domain is established.

**Tech Stack:** Go, Chi, Uber FX, pgx/v5, pgxpool, zap, testify, build tag `integration`

---

## File Map

| Action | File | Responsibility |
|--------|------|---------------|
| Create | `backend/migrations/000017_init_module.up.sql` | Add `coverage_status` enum + `class_module_coverages` table |
| Create | `backend/migrations/000017_init_module.down.sql` | Drop table + enum |
| Create | `backend/domains/module/model.go` | All 5 entity types + enums/constants |
| Create | `backend/domains/module/repository.go` | Repository interface + pgx implementation |
| Create | `backend/domains/module/service.go` | Business logic (CRUD, publish, version resolution, coverage, progress, access) |
| Create | `backend/domains/module/events.go` | Event type defs + subscription wiring |
| Create | `backend/domains/module/handler.go` | HTTP handlers for all 16 endpoints |
| Create | `backend/domains/module/module.go` | Uber FX module registration + route mounting |
| Create | `backend/domains/module/service_integration_test.go` | Integration tests |
| Modify | `backend/cmd/api/main.go` | Import + register `module.Module` |
| Modify | `backend/domains/catalog/model.go` | Remove CourseModule, ModuleVersion, ModuleAsset, BatchModuleConfig types + enums |
| Modify | `backend/domains/catalog/repository.go` | Remove module-related interface methods + implementations |
| Modify | `backend/domains/catalog/service.go` | Remove CreateModule, ListModulesByCourse, CreateModuleVersion methods |

---

## Task 1: Migration

**Files:**
- Create: `backend/migrations/000017_init_module.up.sql`
- Create: `backend/migrations/000017_init_module.down.sql`

- [ ] **Step 1: Create up migration**

```sql
-- backend/migrations/000017_init_module.up.sql
CREATE TYPE catalog.coverage_status AS ENUM ('planned', 'covered');

CREATE TABLE catalog.class_module_coverages (
  id              UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id        UUID                    NOT NULL REFERENCES catalog.classes(id) ON DELETE CASCADE,
  module_id       UUID                    NOT NULL REFERENCES catalog.modules(id) ON DELETE CASCADE,
  status          catalog.coverage_status NOT NULL DEFAULT 'planned',
  covered_by      UUID                    NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  covered_at      TIMESTAMPTZ             NULL,
  is_auto_covered BOOLEAN                 NOT NULL DEFAULT FALSE,
  notes           TEXT                    NULL,
  created_by      UUID                    NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at      TIMESTAMPTZ             NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ             NOT NULL DEFAULT now(),
  CONSTRAINT uq_class_module UNIQUE (class_id, module_id)
);
SELECT attach_updated_at_trigger('catalog', 'class_module_coverages');
CREATE INDEX idx_class_module_coverages_class  ON catalog.class_module_coverages(class_id);
CREATE INDEX idx_class_module_coverages_module ON catalog.class_module_coverages(module_id);
```

- [ ] **Step 2: Create down migration**

```sql
-- backend/migrations/000017_init_module.down.sql
DROP TABLE IF EXISTS catalog.class_module_coverages;
DROP TYPE IF EXISTS catalog.coverage_status;
```

- [ ] **Step 3: Run migration**

```bash
make migrate-up
```

Expected: migration applies cleanly, no errors.

- [ ] **Step 4: Commit**

```bash
git add backend/migrations/000017_init_module.up.sql backend/migrations/000017_init_module.down.sql
git commit -m "feat(module): add class_module_coverages migration"
```

---

## Task 2: Model

**Files:**
- Create: `backend/domains/module/model.go`

- [ ] **Step 1: Write model.go**

```go
package module

import (
	"time"

	"github.com/google/uuid"
)

type ModuleStatus string

const (
	ModuleDraft     ModuleStatus = "draft"
	ModulePublished ModuleStatus = "published"
	ModuleArchived  ModuleStatus = "archived"
)

type AssetType string

const (
	AssetVideo    AssetType = "video"
	AssetPDF      AssetType = "pdf"
	AssetDocument AssetType = "document"
	AssetLink     AssetType = "link"
	AssetImage    AssetType = "image"
	AssetOther    AssetType = "other"
)

type VersionPolicy string

const (
	PolicyAutoLatest VersionPolicy = "auto_latest"
	PolicyLocked     VersionPolicy = "locked"
)

type CoverageStatus string

const (
	CoveragePlanned CoverageStatus = "planned"
	CoverageCovered CoverageStatus = "covered"
)

type CourseModule struct {
	ID        uuid.UUID `json:"id"`
	CourseID  uuid.UUID `json:"course_id"`
	Title     string    `json:"title"`
	Order     int       `json:"order"`
	IsActive  bool      `json:"is_active"`
	CreatedBy uuid.UUID `json:"created_by"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type ModuleVersion struct {
	ID            uuid.UUID    `json:"id"`
	ModuleID      uuid.UUID    `json:"module_id"`
	VersionNumber int          `json:"version_number"`
	Title         string       `json:"title"`
	Description   *string      `json:"description,omitempty"`
	Status        ModuleStatus `json:"status"`
	PublishedAt   *time.Time   `json:"published_at,omitempty"`
	PublishedBy   *uuid.UUID   `json:"published_by,omitempty"`
	CreatedBy     uuid.UUID    `json:"created_by"`
	CreatedAt     time.Time    `json:"created_at"`
	UpdatedAt     time.Time    `json:"updated_at"`
}

type ModuleAsset struct {
	ID              uuid.UUID `json:"id"`
	ModuleVersionID uuid.UUID `json:"module_version_id"`
	Title           string    `json:"title"`
	AssetType       AssetType `json:"asset_type"`
	URL             string    `json:"url"`
	SizeBytes       *int64    `json:"size_bytes,omitempty"`
	Order           int       `json:"order"`
	IsDownloadable  bool      `json:"is_downloadable"`
	CreatedBy       uuid.UUID `json:"created_by"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

type BatchModuleConfig struct {
	ID              uuid.UUID     `json:"id"`
	CourseBatchID   uuid.UUID     `json:"course_batch_id"`
	ModuleID        uuid.UUID     `json:"module_id"`
	VersionPolicy   VersionPolicy `json:"version_policy"`
	LockedVersionID *uuid.UUID    `json:"locked_version_id,omitempty"`
	SetBy           uuid.UUID     `json:"set_by"`
	CreatedAt       time.Time     `json:"created_at"`
	UpdatedAt       time.Time     `json:"updated_at"`
}

type ClassModuleCoverage struct {
	ID            uuid.UUID      `json:"id"`
	ClassID       uuid.UUID      `json:"class_id"`
	ModuleID      uuid.UUID      `json:"module_id"`
	Status        CoverageStatus `json:"status"`
	CoveredBy     *uuid.UUID     `json:"covered_by,omitempty"`
	CoveredAt     *time.Time     `json:"covered_at,omitempty"`
	IsAutoCovered bool           `json:"is_auto_covered"`
	Notes         *string        `json:"notes,omitempty"`
	CreatedBy     uuid.UUID      `json:"created_by"`
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`
}

// BatchProgress is a read model for batch progress summary.
type BatchProgress struct {
	BatchID        uuid.UUID `json:"batch_id"`
	TotalModules   int       `json:"total_modules"`
	CoveredModules int       `json:"covered_modules"`
	ProgressPct    float64   `json:"progress_pct"`
}

// StudentModuleView is a read model for student-facing module list.
type StudentModuleView struct {
	ModuleID      uuid.UUID      `json:"module_id"`
	Title         string         `json:"title"`
	Order         int            `json:"order"`
	VersionID     uuid.UUID      `json:"version_id"`
	VersionTitle  string         `json:"version_title"`
	VersionNumber int            `json:"version_number"`
	Assets        []*ModuleAsset `json:"assets"`
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/domains/module/model.go
git commit -m "feat(module): add domain models"
```

---

## Task 3: Repository

**Files:**
- Create: `backend/domains/module/repository.go`

- [ ] **Step 1: Write repository interface + implementation**

```go
package module

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// Repository defines module domain data access.
type Repository interface {
	// Course helper (cross-schema read)
	GetCourseCreatorID(ctx context.Context, courseID uuid.UUID) (uuid.UUID, error)
	GetBatchCourseID(ctx context.Context, batchID uuid.UUID) (uuid.UUID, error)
	GetClassInstructorID(ctx context.Context, classID uuid.UUID) (uuid.UUID, error)
	GetClassBatchID(ctx context.Context, classID uuid.UUID) (uuid.UUID, error)
	IsStudentEnrolled(ctx context.Context, studentID, batchID uuid.UUID) (bool, error)
	GetEnrollmentBatchID(ctx context.Context, enrollmentID uuid.UUID) (uuid.UUID, error)

	// CourseModule
	CreateModule(ctx context.Context, m *CourseModule) error
	GetModuleByID(ctx context.Context, id uuid.UUID) (*CourseModule, error)
	ListModulesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error)
	UpdateModule(ctx context.Context, m *CourseModule) error

	// ModuleVersion
	CreateModuleVersion(ctx context.Context, mv *ModuleVersion) error
	GetModuleVersionByID(ctx context.Context, id uuid.UUID) (*ModuleVersion, error)
	ListVersionsByModule(ctx context.Context, moduleID uuid.UUID) ([]*ModuleVersion, error)
	GetLatestPublishedVersion(ctx context.Context, moduleID uuid.UUID) (*ModuleVersion, error)
	CountVersionsByModule(ctx context.Context, moduleID uuid.UUID) (int, error)
	ArchivePreviousPublished(ctx context.Context, moduleID uuid.UUID) error
	PublishVersion(ctx context.Context, versionID uuid.UUID, publishedBy uuid.UUID, publishedAt time.Time) error

	// ModuleAsset
	CreateAsset(ctx context.Context, a *ModuleAsset) error
	GetAssetByID(ctx context.Context, id uuid.UUID) (*ModuleAsset, error)
	UpdateAsset(ctx context.Context, a *ModuleAsset) error
	DeleteAsset(ctx context.Context, id uuid.UUID) error
	ListAssetsByVersion(ctx context.Context, versionID uuid.UUID) ([]*ModuleAsset, error)

	// BatchModuleConfig
	UpsertBatchModuleConfig(ctx context.Context, c *BatchModuleConfig) error
	GetBatchModuleConfig(ctx context.Context, batchID, moduleID uuid.UUID) (*BatchModuleConfig, error)
	ListBatchModuleConfigs(ctx context.Context, batchID uuid.UUID) ([]*BatchModuleConfig, error)

	// ClassModuleCoverage
	CreateCoverage(ctx context.Context, c *ClassModuleCoverage) error
	GetCoverageByID(ctx context.Context, id uuid.UUID) (*ClassModuleCoverage, error)
	ListCoverageByClass(ctx context.Context, classID uuid.UUID) ([]*ClassModuleCoverage, error)
	UpdateCoverage(ctx context.Context, c *ClassModuleCoverage) error
	DeleteCoverage(ctx context.Context, id uuid.UUID) error
	AutoFlipPlannedToCovered(ctx context.Context, classID uuid.UUID, coveredAt time.Time) error

	// Progress
	GetBatchProgress(ctx context.Context, batchID uuid.UUID) (*BatchProgress, error)

	// Student access
	ListActiveModulesWithPublishedVersion(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error)
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository creates a module repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

// ─── Cross-schema helpers ─────────────────────────────────────────────────────

func (r *repository) GetCourseCreatorID(ctx context.Context, courseID uuid.UUID) (uuid.UUID, error) {
	var id uuid.UUID
	err := r.pool.QueryRow(ctx,
		`SELECT course_creator_id FROM catalog.courses WHERE id = $1`, courseID,
	).Scan(&id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return uuid.UUID{}, apperrors.ErrNotFound
		}
		return uuid.UUID{}, fmt.Errorf("module.GetCourseCreatorID: %w", err)
	}
	return id, nil
}

func (r *repository) GetBatchCourseID(ctx context.Context, batchID uuid.UUID) (uuid.UUID, error) {
	var id uuid.UUID
	err := r.pool.QueryRow(ctx,
		`SELECT course_id FROM catalog.course_batches WHERE id = $1`, batchID,
	).Scan(&id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return uuid.UUID{}, apperrors.ErrNotFound
		}
		return uuid.UUID{}, fmt.Errorf("module.GetBatchCourseID: %w", err)
	}
	return id, nil
}

func (r *repository) GetClassInstructorID(ctx context.Context, classID uuid.UUID) (uuid.UUID, error) {
	var id uuid.UUID
	err := r.pool.QueryRow(ctx,
		`SELECT instructor_id FROM catalog.classes WHERE id = $1`, classID,
	).Scan(&id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return uuid.UUID{}, apperrors.ErrNotFound
		}
		return uuid.UUID{}, fmt.Errorf("module.GetClassInstructorID: %w", err)
	}
	return id, nil
}

func (r *repository) GetClassBatchID(ctx context.Context, classID uuid.UUID) (uuid.UUID, error) {
	var id uuid.UUID
	err := r.pool.QueryRow(ctx,
		`SELECT course_batch_id FROM catalog.classes WHERE id = $1`, classID,
	).Scan(&id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return uuid.UUID{}, apperrors.ErrNotFound
		}
		return uuid.UUID{}, fmt.Errorf("module.GetClassBatchID: %w", err)
	}
	return id, nil
}

func (r *repository) IsStudentEnrolled(ctx context.Context, studentID, batchID uuid.UUID) (bool, error) {
	var count int
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM enrollment.enrollments
		 WHERE student_id = $1 AND course_batch_id = $2 AND status = 'confirmed'`,
		studentID, batchID,
	).Scan(&count)
	if err != nil {
		return false, fmt.Errorf("module.IsStudentEnrolled: %w", err)
	}
	return count > 0, nil
}

func (r *repository) GetEnrollmentBatchID(ctx context.Context, enrollmentID uuid.UUID) (uuid.UUID, error) {
	var batchID uuid.UUID
	err := r.pool.QueryRow(ctx,
		`SELECT course_batch_id FROM enrollment.enrollments WHERE id = $1`, enrollmentID,
	).Scan(&batchID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return uuid.UUID{}, apperrors.ErrNotFound
		}
		return uuid.UUID{}, fmt.Errorf("module.GetEnrollmentBatchID: %w", err)
	}
	return batchID, nil
}

// ─── CourseModule ─────────────────────────────────────────────────────────────

func (r *repository) CreateModule(ctx context.Context, m *CourseModule) error {
	query := `
		INSERT INTO catalog.modules (id, course_id, title, "order", is_active, created_by)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING created_at, updated_at`
	err := r.pool.QueryRow(ctx, query,
		m.ID, m.CourseID, m.Title, m.Order, m.IsActive, m.CreatedBy,
	).Scan(&m.CreatedAt, &m.UpdatedAt)
	if err != nil {
		return fmt.Errorf("module.CreateModule: %w", err)
	}
	return nil
}

func (r *repository) GetModuleByID(ctx context.Context, id uuid.UUID) (*CourseModule, error) {
	query := `SELECT id, course_id, title, "order", is_active, created_by, created_at, updated_at
	          FROM catalog.modules WHERE id = $1`
	m := &CourseModule{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&m.ID, &m.CourseID, &m.Title, &m.Order, &m.IsActive, &m.CreatedBy, &m.CreatedAt, &m.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("module.GetModuleByID: %w", err)
	}
	return m, nil
}

func (r *repository) ListModulesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error) {
	query := `SELECT id, course_id, title, "order", is_active, created_by, created_at, updated_at
	          FROM catalog.modules WHERE course_id = $1 ORDER BY "order"`
	rows, err := r.pool.Query(ctx, query, courseID)
	if err != nil {
		return nil, fmt.Errorf("module.ListModulesByCourse: %w", err)
	}
	defer rows.Close()

	var out []*CourseModule
	for rows.Next() {
		m := &CourseModule{}
		if err := rows.Scan(&m.ID, &m.CourseID, &m.Title, &m.Order, &m.IsActive, &m.CreatedBy, &m.CreatedAt, &m.UpdatedAt); err != nil {
			return nil, fmt.Errorf("module.ListModulesByCourse scan: %w", err)
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

func (r *repository) UpdateModule(ctx context.Context, m *CourseModule) error {
	query := `UPDATE catalog.modules SET title=$1, "order"=$2, is_active=$3 WHERE id=$4
	          RETURNING updated_at`
	err := r.pool.QueryRow(ctx, query, m.Title, m.Order, m.IsActive, m.ID).Scan(&m.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("module.UpdateModule: %w", err)
	}
	return nil
}

func (r *repository) ListActiveModulesWithPublishedVersion(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error) {
	query := `SELECT DISTINCT m.id, m.course_id, m.title, m."order", m.is_active, m.created_by, m.created_at, m.updated_at
	          FROM catalog.modules m
	          JOIN catalog.module_versions mv ON mv.module_id = m.id AND mv.status = 'published'
	          WHERE m.course_id = $1 AND m.is_active = true
	          ORDER BY m."order"`
	rows, err := r.pool.Query(ctx, query, courseID)
	if err != nil {
		return nil, fmt.Errorf("module.ListActiveModulesWithPublishedVersion: %w", err)
	}
	defer rows.Close()

	var out []*CourseModule
	for rows.Next() {
		m := &CourseModule{}
		if err := rows.Scan(&m.ID, &m.CourseID, &m.Title, &m.Order, &m.IsActive, &m.CreatedBy, &m.CreatedAt, &m.UpdatedAt); err != nil {
			return nil, fmt.Errorf("module.ListActiveModulesWithPublishedVersion scan: %w", err)
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

// ─── ModuleVersion ────────────────────────────────────────────────────────────

func (r *repository) CreateModuleVersion(ctx context.Context, mv *ModuleVersion) error {
	query := `
		INSERT INTO catalog.module_versions (id, module_id, version_number, title, description, status, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at, updated_at`
	err := r.pool.QueryRow(ctx, query,
		mv.ID, mv.ModuleID, mv.VersionNumber, mv.Title, mv.Description, mv.Status, mv.CreatedBy,
	).Scan(&mv.CreatedAt, &mv.UpdatedAt)
	if err != nil {
		return fmt.Errorf("module.CreateModuleVersion: %w", err)
	}
	return nil
}

func (r *repository) GetModuleVersionByID(ctx context.Context, id uuid.UUID) (*ModuleVersion, error) {
	query := `SELECT id, module_id, version_number, title, description, status, published_at, published_by, created_by, created_at, updated_at
	          FROM catalog.module_versions WHERE id = $1`
	mv := &ModuleVersion{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&mv.ID, &mv.ModuleID, &mv.VersionNumber, &mv.Title, &mv.Description,
		&mv.Status, &mv.PublishedAt, &mv.PublishedBy, &mv.CreatedBy, &mv.CreatedAt, &mv.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("module.GetModuleVersionByID: %w", err)
	}
	return mv, nil
}

func (r *repository) ListVersionsByModule(ctx context.Context, moduleID uuid.UUID) ([]*ModuleVersion, error) {
	query := `SELECT id, module_id, version_number, title, description, status, published_at, published_by, created_by, created_at, updated_at
	          FROM catalog.module_versions WHERE module_id = $1 ORDER BY version_number DESC`
	rows, err := r.pool.Query(ctx, query, moduleID)
	if err != nil {
		return nil, fmt.Errorf("module.ListVersionsByModule: %w", err)
	}
	defer rows.Close()

	var out []*ModuleVersion
	for rows.Next() {
		mv := &ModuleVersion{}
		if err := rows.Scan(&mv.ID, &mv.ModuleID, &mv.VersionNumber, &mv.Title, &mv.Description,
			&mv.Status, &mv.PublishedAt, &mv.PublishedBy, &mv.CreatedBy, &mv.CreatedAt, &mv.UpdatedAt); err != nil {
			return nil, fmt.Errorf("module.ListVersionsByModule scan: %w", err)
		}
		out = append(out, mv)
	}
	return out, rows.Err()
}

func (r *repository) GetLatestPublishedVersion(ctx context.Context, moduleID uuid.UUID) (*ModuleVersion, error) {
	query := `SELECT id, module_id, version_number, title, description, status, published_at, published_by, created_by, created_at, updated_at
	          FROM catalog.module_versions
	          WHERE module_id = $1 AND status = 'published'
	          ORDER BY version_number DESC LIMIT 1`
	mv := &ModuleVersion{}
	err := r.pool.QueryRow(ctx, query, moduleID).Scan(
		&mv.ID, &mv.ModuleID, &mv.VersionNumber, &mv.Title, &mv.Description,
		&mv.Status, &mv.PublishedAt, &mv.PublishedBy, &mv.CreatedBy, &mv.CreatedAt, &mv.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("module.GetLatestPublishedVersion: %w", err)
	}
	return mv, nil
}

func (r *repository) CountVersionsByModule(ctx context.Context, moduleID uuid.UUID) (int, error) {
	var count int
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM catalog.module_versions WHERE module_id = $1`, moduleID,
	).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("module.CountVersionsByModule: %w", err)
	}
	return count, nil
}

func (r *repository) ArchivePreviousPublished(ctx context.Context, moduleID uuid.UUID) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE catalog.module_versions SET status = 'archived'
		 WHERE module_id = $1 AND status = 'published'`, moduleID)
	if err != nil {
		return fmt.Errorf("module.ArchivePreviousPublished: %w", err)
	}
	return nil
}

func (r *repository) PublishVersion(ctx context.Context, versionID uuid.UUID, publishedBy uuid.UUID, publishedAt time.Time) error {
	result, err := r.pool.Exec(ctx,
		`UPDATE catalog.module_versions SET status = 'published', published_by = $1, published_at = $2
		 WHERE id = $3 AND status = 'draft'`,
		publishedBy, publishedAt, versionID)
	if err != nil {
		return fmt.Errorf("module.PublishVersion: %w", err)
	}
	if result.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

// ─── ModuleAsset ──────────────────────────────────────────────────────────────

func (r *repository) CreateAsset(ctx context.Context, a *ModuleAsset) error {
	query := `
		INSERT INTO catalog.module_assets (id, module_version_id, title, asset_type, url, size_bytes, "order", is_downloadable, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING created_at, updated_at`
	err := r.pool.QueryRow(ctx, query,
		a.ID, a.ModuleVersionID, a.Title, a.AssetType, a.URL, a.SizeBytes, a.Order, a.IsDownloadable, a.CreatedBy,
	).Scan(&a.CreatedAt, &a.UpdatedAt)
	if err != nil {
		return fmt.Errorf("module.CreateAsset: %w", err)
	}
	return nil
}

func (r *repository) GetAssetByID(ctx context.Context, id uuid.UUID) (*ModuleAsset, error) {
	query := `SELECT id, module_version_id, title, asset_type, url, size_bytes, "order", is_downloadable, created_by, created_at, updated_at
	          FROM catalog.module_assets WHERE id = $1`
	a := &ModuleAsset{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&a.ID, &a.ModuleVersionID, &a.Title, &a.AssetType, &a.URL, &a.SizeBytes,
		&a.Order, &a.IsDownloadable, &a.CreatedBy, &a.CreatedAt, &a.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("module.GetAssetByID: %w", err)
	}
	return a, nil
}

func (r *repository) UpdateAsset(ctx context.Context, a *ModuleAsset) error {
	query := `UPDATE catalog.module_assets
	          SET title=$1, asset_type=$2, url=$3, size_bytes=$4, "order"=$5, is_downloadable=$6
	          WHERE id=$7
	          RETURNING updated_at`
	err := r.pool.QueryRow(ctx, query,
		a.Title, a.AssetType, a.URL, a.SizeBytes, a.Order, a.IsDownloadable, a.ID,
	).Scan(&a.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("module.UpdateAsset: %w", err)
	}
	return nil
}

func (r *repository) DeleteAsset(ctx context.Context, id uuid.UUID) error {
	result, err := r.pool.Exec(ctx, `DELETE FROM catalog.module_assets WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("module.DeleteAsset: %w", err)
	}
	if result.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListAssetsByVersion(ctx context.Context, versionID uuid.UUID) ([]*ModuleAsset, error) {
	query := `SELECT id, module_version_id, title, asset_type, url, size_bytes, "order", is_downloadable, created_by, created_at, updated_at
	          FROM catalog.module_assets WHERE module_version_id = $1 ORDER BY "order"`
	rows, err := r.pool.Query(ctx, query, versionID)
	if err != nil {
		return nil, fmt.Errorf("module.ListAssetsByVersion: %w", err)
	}
	defer rows.Close()

	var out []*ModuleAsset
	for rows.Next() {
		a := &ModuleAsset{}
		if err := rows.Scan(&a.ID, &a.ModuleVersionID, &a.Title, &a.AssetType, &a.URL, &a.SizeBytes,
			&a.Order, &a.IsDownloadable, &a.CreatedBy, &a.CreatedAt, &a.UpdatedAt); err != nil {
			return nil, fmt.Errorf("module.ListAssetsByVersion scan: %w", err)
		}
		out = append(out, a)
	}
	return out, rows.Err()
}

// ─── BatchModuleConfig ────────────────────────────────────────────────────────

func (r *repository) UpsertBatchModuleConfig(ctx context.Context, c *BatchModuleConfig) error {
	query := `
		INSERT INTO catalog.batch_module_configs (id, course_batch_id, module_id, version_policy, locked_version_id, set_by)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (course_batch_id, module_id)
		DO UPDATE SET version_policy = EXCLUDED.version_policy,
		              locked_version_id = EXCLUDED.locked_version_id,
		              set_by = EXCLUDED.set_by
		RETURNING created_at, updated_at`
	err := r.pool.QueryRow(ctx, query,
		c.ID, c.CourseBatchID, c.ModuleID, c.VersionPolicy, c.LockedVersionID, c.SetBy,
	).Scan(&c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		return fmt.Errorf("module.UpsertBatchModuleConfig: %w", err)
	}
	return nil
}

func (r *repository) GetBatchModuleConfig(ctx context.Context, batchID, moduleID uuid.UUID) (*BatchModuleConfig, error) {
	query := `SELECT id, course_batch_id, module_id, version_policy, locked_version_id, set_by, created_at, updated_at
	          FROM catalog.batch_module_configs WHERE course_batch_id = $1 AND module_id = $2`
	c := &BatchModuleConfig{}
	err := r.pool.QueryRow(ctx, query, batchID, moduleID).Scan(
		&c.ID, &c.CourseBatchID, &c.ModuleID, &c.VersionPolicy, &c.LockedVersionID, &c.SetBy, &c.CreatedAt, &c.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("module.GetBatchModuleConfig: %w", err)
	}
	return c, nil
}

func (r *repository) ListBatchModuleConfigs(ctx context.Context, batchID uuid.UUID) ([]*BatchModuleConfig, error) {
	query := `SELECT id, course_batch_id, module_id, version_policy, locked_version_id, set_by, created_at, updated_at
	          FROM catalog.batch_module_configs WHERE course_batch_id = $1`
	rows, err := r.pool.Query(ctx, query, batchID)
	if err != nil {
		return nil, fmt.Errorf("module.ListBatchModuleConfigs: %w", err)
	}
	defer rows.Close()

	var out []*BatchModuleConfig
	for rows.Next() {
		c := &BatchModuleConfig{}
		if err := rows.Scan(&c.ID, &c.CourseBatchID, &c.ModuleID, &c.VersionPolicy, &c.LockedVersionID, &c.SetBy, &c.CreatedAt, &c.UpdatedAt); err != nil {
			return nil, fmt.Errorf("module.ListBatchModuleConfigs scan: %w", err)
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// ─── ClassModuleCoverage ──────────────────────────────────────────────────────

func (r *repository) CreateCoverage(ctx context.Context, c *ClassModuleCoverage) error {
	query := `
		INSERT INTO catalog.class_module_coverages (id, class_id, module_id, status, covered_by, covered_at, is_auto_covered, notes, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING created_at, updated_at`
	err := r.pool.QueryRow(ctx, query,
		c.ID, c.ClassID, c.ModuleID, c.Status, c.CoveredBy, c.CoveredAt,
		c.IsAutoCovered, c.Notes, c.CreatedBy,
	).Scan(&c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		return fmt.Errorf("module.CreateCoverage: %w", err)
	}
	return nil
}

func (r *repository) GetCoverageByID(ctx context.Context, id uuid.UUID) (*ClassModuleCoverage, error) {
	query := `SELECT id, class_id, module_id, status, covered_by, covered_at, is_auto_covered, notes, created_by, created_at, updated_at
	          FROM catalog.class_module_coverages WHERE id = $1`
	c := &ClassModuleCoverage{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&c.ID, &c.ClassID, &c.ModuleID, &c.Status, &c.CoveredBy, &c.CoveredAt,
		&c.IsAutoCovered, &c.Notes, &c.CreatedBy, &c.CreatedAt, &c.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("module.GetCoverageByID: %w", err)
	}
	return c, nil
}

func (r *repository) ListCoverageByClass(ctx context.Context, classID uuid.UUID) ([]*ClassModuleCoverage, error) {
	query := `SELECT id, class_id, module_id, status, covered_by, covered_at, is_auto_covered, notes, created_by, created_at, updated_at
	          FROM catalog.class_module_coverages WHERE class_id = $1 ORDER BY created_at`
	rows, err := r.pool.Query(ctx, query, classID)
	if err != nil {
		return nil, fmt.Errorf("module.ListCoverageByClass: %w", err)
	}
	defer rows.Close()

	var out []*ClassModuleCoverage
	for rows.Next() {
		c := &ClassModuleCoverage{}
		if err := rows.Scan(&c.ID, &c.ClassID, &c.ModuleID, &c.Status, &c.CoveredBy, &c.CoveredAt,
			&c.IsAutoCovered, &c.Notes, &c.CreatedBy, &c.CreatedAt, &c.UpdatedAt); err != nil {
			return nil, fmt.Errorf("module.ListCoverageByClass scan: %w", err)
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

func (r *repository) UpdateCoverage(ctx context.Context, c *ClassModuleCoverage) error {
	query := `UPDATE catalog.class_module_coverages
	          SET status=$1, covered_by=$2, covered_at=$3, notes=$4
	          WHERE id=$5
	          RETURNING updated_at`
	err := r.pool.QueryRow(ctx, query,
		c.Status, c.CoveredBy, c.CoveredAt, c.Notes, c.ID,
	).Scan(&c.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("module.UpdateCoverage: %w", err)
	}
	return nil
}

func (r *repository) DeleteCoverage(ctx context.Context, id uuid.UUID) error {
	result, err := r.pool.Exec(ctx, `DELETE FROM catalog.class_module_coverages WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("module.DeleteCoverage: %w", err)
	}
	if result.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) AutoFlipPlannedToCovered(ctx context.Context, classID uuid.UUID, coveredAt time.Time) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE catalog.class_module_coverages
		 SET status = 'covered', is_auto_covered = true, covered_at = $1, covered_by = NULL
		 WHERE class_id = $2 AND status = 'planned'`,
		coveredAt, classID)
	if err != nil {
		return fmt.Errorf("module.AutoFlipPlannedToCovered: %w", err)
	}
	return nil
}

// ─── Progress ─────────────────────────────────────────────────────────────────

func (r *repository) GetBatchProgress(ctx context.Context, batchID uuid.UUID) (*BatchProgress, error) {
	query := `
		SELECT
		  cb.id,
		  COUNT(DISTINCT m.id) FILTER (WHERE m.is_active) AS total_modules,
		  COUNT(DISTINCT cmc.module_id) FILTER (WHERE cmc.status = 'covered') AS covered_modules
		FROM catalog.course_batches cb
		JOIN catalog.courses c ON c.id = cb.course_id
		LEFT JOIN catalog.modules m ON m.course_id = c.id
		LEFT JOIN catalog.class_module_coverages cmc ON cmc.module_id = m.id
		  AND cmc.class_id IN (
		    SELECT id FROM catalog.classes WHERE course_batch_id = cb.id
		  )
		WHERE cb.id = $1
		GROUP BY cb.id`
	p := &BatchProgress{}
	err := r.pool.QueryRow(ctx, query, batchID).Scan(&p.BatchID, &p.TotalModules, &p.CoveredModules)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("module.GetBatchProgress: %w", err)
	}
	if p.TotalModules > 0 {
		p.ProgressPct = float64(p.CoveredModules) / float64(p.TotalModules) * 100
	}
	return p, nil
}
```

- [ ] **Step 2: Verify compiles**

```bash
cd backend && go build ./domains/module/...
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add backend/domains/module/repository.go
git commit -m "feat(module): add repository interface and pgx implementation"
```

---

## Task 4: Service

**Files:**
- Create: `backend/domains/module/service.go`

- [ ] **Step 1: Write failing integration test stubs** (create the test file first)

```go
//go:build integration

package module_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/module"
)

const defaultTestDBURL = "postgres://vernonedu:vernonedu_secret@localhost:5433/vernonedu?sslmode=disable"

func newTestPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DB_URL")
	if url == "" {
		url = defaultTestDBURL
	}
	pool, err := pgxpool.New(context.Background(), url)
	require.NoError(t, err)
	require.NoError(t, pool.Ping(context.Background()))
	return pool
}

func resetSchemas(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	_, err := pool.Exec(context.Background(), `
		TRUNCATE
			catalog.class_module_coverages,
			catalog.batch_module_configs,
			catalog.module_assets,
			catalog.module_versions,
			catalog.modules,
			catalog.classes,
			catalog.course_batches,
			catalog.courses,
			enrollment.enrollments,
			identity.departments,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

func newService(t *testing.T, pool *pgxpool.Pool) *module.Service {
	t.Helper()
	repo := module.NewRepository(pool)
	return module.NewService(repo, zap.NewNop())
}

type seedResult struct {
	actorID  uuid.UUID
	courseID uuid.UUID
	batchID  uuid.UUID
	classID  uuid.UUID
}

func seedCatalog(t *testing.T, pool *pgxpool.Pool) seedResult {
	t.Helper()
	ctx := context.Background()

	actorID := uuid.New()
	_, err := pool.Exec(ctx,
		`INSERT INTO identity.users (id, email, password_hash, role) VALUES ($1, $2, 'x', 'vernonedu_admin')`,
		actorID, actorID.String()+"@test.local")
	require.NoError(t, err)

	deptID := uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO identity.departments (id, name, leader_id, created_by) VALUES ($1, 'Dept', $2, $2)`,
		deptID, actorID)
	require.NoError(t, err)

	courseID := uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO catalog.courses (id, name, department_id, course_creator_id, base_price, min_price, created_by)
		 VALUES ($1, 'Course', $2, $3, 0, 0, $3)`,
		courseID, deptID, actorID)
	require.NoError(t, err)

	batchID := uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO catalog.course_batches (id, course_id, label, start_date, end_date, price, status, created_by)
		 VALUES ($1, $2, 'Batch 1', now(), now()+interval '30 days', 0, 'open', $3)`,
		batchID, courseID, actorID)
	require.NoError(t, err)

	classID := uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO catalog.classes (id, course_batch_id, session_date, start_time, end_time, mode, instructor_id, instructor_type, assigned_by, created_at, updated_at)
		 VALUES ($1, $2, now(), '09:00', '11:00', 'online', $3, 'internal', 'admin', now(), now())`,
		classID, batchID, actorID)
	require.NoError(t, err)

	return seedResult{actorID: actorID, courseID: courseID, batchID: batchID, classID: classID}
}

func TestCreateModule(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)

	m, err := svc.CreateModule(context.Background(), seed.courseID, "Intro", 1, seed.actorID)
	require.NoError(t, err)
	require.Equal(t, "Intro", m.Title)
	require.True(t, m.IsActive)
	require.Equal(t, 1, m.Order)
}

func TestPublishVersion_ArchivesPrevious(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)

	m, err := svc.CreateModule(context.Background(), seed.courseID, "Module A", 1, seed.actorID)
	require.NoError(t, err)

	v1, err := svc.CreateModuleVersion(context.Background(), m.ID, "Version 1", nil, seed.actorID)
	require.NoError(t, err)
	err = svc.PublishVersion(context.Background(), m.ID, v1.ID, seed.actorID)
	require.NoError(t, err)

	v2, err := svc.CreateModuleVersion(context.Background(), m.ID, "Version 2", nil, seed.actorID)
	require.NoError(t, err)
	err = svc.PublishVersion(context.Background(), m.ID, v2.ID, seed.actorID)
	require.NoError(t, err)

	v1Fetched, err := svc.GetModuleVersion(context.Background(), v1.ID)
	require.NoError(t, err)
	require.Equal(t, module.ModuleArchived, v1Fetched.Status)

	v2Fetched, err := svc.GetModuleVersion(context.Background(), v2.ID)
	require.NoError(t, err)
	require.Equal(t, module.ModulePublished, v2Fetched.Status)
}

func TestCoverage_AutoFlip(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)

	m, _ := svc.CreateModule(context.Background(), seed.courseID, "Module A", 1, seed.actorID)
	cov, err := svc.CreateCoverage(context.Background(), seed.classID, m.ID, nil, seed.actorID)
	require.NoError(t, err)
	require.Equal(t, module.CoveragePlanned, cov.Status)

	err = svc.AutoFlipPlannedToCovered(context.Background(), seed.classID)
	require.NoError(t, err)

	updated, err := svc.GetCoverage(context.Background(), cov.ID)
	require.NoError(t, err)
	require.Equal(t, module.CoverageCovered, updated.Status)
	require.True(t, updated.IsAutoCovered)
	require.NotNil(t, updated.CoveredAt)
}

func TestBatchProgress(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)

	m1, _ := svc.CreateModule(context.Background(), seed.courseID, "Mod 1", 1, seed.actorID)
	m2, _ := svc.CreateModule(context.Background(), seed.courseID, "Mod 2", 2, seed.actorID)

	svc.CreateCoverage(context.Background(), seed.classID, m1.ID, nil, seed.actorID)
	svc.CreateCoverage(context.Background(), seed.classID, m2.ID, nil, seed.actorID)
	svc.AutoFlipPlannedToCovered(context.Background(), seed.classID)

	progress, err := svc.GetBatchProgress(context.Background(), seed.batchID)
	require.NoError(t, err)
	require.Equal(t, 2, progress.TotalModules)
	require.Equal(t, 2, progress.CoveredModules)
	require.InDelta(t, 100.0, progress.ProgressPct, 0.01)
}
```

- [ ] **Step 2: Run tests — verify they fail with "module.Service undefined"**

```bash
cd backend && go test -tags=integration ./domains/module/... -run TestCreateModule -v 2>&1 | head -20
```

Expected: compile error — `module.Service` undefined.

- [ ] **Step 3: Write service.go**

```go
package module

import (
	"context"
	"time"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// Service handles module domain business logic.
type Service struct {
	repo Repository
	log  *zap.Logger
}

// NewService constructs module Service (FX-injectable).
func NewService(repo Repository, log *zap.Logger) *Service {
	return &Service{repo: repo, log: log}
}

// ─── CourseModule ─────────────────────────────────────────────────────────────

func (s *Service) CreateModule(ctx context.Context, courseID uuid.UUID, title string, order int, actorID uuid.UUID) (*CourseModule, error) {
	m := &CourseModule{
		ID:        uuid.New(),
		CourseID:  courseID,
		Title:     title,
		Order:     order,
		IsActive:  true,
		CreatedBy: actorID,
	}
	if err := s.repo.CreateModule(ctx, m); err != nil {
		return nil, err
	}
	return m, nil
}

func (s *Service) UpdateModule(ctx context.Context, moduleID uuid.UUID, title string, order int, isActive bool) (*CourseModule, error) {
	m, err := s.repo.GetModuleByID(ctx, moduleID)
	if err != nil {
		return nil, err
	}
	m.Title = title
	m.Order = order
	m.IsActive = isActive
	if err := s.repo.UpdateModule(ctx, m); err != nil {
		return nil, err
	}
	return m, nil
}

func (s *Service) GetModule(ctx context.Context, id uuid.UUID) (*CourseModule, error) {
	return s.repo.GetModuleByID(ctx, id)
}

func (s *Service) ListModules(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error) {
	return s.repo.ListModulesByCourse(ctx, courseID)
}

// GetCourseCreatorID returns the course_creator_id for ownership checks.
func (s *Service) GetCourseCreatorID(ctx context.Context, courseID uuid.UUID) (uuid.UUID, error) {
	return s.repo.GetCourseCreatorID(ctx, courseID)
}

func (s *Service) GetBatchCourseID(ctx context.Context, batchID uuid.UUID) (uuid.UUID, error) {
	return s.repo.GetBatchCourseID(ctx, batchID)
}

func (s *Service) GetClassBatchID(ctx context.Context, classID uuid.UUID) (uuid.UUID, error) {
	return s.repo.GetClassBatchID(ctx, classID)
}

func (s *Service) GetClassInstructorID(ctx context.Context, classID uuid.UUID) (uuid.UUID, error) {
	return s.repo.GetClassInstructorID(ctx, classID)
}

// ─── ModuleVersion ────────────────────────────────────────────────────────────

func (s *Service) CreateModuleVersion(ctx context.Context, moduleID uuid.UUID, title string, description *string, actorID uuid.UUID) (*ModuleVersion, error) {
	count, err := s.repo.CountVersionsByModule(ctx, moduleID)
	if err != nil {
		return nil, err
	}
	mv := &ModuleVersion{
		ID:            uuid.New(),
		ModuleID:      moduleID,
		VersionNumber: count + 1,
		Title:         title,
		Description:   description,
		Status:        ModuleDraft,
		CreatedBy:     actorID,
	}
	if err := s.repo.CreateModuleVersion(ctx, mv); err != nil {
		return nil, err
	}
	return mv, nil
}

func (s *Service) GetModuleVersion(ctx context.Context, id uuid.UUID) (*ModuleVersion, error) {
	return s.repo.GetModuleVersionByID(ctx, id)
}

func (s *Service) PublishVersion(ctx context.Context, moduleID, versionID uuid.UUID, actorID uuid.UUID) error {
	mv, err := s.repo.GetModuleVersionByID(ctx, versionID)
	if err != nil {
		return err
	}
	if mv.ModuleID != moduleID {
		return apperrors.ErrNotFound
	}
	if mv.Status != ModuleDraft {
		return apperrors.Validationf("only draft versions can be published")
	}
	if err := s.repo.ArchivePreviousPublished(ctx, moduleID); err != nil {
		return err
	}
	return s.repo.PublishVersion(ctx, versionID, actorID, time.Now())
}

// ─── ModuleAsset ──────────────────────────────────────────────────────────────

func (s *Service) CreateAsset(ctx context.Context, versionID uuid.UUID, title string, assetType AssetType, url string, sizeBytes *int64, order int, isDownloadable bool, actorID uuid.UUID) (*ModuleAsset, error) {
	a := &ModuleAsset{
		ID:              uuid.New(),
		ModuleVersionID: versionID,
		Title:           title,
		AssetType:       assetType,
		URL:             url,
		SizeBytes:       sizeBytes,
		Order:           order,
		IsDownloadable:  isDownloadable,
		CreatedBy:       actorID,
	}
	if err := s.repo.CreateAsset(ctx, a); err != nil {
		return nil, err
	}
	return a, nil
}

func (s *Service) UpdateAsset(ctx context.Context, assetID uuid.UUID, title string, assetType AssetType, url string, sizeBytes *int64, order int, isDownloadable bool) (*ModuleAsset, error) {
	a, err := s.repo.GetAssetByID(ctx, assetID)
	if err != nil {
		return nil, err
	}
	a.Title = title
	a.AssetType = assetType
	a.URL = url
	a.SizeBytes = sizeBytes
	a.Order = order
	a.IsDownloadable = isDownloadable
	if err := s.repo.UpdateAsset(ctx, a); err != nil {
		return nil, err
	}
	return a, nil
}

func (s *Service) DeleteAsset(ctx context.Context, assetID uuid.UUID) error {
	return s.repo.DeleteAsset(ctx, assetID)
}

func (s *Service) ListAssets(ctx context.Context, versionID uuid.UUID) ([]*ModuleAsset, error) {
	return s.repo.ListAssetsByVersion(ctx, versionID)
}

// ─── BatchModuleConfig ────────────────────────────────────────────────────────

func (s *Service) UpsertBatchModuleConfig(ctx context.Context, batchID, moduleID uuid.UUID, policy VersionPolicy, lockedVersionID *uuid.UUID, actorID uuid.UUID) (*BatchModuleConfig, error) {
	if policy == PolicyLocked && lockedVersionID == nil {
		return nil, apperrors.Validationf("locked_version_id required when policy is locked")
	}
	if policy == PolicyLocked && lockedVersionID != nil {
		lv, err := s.repo.GetModuleVersionByID(ctx, *lockedVersionID)
		if err != nil {
			return nil, err
		}
		if lv.ModuleID != moduleID || lv.Status != ModulePublished {
			return nil, apperrors.Validationf("locked_version_id must reference a published version of the same module")
		}
	}
	c := &BatchModuleConfig{
		ID:              uuid.New(),
		CourseBatchID:   batchID,
		ModuleID:        moduleID,
		VersionPolicy:   policy,
		LockedVersionID: lockedVersionID,
		SetBy:           actorID,
	}
	if err := s.repo.UpsertBatchModuleConfig(ctx, c); err != nil {
		return nil, err
	}
	return c, nil
}

func (s *Service) ListBatchModuleConfigs(ctx context.Context, batchID uuid.UUID) ([]*BatchModuleConfig, error) {
	return s.repo.ListBatchModuleConfigs(ctx, batchID)
}

// ─── ClassModuleCoverage ──────────────────────────────────────────────────────

func (s *Service) CreateCoverage(ctx context.Context, classID, moduleID uuid.UUID, notes *string, actorID uuid.UUID) (*ClassModuleCoverage, error) {
	c := &ClassModuleCoverage{
		ID:        uuid.New(),
		ClassID:   classID,
		ModuleID:  moduleID,
		Status:    CoveragePlanned,
		Notes:     notes,
		CreatedBy: actorID,
	}
	if err := s.repo.CreateCoverage(ctx, c); err != nil {
		return nil, err
	}
	return c, nil
}

func (s *Service) GetCoverage(ctx context.Context, id uuid.UUID) (*ClassModuleCoverage, error) {
	return s.repo.GetCoverageByID(ctx, id)
}

func (s *Service) ListCoverage(ctx context.Context, classID uuid.UUID) ([]*ClassModuleCoverage, error) {
	return s.repo.ListCoverageByClass(ctx, classID)
}

func (s *Service) MarkCovered(ctx context.Context, coverageID, actorID uuid.UUID, notes *string) (*ClassModuleCoverage, error) {
	c, err := s.repo.GetCoverageByID(ctx, coverageID)
	if err != nil {
		return nil, err
	}
	now := time.Now()
	c.Status = CoverageCovered
	c.CoveredBy = &actorID
	c.CoveredAt = &now
	c.Notes = notes
	if err := s.repo.UpdateCoverage(ctx, c); err != nil {
		return nil, err
	}
	return c, nil
}

func (s *Service) DeleteCoverage(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeleteCoverage(ctx, id)
}

func (s *Service) AutoFlipPlannedToCovered(ctx context.Context, classID uuid.UUID) error {
	return s.repo.AutoFlipPlannedToCovered(ctx, classID, time.Now())
}

// ─── Progress ─────────────────────────────────────────────────────────────────

func (s *Service) GetBatchProgress(ctx context.Context, batchID uuid.UUID) (*BatchProgress, error) {
	return s.repo.GetBatchProgress(ctx, batchID)
}

// ─── Student Access ───────────────────────────────────────────────────────────

// ResolveStudentModules returns student-visible modules for an enrollment.
// Checks enrollment.confirmed status via DB. Applies version resolution per BatchModuleConfig.
func (s *Service) ResolveStudentModules(ctx context.Context, enrollmentID, studentID uuid.UUID) ([]*StudentModuleView, error) {
	batchID, err := s.repo.GetEnrollmentBatchID(ctx, enrollmentID)
	if err != nil {
		return nil, err
	}
	enrolled, err := s.repo.IsStudentEnrolled(ctx, studentID, batchID)
	if err != nil {
		return nil, err
	}
	if !enrolled {
		return nil, apperrors.ErrForbidden
	}

	batchCourseID, err := s.repo.GetBatchCourseID(ctx, batchID)
	if err != nil {
		return nil, err
	}
	modules, err := s.repo.ListActiveModulesWithPublishedVersion(ctx, batchCourseID)
	if err != nil {
		return nil, err
	}

	configs, err := s.repo.ListBatchModuleConfigs(ctx, batchID)
	if err != nil {
		return nil, err
	}
	configMap := make(map[uuid.UUID]*BatchModuleConfig, len(configs))
	for _, cfg := range configs {
		configMap[cfg.ModuleID] = cfg
	}

	var out []*StudentModuleView
	for _, m := range modules {
		version, err := s.resolveVersion(ctx, m.ID, batchID, configMap)
		if err != nil {
			s.log.Warn("module: skipping module, no published version", zap.String("module_id", m.ID.String()))
			continue
		}
		assets, _ := s.repo.ListAssetsByVersion(ctx, version.ID)
		out = append(out, &StudentModuleView{
			ModuleID:      m.ID,
			Title:         m.Title,
			Order:         m.Order,
			VersionID:     version.ID,
			VersionTitle:  version.Title,
			VersionNumber: version.VersionNumber,
			Assets:        assets,
		})
	}
	return out, nil
}

// ResolveStudentModule returns student-visible detail for a single module.
func (s *Service) ResolveStudentModule(ctx context.Context, enrollmentID, moduleID, studentID uuid.UUID) (*StudentModuleView, error) {
	batchID, err := s.repo.GetEnrollmentBatchID(ctx, enrollmentID)
	if err != nil {
		return nil, err
	}
	enrolled, err := s.repo.IsStudentEnrolled(ctx, studentID, batchID)
	if err != nil {
		return nil, err
	}
	if !enrolled {
		return nil, apperrors.ErrForbidden
	}

	m, err := s.repo.GetModuleByID(ctx, moduleID)
	if err != nil {
		return nil, err
	}
	if !m.IsActive {
		return nil, apperrors.ErrNotFound
	}

	configs, _ := s.repo.ListBatchModuleConfigs(ctx, batchID)
	configMap := make(map[uuid.UUID]*BatchModuleConfig, len(configs))
	for _, cfg := range configs {
		configMap[cfg.ModuleID] = cfg
	}

	version, err := s.resolveVersion(ctx, moduleID, batchID, configMap)
	if err != nil {
		return nil, err
	}
	assets, _ := s.repo.ListAssetsByVersion(ctx, version.ID)
	return &StudentModuleView{
		ModuleID:      m.ID,
		Title:         m.Title,
		Order:         m.Order,
		VersionID:     version.ID,
		VersionTitle:  version.Title,
		VersionNumber: version.VersionNumber,
		Assets:        assets,
	}, nil
}

func (s *Service) resolveVersion(ctx context.Context, moduleID, batchID uuid.UUID, configMap map[uuid.UUID]*BatchModuleConfig) (*ModuleVersion, error) {
	if cfg, ok := configMap[moduleID]; ok && cfg.VersionPolicy == PolicyLocked && cfg.LockedVersionID != nil {
		return s.repo.GetModuleVersionByID(ctx, *cfg.LockedVersionID)
	}
	return s.repo.GetLatestPublishedVersion(ctx, moduleID)
}
```

- [ ] **Step 4: Add missing Validationf to errors package**

Check if `apperrors.Validationf` exists:

```bash
grep -r "Validationf" /Users/erickmo/Desktop/Project/vernonedu2/backend/internal/errors/
```

If it does not exist, add it to `backend/internal/errors/errors.go`:

```go
import "fmt"

// Validationf creates a validation AppError with a formatted message.
func Validationf(format string, args ...any) *AppError {
	return &AppError{
		Code:       "VALIDATION_ERROR",
		Message:    fmt.Sprintf(format, args...),
		HTTPStatus: http.StatusUnprocessableEntity,
	}
}
```

- [ ] **Step 5: Run integration tests**

```bash
cd backend && go test -tags=integration ./domains/module/... -v -run "TestCreateModule|TestPublishVersion|TestCoverage|TestBatchProgress"
```

Expected: all 4 tests PASS.

- [ ] **Step 6: Verify build**

```bash
cd backend && go build ./domains/module/...
```

- [ ] **Step 7: Commit**

```bash
git add backend/domains/module/service.go backend/domains/module/service_integration_test.go
git commit -m "feat(module): add service with coverage, progress, and student access"
```

---

## Task 5: Events

**Files:**
- Create: `backend/domains/module/events.go`

- [ ] **Step 1: Check if `ClassCompleted` event constant exists**

```bash
grep -r "ClassCompleted\|class_completed" /Users/erickmo/Desktop/Project/vernonedu2/backend/internal/events/
```

If missing, add to `backend/internal/events/events.go`:

```go
ClassCompleted EventType = "attendance.class_completed"
```

- [ ] **Step 2: Write events.go**

```go
package module

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// classCompletedPayload is the expected shape of attendance.class_completed.
type classCompletedPayload struct {
	ClassID uuid.UUID `json:"class_id"`
}

// RegisterSubscriptions wires module domain into the event bus.
func RegisterSubscriptions(bus events.Bus, svc *Service, log *zap.Logger) {
	bus.Subscribe(events.ClassCompleted, handleClassCompleted(svc, log))
}

func handleClassCompleted(svc *Service, log *zap.Logger) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		payload, err := decodeClassCompletedPayload(e.Payload)
		if err != nil {
			log.Error("module: failed to decode ClassCompleted payload", zap.Error(err))
			return err
		}
		if err := svc.AutoFlipPlannedToCovered(ctx, payload.ClassID); err != nil {
			log.Error("module: AutoFlipPlannedToCovered failed",
				zap.String("class_id", payload.ClassID.String()),
				zap.Error(err))
			return err
		}
		return nil
	}
}

func decodeClassCompletedPayload(raw any) (*classCompletedPayload, error) {
	b, err := json.Marshal(raw)
	if err != nil {
		return nil, err
	}
	var p classCompletedPayload
	if err := json.Unmarshal(b, &p); err != nil {
		return nil, err
	}
	return &p, nil
}
```

- [ ] **Step 3: Verify compiles**

```bash
cd backend && go build ./domains/module/... ./internal/events/...
```

- [ ] **Step 4: Commit**

```bash
git add backend/domains/module/events.go backend/internal/events/events.go
git commit -m "feat(module): add event subscriptions for class_completed auto-coverage"
```

---

## Task 6: Handler

**Files:**
- Create: `backend/domains/module/handler.go`

- [ ] **Step 1: Write handler.go**

```go
package module

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/zap"
)

// Handler exposes HTTP endpoints for the module domain.
type Handler struct {
	svc *Service
	log *zap.Logger
}

// NewHandler constructs module Handler (FX-injectable).
func NewHandler(svc *Service, log *zap.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// ─── Module Management ────────────────────────────────────────────────────────

func (h *Handler) CreateModule(w http.ResponseWriter, r *http.Request) {
	courseID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}
	var req struct {
		Title string `json:"title"`
		Order int    `json:"order"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if err := h.assertCourseOwner(r, courseID, uc); err != nil {
		apperrors.Render(w, err)
		return
	}
	m, err := h.svc.CreateModule(r.Context(), courseID, req.Title, req.Order, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, m)
}

func (h *Handler) UpdateModule(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "module_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module_id"))
		return
	}
	var req struct {
		Title    string `json:"title"`
		Order    int    `json:"order"`
		IsActive bool   `json:"is_active"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	uc := mw.GetUserContext(r.Context())
	if err := h.assertCourseOwner(r, m.CourseID, uc); err != nil {
		apperrors.Render(w, err)
		return
	}
	updated, err := h.svc.UpdateModule(r.Context(), moduleID, req.Title, req.Order, req.IsActive)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, updated)
}

func (h *Handler) CreateVersion(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	var req struct {
		Title       string  `json:"title"`
		Description *string `json:"description"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	uc := mw.GetUserContext(r.Context())
	if err := h.assertCourseOwner(r, m.CourseID, uc); err != nil {
		apperrors.Render(w, err)
		return
	}
	mv, err := h.svc.CreateModuleVersion(r.Context(), moduleID, req.Title, req.Description, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, mv)
}

func (h *Handler) PublishVersion(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	verID, err := parseUUID(chi.URLParam(r, "ver_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid version id"))
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	uc := mw.GetUserContext(r.Context())
	if err := h.assertCourseOwner(r, m.CourseID, uc); err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.PublishVersion(r.Context(), moduleID, verID, uc.ID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CreateAsset(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	verID, err := parseUUID(chi.URLParam(r, "ver_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid version id"))
		return
	}
	var req struct {
		Title          string    `json:"title"`
		AssetType      AssetType `json:"asset_type"`
		URL            string    `json:"url"`
		SizeBytes      *int64    `json:"size_bytes"`
		Order          int       `json:"order"`
		IsDownloadable bool      `json:"is_downloadable"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	uc := mw.GetUserContext(r.Context())
	if err := h.assertCourseOwner(r, m.CourseID, uc); err != nil {
		apperrors.Render(w, err)
		return
	}
	a, err := h.svc.CreateAsset(r.Context(), verID, req.Title, req.AssetType, req.URL, req.SizeBytes, req.Order, req.IsDownloadable, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, a)
}

func (h *Handler) UpdateAsset(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	assetID, err := parseUUID(chi.URLParam(r, "asset_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid asset_id"))
		return
	}
	var req struct {
		Title          string    `json:"title"`
		AssetType      AssetType `json:"asset_type"`
		URL            string    `json:"url"`
		SizeBytes      *int64    `json:"size_bytes"`
		Order          int       `json:"order"`
		IsDownloadable bool      `json:"is_downloadable"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	uc := mw.GetUserContext(r.Context())
	if err := h.assertCourseOwner(r, m.CourseID, uc); err != nil {
		apperrors.Render(w, err)
		return
	}
	a, err := h.svc.UpdateAsset(r.Context(), assetID, req.Title, req.AssetType, req.URL, req.SizeBytes, req.Order, req.IsDownloadable)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, a)
}

func (h *Handler) DeleteAsset(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	assetID, err := parseUUID(chi.URLParam(r, "asset_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid asset_id"))
		return
	}
	m, err := h.svc.GetModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	uc := mw.GetUserContext(r.Context())
	if err := h.assertCourseOwner(r, m.CourseID, uc); err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.DeleteAsset(r.Context(), assetID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ─── Batch Config ─────────────────────────────────────────────────────────────

func (h *Handler) ListBatchModuleConfigs(w http.ResponseWriter, r *http.Request) {
	batchID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	configs, err := h.svc.ListBatchModuleConfigs(r.Context(), batchID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, configs)
}

func (h *Handler) UpsertBatchModuleConfig(w http.ResponseWriter, r *http.Request) {
	batchID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	moduleID, err := parseUUID(chi.URLParam(r, "module_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module_id"))
		return
	}
	var req struct {
		VersionPolicy   VersionPolicy `json:"version_policy"`
		LockedVersionID *uuid.UUID    `json:"locked_version_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	cfg, err := h.svc.UpsertBatchModuleConfig(r.Context(), batchID, moduleID, req.VersionPolicy, req.LockedVersionID, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, cfg)
}

// ─── Class Progress ───────────────────────────────────────────────────────────

func (h *Handler) ListCoverage(w http.ResponseWriter, r *http.Request) {
	classID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid class id"))
		return
	}
	items, err := h.svc.ListCoverage(r.Context(), classID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *Handler) CreateCoverage(w http.ResponseWriter, r *http.Request) {
	classID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid class id"))
		return
	}
	var req struct {
		ModuleID uuid.UUID `json:"module_id"`
		Notes    *string   `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if err := h.assertClassAccess(r, classID, uc); err != nil {
		apperrors.Render(w, err)
		return
	}
	c, err := h.svc.CreateCoverage(r.Context(), classID, req.ModuleID, req.Notes, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, c)
}

func (h *Handler) UpdateCoverage(w http.ResponseWriter, r *http.Request) {
	classID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid class id"))
		return
	}
	covID, err := parseUUID(chi.URLParam(r, "cov_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid coverage id"))
		return
	}
	var req struct {
		Notes *string `json:"notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if err := h.assertClassAccess(r, classID, uc); err != nil {
		apperrors.Render(w, err)
		return
	}
	c, err := h.svc.MarkCovered(r.Context(), covID, uc.ID, req.Notes)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, c)
}

func (h *Handler) DeleteCoverage(w http.ResponseWriter, r *http.Request) {
	classID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid class id"))
		return
	}
	covID, err := parseUUID(chi.URLParam(r, "cov_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid coverage id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if err := h.assertClassAccess(r, classID, uc); err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.DeleteCoverage(r.Context(), covID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetBatchProgress(w http.ResponseWriter, r *http.Request) {
	batchID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	p, err := h.svc.GetBatchProgress(r.Context(), batchID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

// ─── Student Access ───────────────────────────────────────────────────────────

func (h *Handler) GetStudentModules(w http.ResponseWriter, r *http.Request) {
	enrollmentID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid enrollment id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	modules, err := h.svc.ResolveStudentModules(r.Context(), enrollmentID, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, modules)
}

func (h *Handler) GetStudentModule(w http.ResponseWriter, r *http.Request) {
	enrollmentID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid enrollment id"))
		return
	}
	moduleID, err := parseUUID(chi.URLParam(r, "module_id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module_id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	m, err := h.svc.ResolveStudentModule(r.Context(), enrollmentID, moduleID, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, m)
}

// ─── RBAC helpers ─────────────────────────────────────────────────────────────

const (
	roleAdmin         = "vernonedu_admin"
	roleCourseCreator = "course_creator"
	roleDeptLeader    = "dept_leader"
	roleFacilitator   = "facilitator"
)

// assertCourseOwner allows admin or course_creator who owns the course.
func (h *Handler) assertCourseOwner(r *http.Request, courseID uuid.UUID, uc *mw.UserContext) error {
	if uc.Role == roleAdmin {
		return nil
	}
	if uc.Role == roleCourseCreator {
		creatorID, err := h.svc.GetCourseCreatorID(r.Context(), courseID)
		if err != nil {
			return err
		}
		if creatorID == uc.ID {
			return nil
		}
	}
	return apperrors.ErrForbidden
}

// assertClassAccess allows admin, course_creator (own), or assigned facilitator.
func (h *Handler) assertClassAccess(r *http.Request, classID uuid.UUID, uc *mw.UserContext) error {
	if uc.Role == roleAdmin {
		return nil
	}
	if uc.Role == roleCourseCreator {
		batchID, err := h.svc.GetClassBatchID(r.Context(), classID)
		if err != nil {
			return err
		}
		courseID, err := h.svc.GetBatchCourseID(r.Context(), batchID)
		if err != nil {
			return err
		}
		creatorID, err := h.svc.GetCourseCreatorID(r.Context(), courseID)
		if err != nil {
			return err
		}
		if creatorID == uc.ID {
			return nil
		}
	}
	if uc.Role == roleFacilitator {
		instructorID, err := h.svc.GetClassInstructorID(r.Context(), classID)
		if err != nil {
			return err
		}
		if instructorID == uc.ID {
			return nil
		}
	}
	return apperrors.ErrForbidden
}

// ─── Util ─────────────────────────────────────────────────────────────────────

func parseUUID(s string) (uuid.UUID, error) {
	return uuid.Parse(s)
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
```

- [ ] **Step 2: Verify compiles**

```bash
cd backend && go build ./domains/module/...
```

- [ ] **Step 3: Commit**

```bash
git add backend/domains/module/handler.go
git commit -m "feat(module): add HTTP handlers with ownership RBAC"
```

---

## Task 7: FX Module Registration

**Files:**
- Create: `backend/domains/module/module.go`

- [ ] **Step 1: Write module.go**

```go
package module

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

// Module wires the module domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts module HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	manageModule    := mw.RequireRole(roleAdmin, roleCourseCreator)
	manageBatchCfg  := mw.RequireRole(roleAdmin, roleDeptLeader, roleCourseCreator)
	manageCoverage  := mw.RequireRole(roleAdmin, roleCourseCreator, roleFacilitator)
	viewCoverage    := mw.RequireRole(roleAdmin, roleDeptLeader, roleCourseCreator, roleFacilitator)
	viewProgress    := mw.RequireRole(roleAdmin, roleDeptLeader, roleCourseCreator)
	studentAccess   := mw.RequireRole("student")

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		// Module management
		r.With(manageModule).Post("/api/v1/courses/{id}/modules", h.CreateModule)
		r.With(manageModule).Patch("/api/v1/courses/{id}/modules/{module_id}", h.UpdateModule)

		// Version management
		r.With(manageModule).Post("/api/v1/modules/{id}/versions", h.CreateVersion)
		r.With(manageModule).Post("/api/v1/modules/{id}/versions/{ver_id}/publish", h.PublishVersion)

		// Asset management
		r.With(manageModule).Post("/api/v1/modules/{id}/versions/{ver_id}/assets", h.CreateAsset)
		r.With(manageModule).Patch("/api/v1/modules/{id}/versions/{ver_id}/assets/{asset_id}", h.UpdateAsset)
		r.With(manageModule).Delete("/api/v1/modules/{id}/versions/{ver_id}/assets/{asset_id}", h.DeleteAsset)

		// Batch config
		r.With(manageBatchCfg).Get("/api/v1/batches/{id}/module-configs", h.ListBatchModuleConfigs)
		r.With(manageBatchCfg).Put("/api/v1/batches/{id}/module-configs/{module_id}", h.UpsertBatchModuleConfig)

		// Class coverage
		r.With(viewCoverage).Get("/api/v1/classes/{id}/coverage", h.ListCoverage)
		r.With(manageCoverage).Post("/api/v1/classes/{id}/coverage", h.CreateCoverage)
		r.With(manageCoverage).Patch("/api/v1/classes/{id}/coverage/{cov_id}", h.UpdateCoverage)
		r.With(manageCoverage).Delete("/api/v1/classes/{id}/coverage/{cov_id}", h.DeleteCoverage)
		r.With(viewProgress).Get("/api/v1/batches/{id}/progress", h.GetBatchProgress)

		// Student access
		r.With(studentAccess).Get("/api/v1/enrollments/{id}/modules", h.GetStudentModules)
		r.With(studentAccess).Get("/api/v1/enrollments/{id}/modules/{module_id}", h.GetStudentModule)
	})
}
```

- [ ] **Step 2: Verify compiles**

```bash
cd backend && go build ./domains/module/...
```

- [ ] **Step 3: Commit**

```bash
git add backend/domains/module/module.go
git commit -m "feat(module): add FX module wiring and route registration"
```

---

## Task 8: Wire into main.go

**Files:**
- Modify: `backend/cmd/api/main.go`

- [ ] **Step 1: Add module import and registration**

In `backend/cmd/api/main.go`, add the import:

```go
"github.com/vernonedu/vernonedu2/backend/domains/module"
```

And add `module.Module,` to the `fx.New(...)` call after `budget.Module,`:

```go
		budget.Module,
		module.Module,
```

- [ ] **Step 2: Build the server**

```bash
cd backend && go build ./cmd/api/...
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add backend/cmd/api/main.go
git commit -m "feat(module): register module domain in API server"
```

---

## Task 9: Remove Module Entities from Catalog

**Files:**
- Modify: `backend/domains/catalog/model.go`
- Modify: `backend/domains/catalog/repository.go`
- Modify: `backend/domains/catalog/service.go`

- [ ] **Step 1: Remove from catalog/model.go**

Delete these type and constant blocks from `backend/domains/catalog/model.go`:
- `ModuleStatus` type + constants (`ModuleDraft`, `ModulePublished`, `ModuleArchived`)
- `AssetType` type + constants (`AssetVideo`, `AssetPDF`, `AssetDocument`, `AssetLink`, `AssetImage`, `AssetOther`)
- `CourseModule` struct
- `ModuleVersion` struct
- `ModuleAsset` struct
- `BatchModuleConfig` struct

- [ ] **Step 2: Remove from catalog/repository.go interface**

Remove from the `Repository` interface:
```
CreateModule(ctx context.Context, m *CourseModule) error
GetModuleByID(ctx context.Context, id uuid.UUID) (*CourseModule, error)
ListModulesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error)
CreateModuleVersion(ctx context.Context, mv *ModuleVersion) error
GetModuleVersionByID(ctx context.Context, id uuid.UUID) (*ModuleVersion, error)
```

Remove the corresponding implementations: `CreateModule`, `GetModuleByID`, `ListModulesByCourse`, `CreateModuleVersion`, `GetModuleVersionByID`.

- [ ] **Step 3: Remove from catalog/service.go**

Remove these service methods:
- `CreateModule`
- `ListModulesByCourse`
- `CreateModuleVersion`

- [ ] **Step 4: Build all domains to verify no references remain**

```bash
cd backend && go build ./...
```

Expected: no errors. If any import errors appear, fix the unused imports.

- [ ] **Step 5: Run all integration tests**

```bash
cd backend && go test -tags=integration ./... -v 2>&1 | tail -30
```

Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/domains/catalog/model.go backend/domains/catalog/repository.go backend/domains/catalog/service.go
git commit -m "refactor(catalog): remove module entities moved to module domain"
```

---

## Task 10: Handler-level RBAC Tests

**Files:**
- Create: `backend/domains/module/handler_test.go`

- [ ] **Step 1: Write handler_test.go**

```go
//go:build integration

package module_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/module"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildModuleRouter(svc *module.Service, role string) http.Handler {
	h := module.NewHandler(svc, zap.NewNop())
	r := chi.NewRouter()

	actorID := uuid.New()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	manageModule   := mw.RequireRole("vernonedu_admin", "course_creator")
	studentAccess  := mw.RequireRole("student")

	r.With(manageModule).Post("/api/v1/courses/{id}/modules", h.CreateModule)
	r.With(studentAccess).Get("/api/v1/enrollments/{id}/modules", h.GetStudentModules)

	return r
}

func TestCreateModule_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := module.NewService(module.NewRepository(pool), zap.NewNop())
	router := buildModuleRouter(svc, "student")

	body := `{"title":"Test","order":1}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/courses/"+uuid.New().String()+"/modules",
		bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	require.Equal(t, http.StatusForbidden, rec.Code)
}

func TestCreateModule_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)

	svc := module.NewService(module.NewRepository(pool), zap.NewNop())
	h := module.NewHandler(svc, zap.NewNop())
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: seed.actorID, Role: "vernonedu_admin"}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	r.Post("/api/v1/courses/{id}/modules", h.CreateModule)

	body, _ := json.Marshal(map[string]any{"title": "Intro", "order": 1})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/courses/"+seed.courseID.String()+"/modules",
		bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	require.Equal(t, http.StatusCreated, rec.Code)
}
```

- [ ] **Step 2: Run handler tests**

```bash
cd backend && go test -tags=integration ./domains/module/... -run "TestCreateModule" -v
```

Expected: both tests PASS.

- [ ] **Step 3: Commit**

```bash
git add backend/domains/module/handler_test.go
git commit -m "test(module): add HTTP-layer role enforcement tests"
```

---

## Final Verification

- [ ] **Full build**

```bash
cd backend && go build ./...
```

- [ ] **All integration tests**

```bash
cd backend && go test -tags=integration ./... 2>&1 | grep -E "PASS|FAIL|ok"
```

Expected: all `ok`, no `FAIL`.

- [ ] **Final commit if clean**

```bash
git add -A
git status
```

Verify nothing unexpected. Then push.

---

## Self-Review Notes

**Spec coverage verified:**
- ✅ CourseModule CRUD (Task 2, 3, 4, 6)
- ✅ ModuleVersion CRUD + publish with archive (Task 3, 4)
- ✅ ModuleAsset CRUD (Task 3, 4)
- ✅ BatchModuleConfig upsert + list (Task 3, 4)
- ✅ ClassModuleCoverage CRUD + manual mark-covered (Task 3, 4)
- ✅ Auto-flip on `attendance.class_completed` (Task 5)
- ✅ Batch progress (Task 3, 4)
- ✅ Student access with version resolution (Task 4)
- ✅ All 16 API endpoints (Task 6, 7)
- ✅ RBAC (own check for course_creator, facilitator assigned check) (Task 6)
- ✅ Migration for class_module_coverages (Task 1)
- ✅ Remove from catalog (Task 9)
- ✅ Wire into main.go (Task 8)

**Type consistency:** All types, method names, and constants are consistent across tasks. `Service` methods referenced in handler match exactly what's defined in service.go. Repository interface matches implementation.

**Known prerequisite:** `enrollment.enrollments` table must have a `status` column with value `'confirmed'`. If the column is named differently, update `IsStudentEnrolled` query in `repository.go`.
