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
	// Cross-schema helpers
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
	ListActiveModulesWithPublishedVersion(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error)

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
