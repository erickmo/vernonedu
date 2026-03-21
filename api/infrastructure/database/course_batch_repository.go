package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursebatch"
)

type CourseBatchRepository struct {
	db *sqlx.DB
}

func NewCourseBatchRepository(db *sqlx.DB) *CourseBatchRepository {
	return &CourseBatchRepository{db: db}
}

type courseBatchRecord struct {
	ID              uuid.UUID  `db:"id"`
	CourseID        uuid.UUID  `db:"course_id"`
	MasterCourseID  *uuid.UUID `db:"master_course_id"`
	Code            string     `db:"code"`
	Name            string     `db:"name"`
	StartDate       time.Time  `db:"start_date"`
	EndDate         time.Time  `db:"end_date"`
	FacilitatorID   *uuid.UUID `db:"facilitator_id"`
	MinParticipants int        `db:"min_participants"`
	MaxParticipants int        `db:"max_participants"`
	WebsiteVisible  bool       `db:"website_visible"`
	Price           int64      `db:"price"`
	PaymentMethod   string     `db:"payment_method"`
	IsActive        bool       `db:"is_active"`
	Status          string     `db:"status"`
	CreatedAt       time.Time  `db:"created_at"`
	UpdatedAt       time.Time  `db:"updated_at"`
}

type enrichedBatchRecord struct {
	ID              uuid.UUID  `db:"id"`
	CourseID        uuid.UUID  `db:"course_id"`
	MasterCourseID  *uuid.UUID `db:"master_course_id"`
	Code            string     `db:"code"`
	Name            string     `db:"name"`
	StartDate       time.Time  `db:"start_date"`
	EndDate         time.Time  `db:"end_date"`
	FacilitatorID   *uuid.UUID `db:"facilitator_id"`
	FacilitatorName string     `db:"facilitator_name"`
	MinParticipants int        `db:"min_participants"`
	MaxParticipants int        `db:"max_participants"`
	WebsiteVisible  bool       `db:"website_visible"`
	Price           int64      `db:"price"`
	PaymentMethod   string     `db:"payment_method"`
	IsActive        bool       `db:"is_active"`
	Status          string     `db:"status"`
	EnrollmentCount int        `db:"enrollment_count"`
	CreatedAt       time.Time  `db:"created_at"`
	UpdatedAt       time.Time  `db:"updated_at"`
}

func (rec *courseBatchRecord) toDomain() *coursebatch.CourseBatch {
	return &coursebatch.CourseBatch{
		ID:              rec.ID,
		CourseID:        rec.CourseID,
		MasterCourseID:  rec.MasterCourseID,
		Code:            rec.Code,
		Name:            rec.Name,
		StartDate:       rec.StartDate,
		EndDate:         rec.EndDate,
		FacilitatorID:   rec.FacilitatorID,
		MinParticipants: rec.MinParticipants,
		MaxParticipants: rec.MaxParticipants,
		WebsiteVisible:  rec.WebsiteVisible,
		Price:           rec.Price,
		PaymentMethod:   rec.PaymentMethod,
		IsActive:        rec.IsActive,
		Status:          rec.Status,
		CreatedAt:       rec.CreatedAt,
		UpdatedAt:       rec.UpdatedAt,
	}
}

func (r *CourseBatchRepository) Save(ctx context.Context, cb *coursebatch.CourseBatch) error {
	query := `
		INSERT INTO course_batches (id, course_id, master_course_id, code, name, start_date, end_date, facilitator_id, min_participants, max_participants, website_visible, price, payment_method, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
	`
	_, err := r.db.ExecContext(ctx, query,
		cb.ID, cb.CourseID, cb.MasterCourseID, cb.Code, cb.Name, cb.StartDate, cb.EndDate,
		cb.FacilitatorID, cb.MinParticipants, cb.MaxParticipants, cb.WebsiteVisible, cb.Price, cb.PaymentMethod,
		cb.IsActive, cb.CreatedAt, cb.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save course batch: %w", err)
	}
	return nil
}

func (r *CourseBatchRepository) Update(ctx context.Context, cb *coursebatch.CourseBatch) error {
	query := `
		UPDATE course_batches
		SET code = $1, name = $2, start_date = $3, end_date = $4, facilitator_id = $5, min_participants = $6, max_participants = $7, website_visible = $8, price = $9, payment_method = $10, is_active = $11, updated_at = $12
		WHERE id = $13
	`
	_, err := r.db.ExecContext(ctx, query,
		cb.Code, cb.Name, cb.StartDate, cb.EndDate, cb.FacilitatorID,
		cb.MinParticipants, cb.MaxParticipants, cb.WebsiteVisible, cb.Price, cb.PaymentMethod,
		cb.IsActive, cb.UpdatedAt, cb.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update course batch: %w", err)
	}
	return nil
}

func (r *CourseBatchRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM course_batches WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete course batch: %w", err)
	}
	return nil
}

func (r *CourseBatchRepository) GetByID(ctx context.Context, id uuid.UUID) (*coursebatch.CourseBatch, error) {
	var rec courseBatchRecord
	query := `SELECT id, course_id, COALESCE(master_course_id, NULL) as master_course_id, COALESCE(code, '') as code, name, start_date, end_date, facilitator_id, COALESCE(min_participants, 0) as min_participants, max_participants, COALESCE(website_visible, true) as website_visible, COALESCE(price, 0) as price, COALESCE(payment_method, 'upfront') as payment_method, is_active, COALESCE(status, 'upcoming') as status, created_at, updated_at FROM course_batches WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get course batch: %w", err)
	}
	return rec.toDomain(), nil
}

type batchDetailRecord struct {
	BatchID           uuid.UUID `db:"batch_id"`
	BatchName         string    `db:"batch_name"`
	StartDate         time.Time `db:"start_date"`
	EndDate           time.Time `db:"end_date"`
	MaxParticipants   int       `db:"max_participants"`
	IsActive          bool      `db:"is_active"`
	CourseID          string    `db:"course_id"`
	CourseName        string    `db:"course_name"`
	CourseDescription string    `db:"course_description"`
	DepartmentID      string    `db:"department_id"`
	DepartmentName    string    `db:"department_name"`
	FacilitatorID     string    `db:"facilitator_id"`
	FacilitatorName   string    `db:"facilitator_name"`
	FacilitatorEmail  string    `db:"facilitator_email"`
	CreatedAt         time.Time `db:"created_at"`
}

type batchEnrollmentRecord struct {
	EnrollmentID  uuid.UUID `db:"enrollment_id"`
	StudentID     uuid.UUID `db:"student_id"`
	StudentName   string    `db:"student_name"`
	StudentEmail  string    `db:"student_email"`
	StudentPhone  string    `db:"student_phone"`
	EnrolledAt    time.Time `db:"enrolled_at"`
	Status        string    `db:"status"`
	PaymentStatus string    `db:"payment_status"`
}

func (r *CourseBatchRepository) GetBatchDetail(ctx context.Context, batchID uuid.UUID) (*coursebatch.BatchDetailInfo, error) {
	batchQuery := `
		SELECT
			cb.id                                 AS batch_id,
			cb.name                               AS batch_name,
			cb.start_date,
			cb.end_date,
			cb.max_participants,
			cb.is_active,
			cb.created_at,
			COALESCE(c.id::text, '')              AS course_id,
			COALESCE(c.name, '')                  AS course_name,
			COALESCE(c.description, '')           AS course_description,
			COALESCE(c.department_id::text, '')   AS department_id,
			COALESCE(d.name, '')                  AS department_name,
			COALESCE(cb.facilitator_id::text, '') AS facilitator_id,
			COALESCE(u.name, '')                  AS facilitator_name,
			COALESCE(u.email, '')                 AS facilitator_email
		FROM course_batches cb
		LEFT JOIN courses c ON c.id = cb.course_id
		LEFT JOIN departments d ON d.id = c.department_id
		LEFT JOIN users u ON u.id = cb.facilitator_id
		WHERE cb.id = $1
	`

	var br batchDetailRecord
	if err := r.db.GetContext(ctx, &br, batchQuery, batchID); err != nil {
		return nil, fmt.Errorf("failed to get batch detail: %w", err)
	}

	enrollmentQuery := `
		SELECT
			e.id                       AS enrollment_id,
			e.student_id,
			COALESCE(s.name, '')       AS student_name,
			COALESCE(s.email, '')      AS student_email,
			COALESCE(s.phone, '')      AS student_phone,
			e.enrolled_at,
			e.status,
			e.payment_status
		FROM enrollments e
		LEFT JOIN students s ON s.id = e.student_id
		WHERE e.course_batch_id = $1
		ORDER BY e.enrolled_at DESC
	`

	var ers []batchEnrollmentRecord
	if err := r.db.SelectContext(ctx, &ers, enrollmentQuery, batchID); err != nil {
		return nil, fmt.Errorf("failed to get batch enrollments: %w", err)
	}

	items := make([]*coursebatch.BatchEnrollmentItem, len(ers))
	for i, er := range ers {
		items[i] = &coursebatch.BatchEnrollmentItem{
			EnrollmentID:  er.EnrollmentID,
			StudentID:     er.StudentID,
			StudentName:   er.StudentName,
			StudentEmail:  er.StudentEmail,
			StudentPhone:  er.StudentPhone,
			EnrolledAt:    er.EnrolledAt,
			Status:        er.Status,
			PaymentStatus: er.PaymentStatus,
		}
	}

	return &coursebatch.BatchDetailInfo{
		ID:                br.BatchID,
		Name:              br.BatchName,
		StartDate:         br.StartDate,
		EndDate:           br.EndDate,
		MaxParticipants:   br.MaxParticipants,
		IsActive:          br.IsActive,
		CourseID:          br.CourseID,
		CourseName:        br.CourseName,
		CourseDescription: br.CourseDescription,
		DepartmentID:      br.DepartmentID,
		DepartmentName:    br.DepartmentName,
		FacilitatorID:     br.FacilitatorID,
		FacilitatorName:   br.FacilitatorName,
		FacilitatorEmail:  br.FacilitatorEmail,
		CreatedAt:         br.CreatedAt,
		Enrollments:       items,
	}, nil
}

func (r *CourseBatchRepository) AssignFacilitator(ctx context.Context, batchID uuid.UUID, facilitatorID *uuid.UUID) error {
	query := `UPDATE course_batches SET facilitator_id = $1, updated_at = NOW() WHERE id = $2`
	_, err := r.db.ExecContext(ctx, query, facilitatorID, batchID)
	if err != nil {
		return fmt.Errorf("failed to assign facilitator: %w", err)
	}
	return nil
}

func (r *CourseBatchRepository) List(ctx context.Context, offset, limit int) ([]*coursebatch.CourseBatch, int, error) {
	var total int
	countQuery := `SELECT COUNT(*) FROM course_batches`
	if err := r.db.GetContext(ctx, &total, countQuery); err != nil {
		return nil, 0, fmt.Errorf("failed to count course batches: %w", err)
	}

	var recs []courseBatchRecord
	query := `SELECT id, course_id, COALESCE(master_course_id, NULL) as master_course_id, COALESCE(code, '') as code, name, start_date, end_date, facilitator_id, COALESCE(min_participants, 0) as min_participants, max_participants, COALESCE(website_visible, true) as website_visible, COALESCE(price, 0) as price, COALESCE(payment_method, 'upfront') as payment_method, is_active, COALESCE(status, 'upcoming') as status, created_at, updated_at FROM course_batches ORDER BY created_at DESC LIMIT $1 OFFSET $2`
	if err := r.db.SelectContext(ctx, &recs, query, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list course batches: %w", err)
	}

	batches := make([]*coursebatch.CourseBatch, len(recs))
	for i, rec := range recs {
		batches[i] = rec.toDomain()
	}
	return batches, total, nil
}

func (r *CourseBatchRepository) ListEnriched(ctx context.Context, offset, limit int) ([]*coursebatch.EnrichedCourseBatch, int, error) {
	var total int
	countQuery := `SELECT COUNT(*) FROM course_batches`
	if err := r.db.GetContext(ctx, &total, countQuery); err != nil {
		return nil, 0, fmt.Errorf("failed to count course batches: %w", err)
	}

	var recs []enrichedBatchRecord
	query := `
		SELECT
			cb.id, cb.course_id, cb.master_course_id,
			COALESCE(cb.code, '') as code,
			cb.name, cb.start_date, cb.end_date,
			cb.facilitator_id,
			COALESCE(u.name, '') as facilitator_name,
			COALESCE(cb.min_participants, 0) as min_participants,
			cb.max_participants,
			COALESCE(cb.website_visible, true) as website_visible,
			COALESCE(cb.price, 0) as price,
			COALESCE(cb.payment_method, 'upfront') as payment_method,
			cb.is_active,
			COALESCE(cb.status, 'upcoming') as status,
			COUNT(e.id) as enrollment_count,
			cb.created_at, cb.updated_at
		FROM course_batches cb
		LEFT JOIN users u ON u.id = cb.facilitator_id
		LEFT JOIN enrollments e ON e.course_batch_id = cb.id
		GROUP BY cb.id, u.name
		ORDER BY cb.created_at DESC
		LIMIT $1 OFFSET $2
	`
	if err := r.db.SelectContext(ctx, &recs, query, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list enriched course batches: %w", err)
	}

	batches := make([]*coursebatch.EnrichedCourseBatch, len(recs))
	for i, rec := range recs {
		batches[i] = &coursebatch.EnrichedCourseBatch{
			CourseBatch: coursebatch.CourseBatch{
				ID:              rec.ID,
				CourseID:        rec.CourseID,
				MasterCourseID:  rec.MasterCourseID,
				Code:            rec.Code,
				Name:            rec.Name,
				StartDate:       rec.StartDate,
				EndDate:         rec.EndDate,
				FacilitatorID:   rec.FacilitatorID,
				MinParticipants: rec.MinParticipants,
				MaxParticipants: rec.MaxParticipants,
				WebsiteVisible:  rec.WebsiteVisible,
				Price:           rec.Price,
				PaymentMethod:   rec.PaymentMethod,
				IsActive:        rec.IsActive,
				Status:          rec.Status,
				CreatedAt:       rec.CreatedAt,
				UpdatedAt:       rec.UpdatedAt,
			},
			FacilitatorName: rec.FacilitatorName,
			EnrollmentCount: rec.EnrollmentCount,
		}
	}
	return batches, total, nil
}
