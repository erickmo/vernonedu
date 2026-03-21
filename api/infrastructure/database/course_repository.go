package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/course"
)

type CourseRepository struct {
	db *sqlx.DB
}

func NewCourseRepository(db *sqlx.DB) *CourseRepository {
	return &CourseRepository{db: db}
}

type courseRecord struct {
	ID           uuid.UUID  `db:"id"`
	Name         string     `db:"name"`
	Description  string     `db:"description"`
	DepartmentID *uuid.UUID `db:"department_id"`
	OwnerID      *uuid.UUID `db:"owner_id"`
	IsActive     bool       `db:"is_active"`
	CreatedAt    time.Time  `db:"created_at"`
	UpdatedAt    time.Time  `db:"updated_at"`
}

func (rec *courseRecord) toDomain() *course.Course {
	return &course.Course{
		ID:           rec.ID,
		Name:         rec.Name,
		Description:  rec.Description,
		DepartmentID: rec.DepartmentID,
		OwnerID:      rec.OwnerID,
		IsActive:     rec.IsActive,
		CreatedAt:    rec.CreatedAt,
		UpdatedAt:    rec.UpdatedAt,
	}
}

func (r *CourseRepository) Save(ctx context.Context, c *course.Course) error {
	query := `
		INSERT INTO courses (id, name, description, department_id, owner_id, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := r.db.ExecContext(ctx, query, c.ID, c.Name, c.Description, c.DepartmentID, c.OwnerID, c.IsActive, c.CreatedAt, c.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save course: %w", err)
	}
	return nil
}

func (r *CourseRepository) Update(ctx context.Context, c *course.Course) error {
	query := `
		UPDATE courses
		SET name = $1, description = $2, department_id = $3, owner_id = $4, is_active = $5, updated_at = $6
		WHERE id = $7
	`
	_, err := r.db.ExecContext(ctx, query, c.Name, c.Description, c.DepartmentID, c.OwnerID, c.IsActive, c.UpdatedAt, c.ID)
	if err != nil {
		return fmt.Errorf("failed to update course: %w", err)
	}
	return nil
}

func (r *CourseRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM courses WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete course: %w", err)
	}
	return nil
}

func (r *CourseRepository) GetByID(ctx context.Context, id uuid.UUID) (*course.Course, error) {
	var rec courseRecord
	query := `SELECT id, name, description, department_id, owner_id, is_active, created_at, updated_at FROM courses WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get course: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *CourseRepository) List(ctx context.Context, offset, limit int) ([]*course.Course, int, error) {
	var total int
	countQuery := `SELECT COUNT(*) FROM courses`
	if err := r.db.GetContext(ctx, &total, countQuery); err != nil {
		return nil, 0, fmt.Errorf("failed to count courses: %w", err)
	}

	var recs []courseRecord
	query := `SELECT id, name, description, department_id, owner_id, is_active, created_at, updated_at FROM courses ORDER BY created_at DESC LIMIT $1 OFFSET $2`
	if err := r.db.SelectContext(ctx, &recs, query, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list courses: %w", err)
	}

	courses := make([]*course.Course, len(recs))
	for i, rec := range recs {
		courses[i] = rec.toDomain()
	}
	return courses, total, nil
}
