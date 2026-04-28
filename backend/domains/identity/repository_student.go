package identity

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// ─── Moved from repository.go ────────────────────────────────────────────────

func (r *repository) CreateStudent(ctx context.Context, s *Student) error {
	query := `
		INSERT INTO identity.students (id, user_id, name, email, phone, source, partner_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		s.ID, s.UserID, s.Name, s.Email, s.Phone, s.Source, s.PartnerID,
	).Scan(&s.CreatedAt, &s.UpdatedAt)
	if err != nil {
		return fmt.Errorf("identity.CreateStudent: %w", err)
	}
	return nil
}

func (r *repository) GetStudentByID(ctx context.Context, id uuid.UUID) (*Student, error) {
	query := `SELECT id, user_id, name, email, phone, source, partner_id, created_at, updated_at
	          FROM identity.students WHERE id = $1`

	s := &Student{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&s.ID, &s.UserID, &s.Name, &s.Email, &s.Phone, &s.Source, &s.PartnerID,
		&s.CreatedAt, &s.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("identity.GetStudentByID: %w", err)
	}
	return s, nil
}

func (r *repository) GetStudentByUserID(ctx context.Context, userID uuid.UUID) (*Student, error) {
	query := `SELECT id, user_id, name, email, phone, source, partner_id, created_at, updated_at
	          FROM identity.students WHERE user_id = $1`

	s := &Student{}
	err := r.pool.QueryRow(ctx, query, userID).Scan(
		&s.ID, &s.UserID, &s.Name, &s.Email, &s.Phone, &s.Source, &s.PartnerID,
		&s.CreatedAt, &s.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("identity.GetStudentByUserID: %w", err)
	}
	return s, nil
}

// ─── New implementations (stubs — filled in Task 4) ─────────────────────────

func (r *repository) ListStudentsFiltered(ctx context.Context, f StudentFilter) ([]*Student, error) {
	where, args := buildStudentWhere(f)

	col := studentSortCol(f.SortBy)
	dir := "DESC"
	if strings.EqualFold(f.SortDir, "asc") {
		dir = "ASC"
	}

	n := len(args) + 1
	query := fmt.Sprintf(`
		SELECT s.id, s.user_id, s.name, s.email, s.phone, s.source, s.partner_id, s.created_at, s.updated_at
		FROM identity.students s
		LEFT JOIN identity.student_profiles p ON p.student_id = s.id
		%s
		ORDER BY %s %s
		LIMIT $%d OFFSET $%d`,
		studentWhereClause(where), col, dir, n, n+1)

	args = append(args, f.Limit, f.Offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("identity.ListStudentsFiltered: %w", err)
	}
	defer rows.Close()

	var students []*Student
	for rows.Next() {
		s := &Student{}
		if err := rows.Scan(
			&s.ID, &s.UserID, &s.Name, &s.Email, &s.Phone, &s.Source,
			&s.PartnerID, &s.CreatedAt, &s.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("identity.ListStudentsFiltered scan: %w", err)
		}
		students = append(students, s)
	}
	return students, rows.Err()
}

func (r *repository) CountStudentsFiltered(ctx context.Context, f StudentFilter) (int, error) {
	where, args := buildStudentWhere(f)

	query := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM identity.students s
		LEFT JOIN identity.student_profiles p ON p.student_id = s.id
		%s`, studentWhereClause(where))

	var count int
	if err := r.pool.QueryRow(ctx, query, args...).Scan(&count); err != nil {
		return 0, fmt.Errorf("identity.CountStudentsFiltered: %w", err)
	}
	return count, nil
}

func (r *repository) UpdateStudent(ctx context.Context, s *Student) error {
	query := `
		UPDATE identity.students
		SET name=$1, email=$2, phone=$3, source=$4, partner_id=$5
		WHERE id=$6 RETURNING updated_at`

	err := r.pool.QueryRow(ctx, query,
		s.Name, s.Email, s.Phone, s.Source, s.PartnerID, s.ID,
	).Scan(&s.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("identity.UpdateStudent: %w", err)
	}
	return nil
}

func (r *repository) CreateStudentProfile(ctx context.Context, p *StudentProfile) error {
	query := `
		INSERT INTO identity.student_profiles
		  (id, student_id, date_of_birth, gender, id_type, id_number,
		   address, city, province, postal_code, profile_complete)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		p.ID, p.StudentID, p.DateOfBirth, p.Gender, p.IDType, p.IDNumber,
		p.Address, p.City, p.Province, p.PostalCode, p.ProfileComplete,
	).Scan(&p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		return fmt.Errorf("identity.CreateStudentProfile: %w", err)
	}
	return nil
}

func (r *repository) GetStudentProfile(ctx context.Context, studentID uuid.UUID) (*StudentProfile, error) {
	query := `
		SELECT id, student_id, date_of_birth, gender, id_type, id_number,
		       address, city, province, postal_code, profile_complete, created_at, updated_at
		FROM identity.student_profiles WHERE student_id = $1`

	p := &StudentProfile{}
	err := r.pool.QueryRow(ctx, query, studentID).Scan(
		&p.ID, &p.StudentID, &p.DateOfBirth, &p.Gender, &p.IDType, &p.IDNumber,
		&p.Address, &p.City, &p.Province, &p.PostalCode, &p.ProfileComplete,
		&p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("identity.GetStudentProfile: %w", err)
	}
	return p, nil
}

func (r *repository) UpdateStudentProfile(ctx context.Context, p *StudentProfile) error {
	query := `
		UPDATE identity.student_profiles
		SET date_of_birth=$1, gender=$2, id_type=$3, id_number=$4,
		    address=$5, city=$6, province=$7, postal_code=$8, profile_complete=$9
		WHERE student_id=$10 RETURNING updated_at`

	err := r.pool.QueryRow(ctx, query,
		p.DateOfBirth, p.Gender, p.IDType, p.IDNumber,
		p.Address, p.City, p.Province, p.PostalCode, p.ProfileComplete,
		p.StudentID,
	).Scan(&p.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("identity.UpdateStudentProfile: %w", err)
	}
	return nil
}

// ─── Query helpers ───────────────────────────────────────────────────────────

func buildStudentWhere(f StudentFilter) ([]string, []interface{}) {
	var where []string
	var args []interface{}
	n := 1

	if f.Source != nil {
		where = append(where, fmt.Sprintf("s.source = $%d", n))
		args = append(args, *f.Source)
		n++
	}
	if f.PartnerID != nil {
		where = append(where, fmt.Sprintf("s.partner_id = $%d", n))
		args = append(args, *f.PartnerID)
		n++
	}
	if f.Search != "" {
		where = append(where, fmt.Sprintf("(s.name ILIKE $%d OR s.email ILIKE $%d)", n, n+1))
		args = append(args, "%"+f.Search+"%", "%"+f.Search+"%")
		n += 2
	}
	if f.ProfileComplete != nil {
		where = append(where, fmt.Sprintf("p.profile_complete = $%d", n))
		args = append(args, *f.ProfileComplete)
		n++
	}
	_ = n
	return where, args
}

func studentWhereClause(where []string) string {
	if len(where) == 0 {
		return ""
	}
	return "WHERE " + strings.Join(where, " AND ")
}

func studentSortCol(sortBy string) string {
	switch sortBy {
	case "name":
		return "s.name"
	case "email":
		return "s.email"
	default:
		return "s.created_at"
	}
}
