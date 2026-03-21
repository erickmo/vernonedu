package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/department"
)

type DepartmentRepository struct {
	db *sqlx.DB
}

func NewDepartmentRepository(db *sqlx.DB) *DepartmentRepository {
	return &DepartmentRepository{db: db}
}

type departmentRecord struct {
	ID          uuid.UUID  `db:"id"`
	Name        string     `db:"name"`
	Description string     `db:"description"`
	LeaderID    *uuid.UUID `db:"leader_id"`
	IsActive    bool       `db:"is_active"`
	CreatedAt   time.Time  `db:"created_at"`
	UpdatedAt   time.Time  `db:"updated_at"`
}

func (rec *departmentRecord) toDomain() *department.Department {
	return &department.Department{
		ID:          rec.ID,
		Name:        rec.Name,
		Description: rec.Description,
		LeaderID:    rec.LeaderID,
		IsActive:    rec.IsActive,
		CreatedAt:   rec.CreatedAt,
		UpdatedAt:   rec.UpdatedAt,
	}
}

func (r *DepartmentRepository) Save(ctx context.Context, d *department.Department) error {
	query := `
		INSERT INTO departments (id, name, description, leader_id, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err := r.db.ExecContext(ctx, query, d.ID, d.Name, d.Description, d.LeaderID, d.IsActive, d.CreatedAt, d.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save department: %w", err)
	}
	return nil
}

func (r *DepartmentRepository) Update(ctx context.Context, d *department.Department) error {
	query := `
		UPDATE departments
		SET name = $1, description = $2, leader_id = $3, is_active = $4, updated_at = $5
		WHERE id = $6
	`
	_, err := r.db.ExecContext(ctx, query, d.Name, d.Description, d.LeaderID, d.IsActive, d.UpdatedAt, d.ID)
	if err != nil {
		return fmt.Errorf("failed to update department: %w", err)
	}
	return nil
}

func (r *DepartmentRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM departments WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete department: %w", err)
	}
	return nil
}

func (r *DepartmentRepository) GetByID(ctx context.Context, id uuid.UUID) (*department.Department, error) {
	var rec departmentRecord
	query := `SELECT id, name, description, leader_id, is_active, created_at, updated_at FROM departments WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get department: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *DepartmentRepository) List(ctx context.Context, offset, limit int) ([]*department.Department, int, error) {
	var total int
	countQuery := `SELECT COUNT(*) FROM departments`
	if err := r.db.GetContext(ctx, &total, countQuery); err != nil {
		return nil, 0, fmt.Errorf("failed to count departments: %w", err)
	}

	var recs []departmentRecord
	query := `SELECT id, name, description, leader_id, is_active, created_at, updated_at FROM departments ORDER BY created_at DESC LIMIT $1 OFFSET $2`
	if err := r.db.SelectContext(ctx, &recs, query, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list departments: %w", err)
	}

	departments := make([]*department.Department, len(recs))
	for i, rec := range recs {
		departments[i] = rec.toDomain()
	}
	return departments, total, nil
}

// departmentSummaryRecord is used for the aggregated summary query.
type departmentSummaryRecord struct {
	ID                  uuid.UUID `db:"id"`
	Name                string    `db:"name"`
	Description         string    `db:"description"`
	CourseCount         int       `db:"course_count"`
	BatchUpcoming       int       `db:"batch_upcoming"`
	BatchOngoing        int       `db:"batch_ongoing"`
	BatchCompleted      int       `db:"batch_completed"`
	PaidEnrollmentCount int       `db:"paid_enrollment_count"`
}

func (r *DepartmentRepository) GetSummaries(ctx context.Context) ([]*department.DepartmentSummary, error) {
	query := `
		SELECT
			d.id,
			d.name,
			COALESCE(d.description, '') AS description,
			COUNT(DISTINCT c.id)                                                                   AS course_count,
			COUNT(DISTINCT CASE WHEN cb.start_date > CURRENT_DATE THEN cb.id END)                 AS batch_upcoming,
			COUNT(DISTINCT CASE WHEN cb.start_date <= CURRENT_DATE AND cb.end_date >= CURRENT_DATE THEN cb.id END) AS batch_ongoing,
			COUNT(DISTINCT CASE WHEN cb.end_date < CURRENT_DATE THEN cb.id END)                   AS batch_completed,
			COUNT(CASE WHEN e.payment_status = 'paid' THEN 1 END)                                 AS paid_enrollment_count
		FROM departments d
		LEFT JOIN courses c       ON c.department_id = d.id
		LEFT JOIN course_batches cb ON cb.course_id  = c.id
		LEFT JOIN enrollments e   ON e.course_batch_id = cb.id
		GROUP BY d.id, d.name, d.description
		ORDER BY d.name
	`

	var recs []departmentSummaryRecord
	if err := r.db.SelectContext(ctx, &recs, query); err != nil {
		return nil, fmt.Errorf("failed to get department summaries: %w", err)
	}

	result := make([]*department.DepartmentSummary, len(recs))
	for i, rec := range recs {
		result[i] = &department.DepartmentSummary{
			ID:                  rec.ID,
			Name:                rec.Name,
			Description:         rec.Description,
			CourseCount:         rec.CourseCount,
			BatchUpcoming:       rec.BatchUpcoming,
			BatchOngoing:        rec.BatchOngoing,
			BatchCompleted:      rec.BatchCompleted,
			PaidEnrollmentCount: rec.PaidEnrollmentCount,
		}
	}
	return result, nil
}

type deptBatchRecord struct {
	BatchID         uuid.UUID `db:"batch_id"`
	BatchName       string    `db:"batch_name"`
	StartDate       string    `db:"start_date"`
	EndDate         string    `db:"end_date"`
	MaxParticipants int       `db:"max_participants"`
	IsActive        bool      `db:"is_active"`
	CourseName      string    `db:"course_name"`
	FacilitatorID   string    `db:"facilitator_id"`
	FacilitatorName string    `db:"facilitator_name"`
	EnrollmentCount int       `db:"enrollment_count"`
}

func (r *DepartmentRepository) GetBatches(ctx context.Context, departmentID uuid.UUID) ([]*department.DepartmentBatch, error) {
	query := `
		SELECT
			cb.id                                     AS batch_id,
			cb.name                                   AS batch_name,
			cb.start_date::text                        AS start_date,
			cb.end_date::text                          AS end_date,
			cb.max_participants,
			cb.is_active,
			COALESCE(c.name, '')                      AS course_name,
			COALESCE(cb.facilitator_id::text, '')     AS facilitator_id,
			COALESCE(u.name, '')                      AS facilitator_name,
			COUNT(e.id)                               AS enrollment_count
		FROM course_batches cb
		JOIN courses c ON c.id = cb.course_id
		LEFT JOIN users u ON u.id = cb.facilitator_id
		LEFT JOIN enrollments e ON e.course_batch_id = cb.id
		WHERE c.department_id = $1
		GROUP BY cb.id, cb.name, cb.start_date, cb.end_date, cb.max_participants, cb.is_active,
		         c.name, cb.facilitator_id, u.name
		ORDER BY cb.start_date DESC
	`

	var recs []deptBatchRecord
	if err := r.db.SelectContext(ctx, &recs, query, departmentID); err != nil {
		return nil, fmt.Errorf("failed to get department batches: %w", err)
	}

	result := make([]*department.DepartmentBatch, len(recs))
	for i, rec := range recs {
		result[i] = &department.DepartmentBatch{
			BatchID:         rec.BatchID,
			BatchName:       rec.BatchName,
			StartDate:       rec.StartDate,
			EndDate:         rec.EndDate,
			MaxParticipants: rec.MaxParticipants,
			IsActive:        rec.IsActive,
			CourseName:      rec.CourseName,
			FacilitatorID:   rec.FacilitatorID,
			FacilitatorName: rec.FacilitatorName,
			EnrollmentCount: rec.EnrollmentCount,
		}
	}
	return result, nil
}

type deptCourseRecord struct {
	CourseID    string `db:"course_id"`
	CourseName  string `db:"course_name"`
	Description string `db:"description"`
	IsActive    bool   `db:"is_active"`
	BatchCount  int    `db:"batch_count"`
}

func (r *DepartmentRepository) GetCourses(ctx context.Context, departmentID uuid.UUID) ([]*department.DepartmentCourse, error) {
	query := `
		SELECT
			c.id::text                 AS course_id,
			c.name                     AS course_name,
			COALESCE(c.description,'') AS description,
			c.is_active,
			COUNT(DISTINCT cb.id)      AS batch_count
		FROM courses c
		LEFT JOIN course_batches cb ON cb.course_id = c.id
		WHERE c.department_id = $1
		GROUP BY c.id, c.name, c.description, c.is_active
		ORDER BY c.name
	`

	var recs []deptCourseRecord
	if err := r.db.SelectContext(ctx, &recs, query, departmentID); err != nil {
		return nil, fmt.Errorf("failed to get department courses: %w", err)
	}

	result := make([]*department.DepartmentCourse, len(recs))
	for i, rec := range recs {
		result[i] = &department.DepartmentCourse{
			CourseID:    rec.CourseID,
			CourseName:  rec.CourseName,
			Description: rec.Description,
			IsActive:    rec.IsActive,
			BatchCount:  rec.BatchCount,
		}
	}
	return result, nil
}

type deptStudentRecord struct {
	StudentID          uuid.UUID `db:"student_id"`
	StudentName        string    `db:"student_name"`
	Email              string    `db:"email"`
	Phone              string    `db:"phone"`
	IsActive           bool      `db:"is_active"`
	JoinedAt           time.Time `db:"joined_at"`
	EnrolledBatchCount int       `db:"enrolled_batch_count"`
}

func (r *DepartmentRepository) GetStudents(ctx context.Context, departmentID uuid.UUID, status string) ([]*department.DepartmentStudent, error) {
	query := `
		SELECT
			s.id          AS student_id,
			s.name        AS student_name,
			s.email,
			COALESCE(s.phone,'') AS phone,
			s.is_active,
			s.joined_at,
			COUNT(DISTINCT e.id) AS enrolled_batch_count
		FROM students s
		LEFT JOIN enrollments e ON e.student_id = s.id
		WHERE s.department_id = $1
		  AND (
		      $2 = ''
		      OR ($2 = 'active'  AND s.is_active = TRUE)
		      OR ($2 = 'alumni'  AND s.is_active = FALSE)
		  )
		GROUP BY s.id, s.name, s.email, s.phone, s.is_active, s.joined_at
		ORDER BY s.name
	`

	var recs []deptStudentRecord
	if err := r.db.SelectContext(ctx, &recs, query, departmentID, status); err != nil {
		return nil, fmt.Errorf("failed to get department students: %w", err)
	}

	result := make([]*department.DepartmentStudent, len(recs))
	for i, rec := range recs {
		result[i] = &department.DepartmentStudent{
			StudentID:          rec.StudentID,
			StudentName:        rec.StudentName,
			Email:              rec.Email,
			Phone:              rec.Phone,
			IsActive:           rec.IsActive,
			JoinedAt:           rec.JoinedAt,
			EnrolledBatchCount: rec.EnrolledBatchCount,
		}
	}
	return result, nil
}

type deptTalentPoolRecord struct {
	ID               uuid.UUID    `db:"id"`
	ParticipantID    uuid.UUID    `db:"participant_id"`
	ParticipantName  string       `db:"participant_name"`
	ParticipantEmail string       `db:"participant_email"`
	Status           string       `db:"status"`
	JoinedAt         time.Time    `db:"joined_at"`
	TestScore        *float64     `db:"test_score"`
}

func (r *DepartmentRepository) GetTalentPoolEntries(ctx context.Context, departmentID uuid.UUID) ([]*department.DepartmentTalentPoolEntry, error) {
	query := `
		SELECT
			t.id,
			t.participant_id,
			t.participant_name,
			COALESCE(t.participant_email, '') AS participant_email,
			t.talentpool_status              AS status,
			t.joined_at,
			t.test_score
		FROM talentpool t
		JOIN students s ON s.id = t.participant_id
		WHERE s.department_id = $1
		ORDER BY t.joined_at DESC
	`

	var recs []deptTalentPoolRecord
	if err := r.db.SelectContext(ctx, &recs, query, departmentID); err != nil && err != sql.ErrNoRows {
		return nil, fmt.Errorf("failed to get department talentpool: %w", err)
	}

	result := make([]*department.DepartmentTalentPoolEntry, len(recs))
	for i, rec := range recs {
		result[i] = &department.DepartmentTalentPoolEntry{
			ID:               rec.ID,
			ParticipantID:    rec.ParticipantID,
			ParticipantName:  rec.ParticipantName,
			ParticipantEmail: rec.ParticipantEmail,
			Status:           rec.Status,
			JoinedAt:         rec.JoinedAt,
			TestScore:        rec.TestScore,
		}
	}
	return result, nil
}
