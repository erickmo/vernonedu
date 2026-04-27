package catalog

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// pgUniqueViolation is the SQLSTATE code for unique constraint violations.
const pgUniqueViolation = "23505"

// Repository defines catalog data access.
type Repository interface {
	CreateCourse(ctx context.Context, c *Course) error
	GetCourseByID(ctx context.Context, id uuid.UUID) (*Course, error)
	UpdateCourse(ctx context.Context, c *Course) error
	ListCoursesByDepartment(ctx context.Context, deptID uuid.UUID) ([]*Course, error)

	CreateBatch(ctx context.Context, b *CourseBatch) error
	GetBatchByID(ctx context.Context, id uuid.UUID) (*CourseBatch, error)
	UpdateBatchStatus(ctx context.Context, id uuid.UUID, status BatchStatus) error
	ListBatchesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseBatch, error)

	CreateClass(ctx context.Context, cl *Class) error
	GetClassByID(ctx context.Context, id uuid.UUID) (*Class, error)
	ListClassesByBatch(ctx context.Context, batchID uuid.UUID) ([]*Class, error)

	CreateModule(ctx context.Context, m *CourseModule) error
	GetModuleByID(ctx context.Context, id uuid.UUID) (*CourseModule, error)
	ListModulesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error)

	CreateModuleVersion(ctx context.Context, mv *ModuleVersion) error
	GetModuleVersionByID(ctx context.Context, id uuid.UUID) (*ModuleVersion, error)

	AddFormatConfig(ctx context.Context, cfg *CourseFormatConfig) error
	DisableFormat(ctx context.Context, configID uuid.UUID) error
	ListFormatConfigsByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseFormatConfig, error)
	GetFormatConfig(ctx context.Context, id uuid.UUID) (*CourseFormatConfig, error)
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository creates a catalog repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

func (r *repository) CreateCourse(ctx context.Context, c *Course) error {
	query := `
		INSERT INTO catalog.courses (id, name, department_id, course_creator_id, base_price, min_price, description, is_active, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		c.ID, c.Name, c.DepartmentID, c.CourseCreatorID, c.BasePrice, c.MinPrice, c.Description, c.IsActive, c.CreatedBy,
	).Scan(&c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		return fmt.Errorf("catalog.CreateCourse: %w", err)
	}
	return nil
}

func (r *repository) GetCourseByID(ctx context.Context, id uuid.UUID) (*Course, error) {
	query := `SELECT id, name, department_id, course_creator_id, base_price, min_price, description, is_active, created_by, created_at, updated_at
	          FROM catalog.courses WHERE id = $1`

	c := &Course{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&c.ID, &c.Name, &c.DepartmentID, &c.CourseCreatorID,
		&c.BasePrice, &c.MinPrice, &c.Description, &c.IsActive, &c.CreatedBy, &c.CreatedAt, &c.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("catalog.GetCourseByID: %w", err)
	}
	return c, nil
}

func (r *repository) UpdateCourse(ctx context.Context, c *Course) error {
	query := `
		UPDATE catalog.courses
		SET name=$1, base_price=$2, min_price=$3, description=$4, is_active=$5
		WHERE id=$6
		RETURNING updated_at`

	err := r.pool.QueryRow(ctx, query,
		c.Name, c.BasePrice, c.MinPrice, c.Description, c.IsActive, c.ID,
	).Scan(&c.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("catalog.UpdateCourse: %w", err)
	}
	return nil
}

func (r *repository) ListCoursesByDepartment(ctx context.Context, deptID uuid.UUID) ([]*Course, error) {
	query := `SELECT id, name, department_id, course_creator_id, base_price, min_price, description, is_active, created_by, created_at, updated_at
	          FROM catalog.courses WHERE department_id = $1 ORDER BY name`

	rows, err := r.pool.Query(ctx, query, deptID)
	if err != nil {
		return nil, fmt.Errorf("catalog.ListCoursesByDepartment: %w", err)
	}
	defer rows.Close()

	var courses []*Course
	for rows.Next() {
		c := &Course{}
		if err := rows.Scan(&c.ID, &c.Name, &c.DepartmentID, &c.CourseCreatorID,
			&c.BasePrice, &c.MinPrice, &c.Description, &c.IsActive, &c.CreatedBy, &c.CreatedAt, &c.UpdatedAt); err != nil {
			return nil, fmt.Errorf("catalog.ListCoursesByDepartment scan: %w", err)
		}
		courses = append(courses, c)
	}
	return courses, rows.Err()
}

func (r *repository) CreateBatch(ctx context.Context, b *CourseBatch) error {
	query := `
		INSERT INTO catalog.course_batches (id, course_id, label, start_date, end_date, price, status, web_registration_open, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		b.ID, b.CourseID, b.Label, b.StartDate, b.EndDate, b.Price, b.Status, b.WebRegistrationOpen, b.CreatedBy,
	).Scan(&b.CreatedAt, &b.UpdatedAt)
	if err != nil {
		return fmt.Errorf("catalog.CreateBatch: %w", err)
	}
	return nil
}

func (r *repository) GetBatchByID(ctx context.Context, id uuid.UUID) (*CourseBatch, error) {
	query := `SELECT id, course_id, label, start_date, end_date, price, batch_bulk_price, status, web_registration_open,
	                 registration_open_at, registration_close_at, created_by, created_at, updated_at
	          FROM catalog.course_batches WHERE id = $1`

	b := &CourseBatch{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&b.ID, &b.CourseID, &b.Label, &b.StartDate, &b.EndDate, &b.Price, &b.BatchBulkPrice,
		&b.Status, &b.WebRegistrationOpen, &b.RegistrationOpenAt, &b.RegistrationCloseAt,
		&b.CreatedBy, &b.CreatedAt, &b.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("catalog.GetBatchByID: %w", err)
	}
	return b, nil
}

func (r *repository) UpdateBatchStatus(ctx context.Context, id uuid.UUID, status BatchStatus) error {
	query := `UPDATE catalog.course_batches SET status=$1 WHERE id=$2`
	ct, err := r.pool.Exec(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("catalog.UpdateBatchStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListBatchesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseBatch, error) {
	query := `SELECT id, course_id, label, start_date, end_date, price, batch_bulk_price, status,
	                 web_registration_open, registration_open_at, registration_close_at, created_by, created_at, updated_at
	          FROM catalog.course_batches WHERE course_id = $1 ORDER BY start_date DESC`

	rows, err := r.pool.Query(ctx, query, courseID)
	if err != nil {
		return nil, fmt.Errorf("catalog.ListBatchesByCourse: %w", err)
	}
	defer rows.Close()

	var batches []*CourseBatch
	for rows.Next() {
		b := &CourseBatch{}
		if err := rows.Scan(&b.ID, &b.CourseID, &b.Label, &b.StartDate, &b.EndDate, &b.Price, &b.BatchBulkPrice,
			&b.Status, &b.WebRegistrationOpen, &b.RegistrationOpenAt, &b.RegistrationCloseAt,
			&b.CreatedBy, &b.CreatedAt, &b.UpdatedAt); err != nil {
			return nil, fmt.Errorf("catalog.ListBatchesByCourse scan: %w", err)
		}
		batches = append(batches, b)
	}
	return batches, rows.Err()
}

func (r *repository) CreateClass(ctx context.Context, cl *Class) error {
	query := `
		INSERT INTO catalog.classes (id, course_batch_id, title, session_date, start_time, end_time, mode, location, online_link, instructor_id, instructor_type, assigned_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		cl.ID, cl.CourseBatchID, cl.Title, cl.SessionDate, cl.StartTime, cl.EndTime,
		cl.Mode, cl.Location, cl.OnlineLink, cl.InstructorID, cl.InstructorType, cl.AssignedBy,
	).Scan(&cl.CreatedAt, &cl.UpdatedAt)
	if err != nil {
		return fmt.Errorf("catalog.CreateClass: %w", err)
	}
	return nil
}

func (r *repository) GetClassByID(ctx context.Context, id uuid.UUID) (*Class, error) {
	query := `SELECT id, course_batch_id, title, session_date, start_time, end_time, mode, location, online_link,
	                 instructor_id, instructor_type, assigned_by, created_at, updated_at
	          FROM catalog.classes WHERE id = $1`

	cl := &Class{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&cl.ID, &cl.CourseBatchID, &cl.Title, &cl.SessionDate, &cl.StartTime, &cl.EndTime,
		&cl.Mode, &cl.Location, &cl.OnlineLink, &cl.InstructorID, &cl.InstructorType,
		&cl.AssignedBy, &cl.CreatedAt, &cl.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("catalog.GetClassByID: %w", err)
	}
	return cl, nil
}

func (r *repository) ListClassesByBatch(ctx context.Context, batchID uuid.UUID) ([]*Class, error) {
	query := `SELECT id, course_batch_id, title, session_date, start_time, end_time, mode, location, online_link,
	                 instructor_id, instructor_type, assigned_by, created_at, updated_at
	          FROM catalog.classes WHERE course_batch_id = $1 ORDER BY session_date, start_time`

	rows, err := r.pool.Query(ctx, query, batchID)
	if err != nil {
		return nil, fmt.Errorf("catalog.ListClassesByBatch: %w", err)
	}
	defer rows.Close()

	var classes []*Class
	for rows.Next() {
		cl := &Class{}
		if err := rows.Scan(&cl.ID, &cl.CourseBatchID, &cl.Title, &cl.SessionDate, &cl.StartTime, &cl.EndTime,
			&cl.Mode, &cl.Location, &cl.OnlineLink, &cl.InstructorID, &cl.InstructorType,
			&cl.AssignedBy, &cl.CreatedAt, &cl.UpdatedAt); err != nil {
			return nil, fmt.Errorf("catalog.ListClassesByBatch scan: %w", err)
		}
		classes = append(classes, cl)
	}
	return classes, rows.Err()
}

func (r *repository) CreateModule(ctx context.Context, m *CourseModule) error {
	query := `
		INSERT INTO catalog.modules (id, course_id, title, "order", is_active, created_by)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query, m.ID, m.CourseID, m.Title, m.Order, m.IsActive, m.CreatedBy).
		Scan(&m.CreatedAt, &m.UpdatedAt)
	if err != nil {
		return fmt.Errorf("catalog.CreateModule: %w", err)
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
		return nil, fmt.Errorf("catalog.GetModuleByID: %w", err)
	}
	return m, nil
}

func (r *repository) ListModulesByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error) {
	query := `SELECT id, course_id, title, "order", is_active, created_by, created_at, updated_at
	          FROM catalog.modules WHERE course_id = $1 AND is_active=true ORDER BY "order"`

	rows, err := r.pool.Query(ctx, query, courseID)
	if err != nil {
		return nil, fmt.Errorf("catalog.ListModulesByCourse: %w", err)
	}
	defer rows.Close()

	var modules []*CourseModule
	for rows.Next() {
		m := &CourseModule{}
		if err := rows.Scan(&m.ID, &m.CourseID, &m.Title, &m.Order, &m.IsActive, &m.CreatedBy, &m.CreatedAt, &m.UpdatedAt); err != nil {
			return nil, fmt.Errorf("catalog.ListModulesByCourse scan: %w", err)
		}
		modules = append(modules, m)
	}
	return modules, rows.Err()
}

func (r *repository) CreateModuleVersion(ctx context.Context, mv *ModuleVersion) error {
	query := `
		INSERT INTO catalog.module_versions (id, module_id, version_number, title, description, status, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		mv.ID, mv.ModuleID, mv.VersionNumber, mv.Title, mv.Description, mv.Status, mv.CreatedBy,
	).Scan(&mv.CreatedAt, &mv.UpdatedAt)
	if err != nil {
		return fmt.Errorf("catalog.CreateModuleVersion: %w", err)
	}
	return nil
}

func (r *repository) AddFormatConfig(ctx context.Context, cfg *CourseFormatConfig) error {
	query := `
		INSERT INTO catalog.course_format_configs
			(id, course_id, format, is_enabled, min_students, max_students, mode_online, mode_offline)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		cfg.ID, cfg.CourseID, cfg.Format, cfg.IsEnabled, cfg.MinStudents, cfg.MaxStudents,
		cfg.ModeOnline, cfg.ModeOffline,
	).Scan(&cfg.CreatedAt, &cfg.UpdatedAt)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == pgUniqueViolation {
			return apperrors.ErrConflict
		}
		return fmt.Errorf("catalog.AddFormatConfig: %w", err)
	}
	return nil
}

func (r *repository) DisableFormat(ctx context.Context, configID uuid.UUID) error {
	query := `UPDATE catalog.course_format_configs SET is_enabled=false WHERE id=$1`
	ct, err := r.pool.Exec(ctx, query, configID)
	if err != nil {
		return fmt.Errorf("catalog.DisableFormat: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListFormatConfigsByCourse(ctx context.Context, courseID uuid.UUID) ([]*CourseFormatConfig, error) {
	query := `SELECT id, course_id, format, is_enabled, min_students, max_students, mode_online, mode_offline, created_at, updated_at
	          FROM catalog.course_format_configs WHERE course_id=$1 ORDER BY format`

	rows, err := r.pool.Query(ctx, query, courseID)
	if err != nil {
		return nil, fmt.Errorf("catalog.ListFormatConfigsByCourse: %w", err)
	}
	defer rows.Close()

	var configs []*CourseFormatConfig
	for rows.Next() {
		cfg := &CourseFormatConfig{}
		if err := rows.Scan(&cfg.ID, &cfg.CourseID, &cfg.Format, &cfg.IsEnabled,
			&cfg.MinStudents, &cfg.MaxStudents, &cfg.ModeOnline, &cfg.ModeOffline,
			&cfg.CreatedAt, &cfg.UpdatedAt); err != nil {
			return nil, fmt.Errorf("catalog.ListFormatConfigsByCourse scan: %w", err)
		}
		configs = append(configs, cfg)
	}
	return configs, rows.Err()
}

func (r *repository) GetFormatConfig(ctx context.Context, id uuid.UUID) (*CourseFormatConfig, error) {
	query := `SELECT id, course_id, format, is_enabled, min_students, max_students, mode_online, mode_offline, created_at, updated_at
	          FROM catalog.course_format_configs WHERE id=$1`

	cfg := &CourseFormatConfig{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&cfg.ID, &cfg.CourseID, &cfg.Format, &cfg.IsEnabled,
		&cfg.MinStudents, &cfg.MaxStudents, &cfg.ModeOnline, &cfg.ModeOffline,
		&cfg.CreatedAt, &cfg.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("catalog.GetFormatConfig: %w", err)
	}
	return cfg, nil
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
		return nil, fmt.Errorf("catalog.GetModuleVersionByID: %w", err)
	}
	return mv, nil
}
