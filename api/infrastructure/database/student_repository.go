package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/student"
)

type StudentRepository struct {
	db *sqlx.DB
}

func NewStudentRepository(db *sqlx.DB) *StudentRepository {
	return &StudentRepository{db: db}
}

type studentRecord struct {
	ID           uuid.UUID  `db:"id"`
	Name         string     `db:"name"`
	Email        string     `db:"email"`
	Phone        string     `db:"phone"`
	DepartmentID *uuid.UUID `db:"department_id"`
	JoinedAt     time.Time  `db:"joined_at"`
	IsActive     bool       `db:"is_active"`
	CreatedAt    time.Time  `db:"created_at"`
	UpdatedAt    time.Time  `db:"updated_at"`
}

func (rec *studentRecord) toDomain() *student.Student {
	return &student.Student{
		ID:           rec.ID,
		Name:         rec.Name,
		Email:        rec.Email,
		Phone:        rec.Phone,
		DepartmentID: rec.DepartmentID,
		JoinedAt:     rec.JoinedAt,
		IsActive:     rec.IsActive,
		CreatedAt:    rec.CreatedAt,
		UpdatedAt:    rec.UpdatedAt,
	}
}

func (r *StudentRepository) Save(ctx context.Context, s *student.Student) error {
	query := `
		INSERT INTO students (id, name, email, phone, department_id, joined_at, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err := r.db.ExecContext(ctx, query,
		s.ID, s.Name, s.Email, s.Phone, s.DepartmentID,
		s.JoinedAt, s.IsActive, s.CreatedAt, s.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save student: %w", err)
	}
	return nil
}

func (r *StudentRepository) Update(ctx context.Context, s *student.Student) error {
	query := `
		UPDATE students
		SET name = $1, email = $2, phone = $3, department_id = $4, is_active = $5, updated_at = $6
		WHERE id = $7
	`
	_, err := r.db.ExecContext(ctx, query,
		s.Name, s.Email, s.Phone, s.DepartmentID, s.IsActive, s.UpdatedAt, s.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update student: %w", err)
	}
	return nil
}

func (r *StudentRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM students WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete student: %w", err)
	}
	return nil
}

func (r *StudentRepository) GetByID(ctx context.Context, id uuid.UUID) (*student.Student, error) {
	var rec studentRecord
	query := `SELECT id, name, email, phone, department_id, joined_at, is_active, created_at, updated_at FROM students WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get student: %w", err)
	}
	return rec.toDomain(), nil
}

func (r *StudentRepository) List(ctx context.Context, offset, limit int) ([]*student.Student, int, error) {
	var total int
	countQuery := `SELECT COUNT(*) FROM students`
	if err := r.db.GetContext(ctx, &total, countQuery); err != nil {
		return nil, 0, fmt.Errorf("failed to count students: %w", err)
	}

	var recs []studentRecord
	query := `SELECT id, name, email, phone, department_id, joined_at, is_active, created_at, updated_at FROM students ORDER BY created_at DESC LIMIT $1 OFFSET $2`
	if err := r.db.SelectContext(ctx, &recs, query, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list students: %w", err)
	}

	students := make([]*student.Student, len(recs))
	for i, rec := range recs {
		students[i] = rec.toDomain()
	}
	return students, total, nil
}

type studentListRecord struct {
	studentRecord
	ActiveBatchCount     int `db:"active_batch_count"`
	CompletedCourseCount int `db:"completed_course_count"`
}

func (r *StudentRepository) ListWithCounts(ctx context.Context, offset, limit int) ([]*student.StudentListEntry, int, error) {
	var total int
	if err := r.db.GetContext(ctx, &total, `SELECT COUNT(*) FROM students`); err != nil {
		return nil, 0, fmt.Errorf("failed to count students: %w", err)
	}

	query := `
		SELECT s.id, s.name, s.email, s.phone, s.department_id,
		       s.joined_at, s.is_active, s.created_at, s.updated_at,
		       COUNT(CASE WHEN e.status = 'active' THEN 1 END)     AS active_batch_count,
		       COUNT(CASE WHEN e.status = 'completed' THEN 1 END)  AS completed_course_count
		FROM students s
		LEFT JOIN enrollments e ON e.student_id = s.id
		GROUP BY s.id, s.name, s.email, s.phone, s.department_id,
		         s.joined_at, s.is_active, s.created_at, s.updated_at
		ORDER BY s.created_at DESC
		LIMIT $1 OFFSET $2`

	var recs []studentListRecord
	if err := r.db.SelectContext(ctx, &recs, query, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list students with counts: %w", err)
	}

	entries := make([]*student.StudentListEntry, len(recs))
	for i, rec := range recs {
		entries[i] = &student.StudentListEntry{
			Student:              *rec.studentRecord.toDomain(),
			ActiveBatchCount:     rec.ActiveBatchCount,
			CompletedCourseCount: rec.CompletedCourseCount,
		}
	}
	return entries, total, nil
}

// ── Thin reader/writer types used by query/command packages ──────────────────

type studentDetailRecord struct {
	studentRecord
	DepartmentName   string `db:"department_name"`
	TotalEnrollments int    `db:"total_enrollments"`
	CompletedCourses int    `db:"completed_courses"`
}

func (r *StudentRepository) GetDetail(ctx context.Context, id uuid.UUID) (*student.StudentDetail, error) {
	var rec studentDetailRecord
	query := `
		SELECT s.id, s.name, s.email, s.phone, s.department_id,
		       COALESCE(d.name, '') AS department_name,
		       s.joined_at, s.is_active, s.created_at, s.updated_at,
		       COUNT(e.id)                                           AS total_enrollments,
		       COUNT(CASE WHEN e.status = 'completed' THEN 1 END)   AS completed_courses
		FROM students s
		LEFT JOIN departments d ON d.id = s.department_id
		LEFT JOIN enrollments e ON e.student_id = s.id
		WHERE s.id = $1
		GROUP BY s.id, s.name, s.email, s.phone, s.department_id, d.name,
		         s.joined_at, s.is_active, s.created_at, s.updated_at`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get student detail: %w", err)
	}
	return &student.StudentDetail{
		Student:          *rec.studentRecord.toDomain(),
		DepartmentName:   rec.DepartmentName,
		TotalEnrollments: rec.TotalEnrollments,
		CompletedCourses: rec.CompletedCourses,
	}, nil
}

type enrollmentHistoryRecord struct {
	ID               uuid.UUID `db:"id"`
	BatchID          uuid.UUID `db:"batch_id"`
	BatchCode        string    `db:"batch_code"`
	BatchName        string    `db:"batch_name"`
	BatchType        string    `db:"batch_type"`
	CourseName       string    `db:"course_name"`
	CourseCode       string    `db:"course_code"`
	MasterCourseName string    `db:"master_course_name"`
	EnrolledAt       time.Time `db:"enrolled_at"`
	TotalAttendance  int       `db:"total_attendance"`
	TotalSessions    int       `db:"total_sessions"`
	FinalScore       *float64  `db:"final_score"`
	Grade            *string   `db:"grade"`
	Status           string    `db:"status"`
	PaymentStatus    string    `db:"payment_status"`
}

func (r *StudentRepository) GetEnrollmentHistory(ctx context.Context, studentID uuid.UUID) ([]*student.StudentEnrollmentHistoryItem, error) {
	query := `
		SELECT e.id,
		       cb.id                                           AS batch_id,
		       COALESCE(cb.name, '')                          AS batch_code,
		       COALESCE(cb.name, '')                          AS batch_name,
		       COALESCE(mc.field, COALESCE(c.name, 'Umum'))  AS batch_type,
		       COALESCE(c.name, COALESCE(mc.course_name, '')) AS course_name,
		       COALESCE(mc.course_code, '')                   AS course_code,
		       COALESCE(mc.course_name, '')                   AS master_course_name,
		       e.enrolled_at,
		       COALESCE(e.total_attendance, 0)                AS total_attendance,
		       COALESCE(cb.session_count, 0)                  AS total_sessions,
		       e.final_score,
		       e.grade,
		       e.status,
		       e.payment_status
		FROM enrollments e
		JOIN course_batches cb ON cb.id = e.course_batch_id
		LEFT JOIN courses c ON c.id = cb.course_id
		LEFT JOIN master_courses mc ON mc.id = cb.master_course_id
		WHERE e.student_id = $1
		ORDER BY e.enrolled_at DESC`

	var recs []enrollmentHistoryRecord
	if err := r.db.SelectContext(ctx, &recs, query, studentID); err != nil {
		return nil, fmt.Errorf("failed to get enrollment history: %w", err)
	}

	result := make([]*student.StudentEnrollmentHistoryItem, len(recs))
	for i, rec := range recs {
		result[i] = &student.StudentEnrollmentHistoryItem{
			ID:               rec.ID,
			BatchID:          rec.BatchID,
			BatchCode:        rec.BatchCode,
			BatchName:        rec.BatchName,
			BatchType:        rec.BatchType,
			CourseName:       rec.CourseName,
			CourseCode:       rec.CourseCode,
			MasterCourseName: rec.MasterCourseName,
			EnrolledAt:       rec.EnrolledAt,
			TotalAttendance:  rec.TotalAttendance,
			TotalSessions:    rec.TotalSessions,
			FinalScore:       rec.FinalScore,
			Grade:            rec.Grade,
			Status:           rec.Status,
			PaymentStatus:    rec.PaymentStatus,
		}
	}
	return result, nil
}

type recommendationRecord struct {
	MasterCourseID uuid.UUID `db:"master_course_id"`
	CourseName     string    `db:"course_name"`
	CourseCode     string    `db:"course_code"`
	Field          string    `db:"field"`
	Reason         string    `db:"reason"`
	HasActiveBatch bool      `db:"has_active_batch"`
}

func (r *StudentRepository) GetRecommendations(ctx context.Context, studentID uuid.UUID) ([]*student.StudentRecommendationItem, error) {
	query := `
		SELECT r.master_course_id,
		       mc.course_name,
		       mc.course_code,
		       mc.field,
		       r.reason,
		       EXISTS(
		           SELECT 1 FROM course_batches cb2
		           WHERE cb2.master_course_id = mc.id
		             AND cb2.status IN ('ongoing','upcoming')
		             AND cb2.is_active = TRUE
		       ) AS has_active_batch
		FROM student_course_recommendations r
		JOIN master_courses mc ON mc.id = r.master_course_id
		WHERE r.student_id = $1
		ORDER BY r.priority DESC, r.created_at DESC`

	var recs []recommendationRecord
	if err := r.db.SelectContext(ctx, &recs, query, studentID); err != nil {
		return nil, fmt.Errorf("failed to get recommendations: %w", err)
	}

	result := make([]*student.StudentRecommendationItem, len(recs))
	for i, rec := range recs {
		result[i] = &student.StudentRecommendationItem{
			MasterCourseID: rec.MasterCourseID,
			CourseName:     rec.CourseName,
			CourseCode:     rec.CourseCode,
			Field:          rec.Field,
			Reason:         rec.Reason,
			HasActiveBatch: rec.HasActiveBatch,
		}
	}
	return result, nil
}

type studentNoteRecord struct {
	ID         uuid.UUID `db:"id"`
	StudentID  uuid.UUID `db:"student_id"`
	AuthorID   string    `db:"author_id"`
	AuthorName string    `db:"author_name"`
	Content    string    `db:"content"`
	CreatedAt  time.Time `db:"created_at"`
}

func (r *StudentRepository) GetNotes(ctx context.Context, studentID uuid.UUID) ([]*student.StudentNoteItem, error) {
	query := `
		SELECT id, student_id, author_id,
		       COALESCE(author_name, author_id) AS author_name,
		       content, created_at
		FROM student_notes
		WHERE student_id = $1
		ORDER BY created_at DESC`

	var recs []studentNoteRecord
	if err := r.db.SelectContext(ctx, &recs, query, studentID); err != nil {
		return nil, fmt.Errorf("failed to get notes: %w", err)
	}

	result := make([]*student.StudentNoteItem, len(recs))
	for i, rec := range recs {
		result[i] = &student.StudentNoteItem{
			ID:         rec.ID,
			StudentID:  rec.StudentID,
			AuthorID:   rec.AuthorID,
			AuthorName: rec.AuthorName,
			Content:    rec.Content,
			CreatedAt:  rec.CreatedAt,
		}
	}
	return result, nil
}

func (r *StudentRepository) AddNote(ctx context.Context, studentID uuid.UUID, authorID, authorName, content string) (*student.StudentNoteItem, error) {
	query := `
		INSERT INTO student_notes (student_id, author_id, author_name, content)
		VALUES ($1, $2, $3, $4)
		RETURNING id, student_id, author_id, author_name, content, created_at`

	var rec studentNoteRecord
	if err := r.db.GetContext(ctx, &rec, query, studentID, authorID, authorName, content); err != nil {
		return nil, fmt.Errorf("failed to add note: %w", err)
	}
	return &student.StudentNoteItem{
		ID:         rec.ID,
		StudentID:  rec.StudentID,
		AuthorID:   rec.AuthorID,
		AuthorName: rec.AuthorName,
		Content:    rec.Content,
		CreatedAt:  rec.CreatedAt,
	}, nil
}
