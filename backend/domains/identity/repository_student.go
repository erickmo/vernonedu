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

func (r *repository) ListStudentsFiltered(_ context.Context, _ StudentFilter) ([]*Student, error) {
	return nil, nil
}

func (r *repository) CountStudentsFiltered(_ context.Context, _ StudentFilter) (int, error) {
	return 0, nil
}

func (r *repository) UpdateStudent(_ context.Context, _ *Student) error {
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

func (r *repository) UpdateStudentProfile(_ context.Context, _ *StudentProfile) error {
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
