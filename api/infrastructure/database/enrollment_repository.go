package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/enrollment"
)

type EnrollmentRepository struct {
	db *sqlx.DB
}

func NewEnrollmentRepository(db *sqlx.DB) *EnrollmentRepository {
	return &EnrollmentRepository{db: db}
}

type enrollmentRecord struct {
	ID            uuid.UUID `db:"id"`
	StudentID     uuid.UUID `db:"student_id"`
	CourseBatchID uuid.UUID `db:"course_batch_id"`
	EnrolledAt    time.Time `db:"enrolled_at"`
	Status        string    `db:"status"`
	PaymentStatus string    `db:"payment_status"`
	CreatedAt     time.Time `db:"created_at"`
	UpdatedAt     time.Time `db:"updated_at"`
}

func (rec *enrollmentRecord) toDomain() *enrollment.Enrollment {
	return &enrollment.Enrollment{
		ID:            rec.ID,
		StudentID:     rec.StudentID,
		CourseBatchID: rec.CourseBatchID,
		EnrolledAt:    rec.EnrolledAt,
		Status:        rec.Status,
		PaymentStatus: rec.PaymentStatus,
		CreatedAt:     rec.CreatedAt,
		UpdatedAt:     rec.UpdatedAt,
	}
}

func (r *EnrollmentRepository) Save(ctx context.Context, e *enrollment.Enrollment) error {
	query := `
		INSERT INTO enrollments (id, student_id, course_batch_id, enrolled_at, status, payment_status, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := r.db.ExecContext(ctx, query,
		e.ID, e.StudentID, e.CourseBatchID, e.EnrolledAt,
		e.Status, e.PaymentStatus, e.CreatedAt, e.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save enrollment: %w", err)
	}
	return nil
}

func (r *EnrollmentRepository) UpdateStatus(ctx context.Context, id uuid.UUID, status string) error {
	query := `UPDATE enrollments SET status = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.ExecContext(ctx, query, status, time.Now(), id)
	if err != nil {
		return fmt.Errorf("failed to update enrollment status: %w", err)
	}
	return nil
}

func (r *EnrollmentRepository) UpdatePaymentStatus(ctx context.Context, id uuid.UUID, paymentStatus string) error {
	query := `UPDATE enrollments SET payment_status = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.ExecContext(ctx, query, paymentStatus, time.Now(), id)
	if err != nil {
		return fmt.Errorf("failed to update enrollment payment status: %w", err)
	}
	return nil
}

func (r *EnrollmentRepository) GetByID(ctx context.Context, id uuid.UUID) (*enrollment.Enrollment, error) {
	var rec enrollmentRecord
	query := `SELECT id, student_id, course_batch_id, enrolled_at, status, payment_status, created_at, updated_at FROM enrollments WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get enrollment: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *EnrollmentRepository) List(ctx context.Context, offset, limit int) ([]*enrollment.Enrollment, int, error) {
	var total int
	countQuery := `SELECT COUNT(*) FROM enrollments`
	if err := r.db.GetContext(ctx, &total, countQuery); err != nil {
		return nil, 0, fmt.Errorf("failed to count enrollments: %w", err)
	}

	var recs []enrollmentRecord
	query := `SELECT id, student_id, course_batch_id, enrolled_at, status, payment_status, created_at, updated_at FROM enrollments ORDER BY created_at DESC LIMIT $1 OFFSET $2`
	if err := r.db.SelectContext(ctx, &recs, query, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list enrollments: %w", err)
	}

	enrollments := make([]*enrollment.Enrollment, len(recs))
	for i, rec := range recs {
		enrollments[i] = rec.toDomain()
	}
	return enrollments, total, nil
}

type enrichedEnrollmentRecord struct {
	ID            uuid.UUID `db:"id"`
	StudentID     uuid.UUID `db:"student_id"`
	StudentName   string    `db:"student_name"`
	StudentPhone  string    `db:"student_phone"`
	CourseBatchID uuid.UUID `db:"course_batch_id"`
	BatchName     string    `db:"batch_name"`
	CourseName    string    `db:"course_name"`
	EnrolledAt    time.Time `db:"enrolled_at"`
	Status        string    `db:"status"`
	PaymentStatus string    `db:"payment_status"`
	CreatedAt     time.Time `db:"created_at"`
	UpdatedAt     time.Time `db:"updated_at"`
}

func (r *EnrollmentRepository) ListEnriched(ctx context.Context, offset, limit int) ([]*enrollment.EnrichedEnrollment, int, error) {
	var total int
	countQuery := `SELECT COUNT(*) FROM enrollments`
	if err := r.db.GetContext(ctx, &total, countQuery); err != nil {
		return nil, 0, fmt.Errorf("failed to count enrollments: %w", err)
	}

	query := `
		SELECT
			e.id,
			e.student_id,
			COALESCE(s.name, '')          AS student_name,
			COALESCE(s.phone, '')         AS student_phone,
			e.course_batch_id,
			COALESCE(cb.name, '')         AS batch_name,
			COALESCE(c.name, '')          AS course_name,
			e.enrolled_at,
			e.status,
			e.payment_status,
			e.created_at,
			e.updated_at
		FROM enrollments e
		LEFT JOIN students s    ON s.id  = e.student_id
		LEFT JOIN course_batches cb ON cb.id = e.course_batch_id
		LEFT JOIN courses c     ON c.id  = cb.course_id
		ORDER BY e.created_at DESC
		LIMIT $1 OFFSET $2
	`

	var recs []enrichedEnrollmentRecord
	if err := r.db.SelectContext(ctx, &recs, query, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list enriched enrollments: %w", err)
	}

	result := make([]*enrollment.EnrichedEnrollment, len(recs))
	for i, rec := range recs {
		result[i] = &enrollment.EnrichedEnrollment{
			ID:            rec.ID,
			StudentID:     rec.StudentID,
			StudentName:   rec.StudentName,
			StudentPhone:  rec.StudentPhone,
			CourseBatchID: rec.CourseBatchID,
			BatchName:     rec.BatchName,
			CourseName:    rec.CourseName,
			EnrolledAt:    rec.EnrolledAt,
			Status:        rec.Status,
			PaymentStatus: rec.PaymentStatus,
			CreatedAt:     rec.CreatedAt,
			UpdatedAt:     rec.UpdatedAt,
		}
	}
	return result, total, nil
}

type batchSummaryRecord struct {
	BatchID          uuid.UUID  `db:"batch_id"`
	BatchName        string     `db:"batch_name"`
	StartDate        string     `db:"start_date"`
	EndDate          string     `db:"end_date"`
	MaxParticipants  int        `db:"max_participants"`
	IsActive         bool       `db:"is_active"`
	CourseID         string     `db:"course_id"`
	CourseName       string     `db:"course_name"`
	DepartmentID     string     `db:"department_id"`
	DepartmentName   string     `db:"department_name"`
	EnrollmentCount  int        `db:"enrollment_count"`
	PaidCount        int        `db:"paid_count"`
	LatestEnrolledAt *time.Time `db:"latest_enrolled_at"`
}

func (r *EnrollmentRepository) ListBatchSummary(ctx context.Context) ([]*enrollment.BatchSummary, error) {
	query := `
		SELECT
			cb.id                                      AS batch_id,
			cb.name                                    AS batch_name,
			cb.start_date::text                        AS start_date,
			cb.end_date::text                          AS end_date,
			cb.max_participants,
			cb.is_active,
			COALESCE(c.id::text, '')                   AS course_id,
			COALESCE(c.name, '')                       AS course_name,
			COALESCE(c.department_id::text, '')        AS department_id,
			COALESCE(d.name, '')                       AS department_name,
			COUNT(e.id)                                AS enrollment_count,
			COUNT(CASE WHEN e.payment_status = 'paid' THEN 1 END) AS paid_count,
			MAX(e.enrolled_at)                         AS latest_enrolled_at
		FROM course_batches cb
		LEFT JOIN courses c ON c.id = cb.course_id
		LEFT JOIN departments d ON d.id = c.department_id
		LEFT JOIN enrollments e ON e.course_batch_id = cb.id
		GROUP BY cb.id, cb.name, cb.start_date, cb.end_date, cb.max_participants, cb.is_active,
		         c.id, c.name, c.department_id, d.name
		ORDER BY MAX(e.enrolled_at) DESC NULLS LAST, cb.start_date DESC
	`

	var recs []batchSummaryRecord
	if err := r.db.SelectContext(ctx, &recs, query); err != nil {
		return nil, fmt.Errorf("failed to list batch summary: %w", err)
	}

	result := make([]*enrollment.BatchSummary, len(recs))
	for i, rec := range recs {
		result[i] = &enrollment.BatchSummary{
			BatchID:          rec.BatchID,
			BatchName:        rec.BatchName,
			StartDate:        rec.StartDate,
			EndDate:          rec.EndDate,
			MaxParticipants:  rec.MaxParticipants,
			IsActive:         rec.IsActive,
			CourseID:         rec.CourseID,
			CourseName:       rec.CourseName,
			DepartmentID:     rec.DepartmentID,
			DepartmentName:   rec.DepartmentName,
			EnrollmentCount:  rec.EnrollmentCount,
			PaidCount:        rec.PaidCount,
			LatestEnrolledAt: rec.LatestEnrolledAt,
		}
	}
	return result, nil
}
