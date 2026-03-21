package database

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/mastercourse"
)

// BatchRecord merepresentasikan data batch yang terhubung ke master course.
type BatchRecord struct {
	ID              uuid.UUID `db:"id"`
	Name            string    `db:"name"`
	StartDate       time.Time `db:"start_date"`
	EndDate         time.Time `db:"end_date"`
	Status          string    `db:"status"`
	MaxParticipants int       `db:"max_participants"`
	SessionCount    int       `db:"session_count"`
	Location        string    `db:"location"`
	EnrollmentCount int       `db:"enrollment_count"`
}

// StudentRecord merepresentasikan data siswa yang pernah enroll ke batch master course.
type StudentRecord struct {
	ID            uuid.UUID `db:"id"`
	Name          string    `db:"name"`
	Email         string    `db:"email"`
	Phone         string    `db:"phone"`
	BatchName     string    `db:"batch_name"`
	EnrollStatus  string    `db:"enroll_status"`
	PaymentStatus string    `db:"payment_status"`
	EnrolledAt    time.Time `db:"enrolled_at"`
}

// MasterCourseRepository mengimplementasikan mastercourse.WriteRepository dan mastercourse.ReadRepository.
// Menggunakan PostgreSQL dengan sqlx untuk operasi database.
type MasterCourseRepository struct {
	db *sqlx.DB
}

// NewMasterCourseRepository membuat instance baru MasterCourseRepository.
func NewMasterCourseRepository(db *sqlx.DB) *MasterCourseRepository {
	return &MasterCourseRepository{db: db}
}

// masterCourseRecord adalah representasi row dari tabel master_courses.
type masterCourseRecord struct {
	ID               uuid.UUID `db:"id"`
	CourseCode       string    `db:"course_code"`
	CourseName       string    `db:"course_name"`
	Field            string    `db:"field"`
	CoreCompetencies []byte    `db:"core_competencies"` // JSONB discan sebagai []byte
	Description      string    `db:"description"`
	Status           string    `db:"status"`
	SupportingAppUrl *string   `db:"supporting_app_url"`
	CreatedAt        time.Time `db:"created_at"`
	UpdatedAt        time.Time `db:"updated_at"`
}

// toDomain mengonversi record database ke domain entity MasterCourse.
func (rec *masterCourseRecord) toDomain() (*mastercourse.MasterCourse, error) {
	var coreCompetencies []string
	if len(rec.CoreCompetencies) > 0 {
		if err := json.Unmarshal(rec.CoreCompetencies, &coreCompetencies); err != nil {
			return nil, fmt.Errorf("failed to unmarshal core_competencies: %w", err)
		}
	}
	if coreCompetencies == nil {
		coreCompetencies = []string{}
	}
	return &mastercourse.MasterCourse{
		ID:               rec.ID,
		CourseCode:       rec.CourseCode,
		CourseName:       rec.CourseName,
		Field:            rec.Field,
		CoreCompetencies: coreCompetencies,
		Description:      rec.Description,
		Status:           rec.Status,
		SupportingAppUrl: rec.SupportingAppUrl,
		CreatedAt:        rec.CreatedAt,
		UpdatedAt:        rec.UpdatedAt,
	}, nil
}

// Save menyimpan entitas MasterCourse baru ke database.
func (r *MasterCourseRepository) Save(ctx context.Context, mc *mastercourse.MasterCourse) error {
	competenciesJSON, err := json.Marshal(mc.CoreCompetencies)
	if err != nil {
		return fmt.Errorf("failed to marshal core_competencies: %w", err)
	}
	query := `
		INSERT INTO master_courses (id, course_code, course_name, field, core_competencies, description, status, supporting_app_url, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	_, err = r.db.ExecContext(ctx, query,
		mc.ID, mc.CourseCode, mc.CourseName, mc.Field,
		competenciesJSON, mc.Description, mc.Status, mc.SupportingAppUrl, mc.CreatedAt, mc.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save master course: %w", err)
	}
	return nil
}

// Update memperbarui data MasterCourse yang sudah ada di database.
func (r *MasterCourseRepository) Update(ctx context.Context, mc *mastercourse.MasterCourse) error {
	competenciesJSON, err := json.Marshal(mc.CoreCompetencies)
	if err != nil {
		return fmt.Errorf("failed to marshal core_competencies: %w", err)
	}
	query := `
		UPDATE master_courses
		SET course_name = $1, field = $2, core_competencies = $3, description = $4, status = $5,
		    supporting_app_url = $6, updated_at = $7
		WHERE id = $8
	`
	_, err = r.db.ExecContext(ctx, query,
		mc.CourseName, mc.Field, competenciesJSON, mc.Description, mc.Status,
		mc.SupportingAppUrl, mc.UpdatedAt, mc.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update master course: %w", err)
	}
	return nil
}

// Delete menghapus MasterCourse berdasarkan ID dari database.
func (r *MasterCourseRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM master_courses WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete master course: %w", err)
	}
	return nil
}

// GetByID mengambil satu MasterCourse berdasarkan ID.
func (r *MasterCourseRepository) GetByID(ctx context.Context, id uuid.UUID) (*mastercourse.MasterCourse, error) {
	var rec masterCourseRecord
	query := `SELECT id, course_code, course_name, field, core_competencies, description, status, supporting_app_url, created_at, updated_at FROM master_courses WHERE id = $1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get master course by id: %w", err)
	}
	return rec.toDomain()
}

// GetByCode mengambil satu MasterCourse berdasarkan course_code.
func (r *MasterCourseRepository) GetByCode(ctx context.Context, code string) (*mastercourse.MasterCourse, error) {
	var rec masterCourseRecord
	query := `SELECT id, course_code, course_name, field, core_competencies, description, status, supporting_app_url, created_at, updated_at FROM master_courses WHERE course_code = $1`
	if err := r.db.GetContext(ctx, &rec, query, code); err != nil {
		return nil, fmt.Errorf("failed to get master course by code: %w", err)
	}
	return rec.toDomain()
}

// List mengambil daftar MasterCourse dengan pagination dan filter opsional berdasarkan status dan field.
// Filter status dan field dilewati jika nilai kosong ("").
func (r *MasterCourseRepository) List(ctx context.Context, offset, limit int, status, field string) ([]*mastercourse.MasterCourse, int, error) {
	// Bangun kondisi WHERE secara dinamis
	conditions := []string{}
	args := []interface{}{}
	argIdx := 1

	if status != "" {
		conditions = append(conditions, fmt.Sprintf("status = $%d", argIdx))
		args = append(args, status)
		argIdx++
	}
	if field != "" {
		conditions = append(conditions, fmt.Sprintf("field = $%d", argIdx))
		args = append(args, field)
		argIdx++
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Hitung total
	var total int
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM master_courses %s", whereClause)
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count master courses: %w", err)
	}

	// Ambil data dengan pagination
	listArgs := append(args, limit, offset)
	selectQuery := fmt.Sprintf(
		`SELECT id, course_code, course_name, field, core_competencies, description, status, supporting_app_url, created_at, updated_at
		 FROM master_courses %s ORDER BY created_at DESC LIMIT $%d OFFSET $%d`,
		whereClause, argIdx, argIdx+1,
	)
	var recs []masterCourseRecord
	if err := r.db.SelectContext(ctx, &recs, selectQuery, listArgs...); err != nil {
		return nil, 0, fmt.Errorf("failed to list master courses: %w", err)
	}

	courses := make([]*mastercourse.MasterCourse, 0, len(recs))
	for _, rec := range recs {
		mc, err := rec.toDomain()
		if err != nil {
			return nil, 0, err
		}
		courses = append(courses, mc)
	}
	return courses, total, nil
}

// ListBatchesByMasterCourse mengambil batches yang terhubung ke master_course_id.
func (r *MasterCourseRepository) ListBatchesByMasterCourse(ctx context.Context, masterCourseID uuid.UUID) ([]*BatchRecord, error) {
	query := `
		SELECT cb.id, cb.name, cb.start_date, cb.end_date,
		       COALESCE(cb.status, 'upcoming') as status,
		       cb.max_participants,
		       COALESCE(cb.session_count, 0) as session_count,
		       COALESCE(cb.location, '') as location,
		       COUNT(e.id) as enrollment_count
		FROM course_batches cb
		LEFT JOIN enrollments e ON e.course_batch_id = cb.id
		WHERE cb.master_course_id = $1
		GROUP BY cb.id
		ORDER BY cb.start_date DESC
	`
	var recs []*BatchRecord
	if err := r.db.SelectContext(ctx, &recs, query, masterCourseID); err != nil {
		return nil, fmt.Errorf("failed to list batches by master course: %w", err)
	}
	return recs, nil
}

// ListStudentsByMasterCourse mengambil students yang pernah enroll ke batch master course ini.
func (r *MasterCourseRepository) ListStudentsByMasterCourse(ctx context.Context, masterCourseID uuid.UUID) ([]*StudentRecord, error) {
	query := `
		SELECT DISTINCT ON (s.id) s.id, s.name, s.email, s.phone,
		       cb.name as batch_name,
		       e.status as enroll_status,
		       e.payment_status,
		       e.enrolled_at
		FROM students s
		JOIN enrollments e ON e.student_id = s.id
		JOIN course_batches cb ON cb.id = e.course_batch_id
		WHERE cb.master_course_id = $1
		ORDER BY s.id, e.enrolled_at DESC
	`
	var recs []*StudentRecord
	if err := r.db.SelectContext(ctx, &recs, query, masterCourseID); err != nil {
		return nil, fmt.Errorf("failed to list students by master course: %w", err)
	}
	return recs, nil
}
