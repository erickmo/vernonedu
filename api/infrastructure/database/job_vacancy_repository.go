package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/job_vacancy"
)

type JobVacancyRepository struct {
	db *sqlx.DB
}

func NewJobVacancyRepository(db *sqlx.DB) *JobVacancyRepository {
	return &JobVacancyRepository{db: db}
}

type jobVacancyRow struct {
	ID              string         `db:"id"`
	Title           string         `db:"title"`
	Description     string         `db:"description"`
	PartnerID       string         `db:"partner_id"`
	DepartmentID    sql.NullString `db:"department_id"`
	Location        string         `db:"location"`
	Type            string         `db:"type"`
	Status          string         `db:"status"`
	ExperienceLevel string         `db:"experience_level"`
	Slots           int            `db:"slots"`
	MinSalary       sql.NullInt64  `db:"min_salary"`
	MaxSalary       sql.NullInt64  `db:"max_salary"`
	RequiredSkills  pq.StringArray `db:"required_skills"`
	Deadline        sql.NullTime   `db:"deadline"`
	CreatedBy       string         `db:"created_by"`
	CreatedAt       time.Time      `db:"created_at"`
	UpdatedAt       time.Time      `db:"updated_at"`
}

func (row *jobVacancyRow) toDomain() (*job_vacancy.JobVacancy, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse job_vacancy id: %w", err)
	}

	partnerID, err := uuid.Parse(row.PartnerID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse job_vacancy partner_id: %w", err)
	}

	createdBy, err := uuid.Parse(row.CreatedBy)
	if err != nil {
		return nil, fmt.Errorf("failed to parse job_vacancy created_by: %w", err)
	}

	var departmentID *uuid.UUID
	if row.DepartmentID.Valid && row.DepartmentID.String != "" {
		parsed, err := uuid.Parse(row.DepartmentID.String)
		if err != nil {
			return nil, fmt.Errorf("failed to parse job_vacancy department_id: %w", err)
		}
		departmentID = &parsed
	}

	var minSalary *int64
	if row.MinSalary.Valid {
		v := row.MinSalary.Int64
		minSalary = &v
	}

	var maxSalary *int64
	if row.MaxSalary.Valid {
		v := row.MaxSalary.Int64
		maxSalary = &v
	}

	var deadline *time.Time
	if row.Deadline.Valid {
		t := row.Deadline.Time
		deadline = &t
	}

	skills := []string(row.RequiredSkills)
	if skills == nil {
		skills = []string{}
	}

	return &job_vacancy.JobVacancy{
		ID:              id,
		Title:           row.Title,
		Description:     row.Description,
		PartnerID:       partnerID,
		DepartmentID:    departmentID,
		Location:        row.Location,
		Type:            row.Type,
		Status:          row.Status,
		ExperienceLevel: row.ExperienceLevel,
		Slots:           row.Slots,
		MinSalary:       minSalary,
		MaxSalary:       maxSalary,
		RequiredSkills:  skills,
		Deadline:        deadline,
		CreatedBy:       createdBy,
		CreatedAt:       row.CreatedAt,
		UpdatedAt:       row.UpdatedAt,
	}, nil
}

func (r *JobVacancyRepository) Save(ctx context.Context, v *job_vacancy.JobVacancy) error {
	var departmentID any
	if v.DepartmentID != nil {
		departmentID = v.DepartmentID.String()
	}
	var minSalary, maxSalary any
	if v.MinSalary != nil {
		minSalary = *v.MinSalary
	}
	if v.MaxSalary != nil {
		maxSalary = *v.MaxSalary
	}
	var deadline any
	if v.Deadline != nil {
		deadline = *v.Deadline
	}

	query := `
		INSERT INTO job_vacancies (
			id, title, description, partner_id, department_id, location, type, status,
			experience_level, slots, min_salary, max_salary, required_skills,
			deadline, created_by, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
	`
	_, err := r.db.ExecContext(ctx, query,
		v.ID.String(), v.Title, v.Description, v.PartnerID.String(), departmentID,
		v.Location, v.Type, v.Status, v.ExperienceLevel, v.Slots,
		minSalary, maxSalary, pq.Array(v.RequiredSkills),
		deadline, v.CreatedBy.String(), v.CreatedAt, v.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save job vacancy: %w", err)
	}
	return nil
}

func (r *JobVacancyRepository) Update(ctx context.Context, v *job_vacancy.JobVacancy) error {
	var departmentID any
	if v.DepartmentID != nil {
		departmentID = v.DepartmentID.String()
	}
	var minSalary, maxSalary any
	if v.MinSalary != nil {
		minSalary = *v.MinSalary
	}
	if v.MaxSalary != nil {
		maxSalary = *v.MaxSalary
	}
	var deadline any
	if v.Deadline != nil {
		deadline = *v.Deadline
	}

	query := `
		UPDATE job_vacancies
		SET title=$1, description=$2, partner_id=$3, department_id=$4, location=$5,
		    type=$6, status=$7, experience_level=$8, slots=$9,
		    min_salary=$10, max_salary=$11, required_skills=$12,
		    deadline=$13, updated_at=$14
		WHERE id=$15 AND deleted_at IS NULL
	`
	_, err := r.db.ExecContext(ctx, query,
		v.Title, v.Description, v.PartnerID.String(), departmentID,
		v.Location, v.Type, v.Status, v.ExperienceLevel, v.Slots,
		minSalary, maxSalary, pq.Array(v.RequiredSkills),
		deadline, v.UpdatedAt, v.ID.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to update job vacancy: %w", err)
	}
	return nil
}

func (r *JobVacancyRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE job_vacancies SET deleted_at=NOW() WHERE id=$1 AND deleted_at IS NULL`,
		id.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to delete job vacancy: %w", err)
	}
	return nil
}

func (r *JobVacancyRepository) GetByIDForWrite(ctx context.Context, id uuid.UUID) (*job_vacancy.JobVacancy, error) {
	var row jobVacancyRow
	query := `
		SELECT id, title, description, partner_id, department_id, location, type, status,
		       experience_level, slots, min_salary, max_salary, required_skills,
		       deadline, created_by, created_at, updated_at
		FROM job_vacancies
		WHERE id=$1 AND deleted_at IS NULL
	`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get job vacancy for write: %w", err)
	}
	return row.toDomain()
}

func (r *JobVacancyRepository) GetByID(ctx context.Context, id uuid.UUID) (*job_vacancy.JobVacancy, error) {
	var row jobVacancyRow
	query := `
		SELECT id, title, description, partner_id, department_id, location, type, status,
		       experience_level, slots, min_salary, max_salary, required_skills,
		       deadline, created_by, created_at, updated_at
		FROM job_vacancies
		WHERE id=$1 AND deleted_at IS NULL
	`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get job vacancy: %w", err)
	}
	return row.toDomain()
}

var jobVacancySortCols = map[string]string{
	"title":            "title",
	"status":           "status",
	"type":             "type",
	"experience_level": "experience_level",
	"deadline":         "deadline",
	"created_at":       "created_at",
}

func (r *JobVacancyRepository) List(ctx context.Context, offset, limit int, status, partnerID, vacancyType, search, sortBy, sortDir string) ([]*job_vacancy.JobVacancy, int, error) {
	args := []any{}
	argIdx := 1

	whereClause := "WHERE deleted_at IS NULL"

	if status != "" {
		whereClause += fmt.Sprintf(" AND status=$%d", argIdx)
		args = append(args, status)
		argIdx++
	}
	if partnerID != "" {
		whereClause += fmt.Sprintf(" AND partner_id::text=$%d", argIdx)
		args = append(args, partnerID)
		argIdx++
	}
	if vacancyType != "" {
		whereClause += fmt.Sprintf(" AND type=$%d", argIdx)
		args = append(args, vacancyType)
		argIdx++
	}
	if search != "" {
		whereClause += fmt.Sprintf(" AND title ILIKE $%d", argIdx)
		args = append(args, "%"+search+"%")
		argIdx++
	}

	var total int
	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM job_vacancies %s`, whereClause)
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count job vacancies: %w", err)
	}

	orderBy := buildOrderBy(sortBy, sortDir, jobVacancySortCols, "created_at DESC")
	dataArgs := append(args, limit, offset)
	query := fmt.Sprintf(`
		SELECT id, title, description, partner_id, department_id, location, type, status,
		       experience_level, slots, min_salary, max_salary, required_skills,
		       deadline, created_by, created_at, updated_at
		FROM job_vacancies
		%s
		%s
		LIMIT $%d OFFSET $%d
	`, whereClause, orderBy, argIdx, argIdx+1)

	var rows []jobVacancyRow
	if err := r.db.SelectContext(ctx, &rows, query, dataArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to list job vacancies: %w", err)
	}

	vacancies := make([]*job_vacancy.JobVacancy, 0, len(rows))
	for _, row := range rows {
		v, err := row.toDomain()
		if err != nil {
			return nil, 0, err
		}
		vacancies = append(vacancies, v)
	}
	return vacancies, total, nil
}
