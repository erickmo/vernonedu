package identity

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// Repository defines identity domain data access.
type Repository interface {
	CreateUser(ctx context.Context, user *User) error
	GetUserByID(ctx context.Context, id uuid.UUID) (*User, error)
	GetUserByEmail(ctx context.Context, email string) (*User, error)
	UpdateUser(ctx context.Context, user *User) error
	DeactivateUser(ctx context.Context, id uuid.UUID) error

	CreateStudent(ctx context.Context, s *Student) error
	GetStudentByID(ctx context.Context, id uuid.UUID) (*Student, error)
	GetStudentByUserID(ctx context.Context, userID uuid.UUID) (*Student, error)
	ListStudentsFiltered(ctx context.Context, f StudentFilter) ([]*Student, error)
	CountStudentsFiltered(ctx context.Context, f StudentFilter) (int, error)
	UpdateStudent(ctx context.Context, s *Student) error
	CreateStudentProfile(ctx context.Context, p *StudentProfile) error
	GetStudentProfile(ctx context.Context, studentID uuid.UUID) (*StudentProfile, error)
	UpdateStudentProfile(ctx context.Context, p *StudentProfile) error

	CreateTeamMember(ctx context.Context, tm *TeamMember) error
	GetTeamMemberByID(ctx context.Context, id uuid.UUID) (*TeamMember, error)
	UpdateTeamMemberStatus(ctx context.Context, id uuid.UUID, status EmploymentStatus) error

	CreateDepartment(ctx context.Context, dept *Department) error
	GetDepartmentByID(ctx context.Context, id uuid.UUID) (*Department, error)
	ListDepartments(ctx context.Context) ([]*Department, error)

	CreateFacilitatorProposal(ctx context.Context, p *FacilitatorProposal) error
	GetFacilitatorProposalByID(ctx context.Context, id uuid.UUID) (*FacilitatorProposal, error)
	UpdateFacilitatorProposal(ctx context.Context, p *FacilitatorProposal) error
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository creates an identity repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

func (r *repository) CreateUser(ctx context.Context, user *User) error {
	query := `
		INSERT INTO identity.users (id, email, password_hash, role, is_active, device_push_token)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		user.ID, user.Email, user.PasswordHash, user.Role, user.IsActive, user.DevicePushToken,
	).Scan(&user.CreatedAt, &user.UpdatedAt)
	if err != nil {
		return fmt.Errorf("identity.CreateUser: %w", err)
	}
	return nil
}

func (r *repository) GetUserByID(ctx context.Context, id uuid.UUID) (*User, error) {
	query := `SELECT id, email, password_hash, role, is_active, device_push_token, created_at, updated_at
	          FROM identity.users WHERE id = $1`

	user := &User{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.Email, &user.PasswordHash, &user.Role,
		&user.IsActive, &user.DevicePushToken, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("identity.GetUserByID: %w", err)
	}
	return user, nil
}

func (r *repository) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	query := `SELECT id, email, password_hash, role, is_active, device_push_token, created_at, updated_at
	          FROM identity.users WHERE email = $1`

	user := &User{}
	err := r.pool.QueryRow(ctx, query, email).Scan(
		&user.ID, &user.Email, &user.PasswordHash, &user.Role,
		&user.IsActive, &user.DevicePushToken, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("identity.GetUserByEmail: %w", err)
	}
	return user, nil
}

func (r *repository) UpdateUser(ctx context.Context, user *User) error {
	query := `UPDATE identity.users SET email=$1, role=$2, is_active=$3, device_push_token=$4
	          WHERE id=$5 RETURNING updated_at`

	err := r.pool.QueryRow(ctx, query,
		user.Email, user.Role, user.IsActive, user.DevicePushToken, user.ID,
	).Scan(&user.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("identity.UpdateUser: %w", err)
	}
	return nil
}

func (r *repository) DeactivateUser(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE identity.users SET is_active=false WHERE id=$1`
	ct, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("identity.DeactivateUser: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) CreateTeamMember(ctx context.Context, tm *TeamMember) error {
	query := `
		INSERT INTO identity.team_members (id, user_id, full_name, phone, department_id, role, employment_status, joined_at, is_facilitator)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		tm.ID, tm.UserID, tm.FullName, tm.Phone, tm.DepartmentID,
		tm.Role, tm.EmploymentStatus, tm.JoinedAt, tm.IsFacilitator,
	).Scan(&tm.CreatedAt, &tm.UpdatedAt)
	if err != nil {
		return fmt.Errorf("identity.CreateTeamMember: %w", err)
	}
	return nil
}

func (r *repository) GetTeamMemberByID(ctx context.Context, id uuid.UUID) (*TeamMember, error) {
	query := `SELECT id, user_id, full_name, phone, department_id, role, employment_status, joined_at, is_facilitator, created_at, updated_at
	          FROM identity.team_members WHERE id = $1`

	tm := &TeamMember{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&tm.ID, &tm.UserID, &tm.FullName, &tm.Phone, &tm.DepartmentID,
		&tm.Role, &tm.EmploymentStatus, &tm.JoinedAt, &tm.IsFacilitator,
		&tm.CreatedAt, &tm.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("identity.GetTeamMemberByID: %w", err)
	}
	return tm, nil
}

func (r *repository) UpdateTeamMemberStatus(ctx context.Context, id uuid.UUID, status EmploymentStatus) error {
	query := `UPDATE identity.team_members SET employment_status=$1 WHERE id=$2`
	ct, err := r.pool.Exec(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("identity.UpdateTeamMemberStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) CreateDepartment(ctx context.Context, dept *Department) error {
	query := `
		INSERT INTO identity.departments (id, name, leader_id, is_active, created_by)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		dept.ID, dept.Name, dept.LeaderID, dept.IsActive, dept.CreatedBy,
	).Scan(&dept.CreatedAt, &dept.UpdatedAt)
	if err != nil {
		return fmt.Errorf("identity.CreateDepartment: %w", err)
	}
	return nil
}

func (r *repository) GetDepartmentByID(ctx context.Context, id uuid.UUID) (*Department, error) {
	query := `SELECT id, name, leader_id, is_active, created_by, created_at, updated_at
	          FROM identity.departments WHERE id = $1`

	d := &Department{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&d.ID, &d.Name, &d.LeaderID, &d.IsActive, &d.CreatedBy, &d.CreatedAt, &d.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("identity.GetDepartmentByID: %w", err)
	}
	return d, nil
}

func (r *repository) ListDepartments(ctx context.Context) ([]*Department, error) {
	query := `SELECT id, name, leader_id, is_active, created_by, created_at, updated_at
	          FROM identity.departments WHERE is_active=true ORDER BY name`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("identity.ListDepartments: %w", err)
	}
	defer rows.Close()

	var depts []*Department
	for rows.Next() {
		d := &Department{}
		if err := rows.Scan(&d.ID, &d.Name, &d.LeaderID, &d.IsActive, &d.CreatedBy, &d.CreatedAt, &d.UpdatedAt); err != nil {
			return nil, fmt.Errorf("identity.ListDepartments scan: %w", err)
		}
		depts = append(depts, d)
	}
	return depts, rows.Err()
}

func (r *repository) CreateFacilitatorProposal(ctx context.Context, p *FacilitatorProposal) error {
	query := `
		INSERT INTO identity.facilitator_proposals
		  (id, course_id, proposed_by, facilitator_id, fee_tier_id, fee_basis,
		   dept_leader_status, academic_leader_status, final_status)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		p.ID, p.CourseID, p.ProposedBy, p.FacilitatorID, p.FeeTierID, p.FeeBasis,
		ProposalPending, ProposalPending, ProposalPending,
	).Scan(&p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		return fmt.Errorf("identity.CreateFacilitatorProposal: %w", err)
	}
	return nil
}

func (r *repository) GetFacilitatorProposalByID(ctx context.Context, id uuid.UUID) (*FacilitatorProposal, error) {
	query := `
		SELECT id, course_id, proposed_by, facilitator_id, fee_tier_id, fee_basis,
		       dept_leader_status, dept_leader_reviewed_at, dept_leader_note,
		       academic_leader_status, academic_leader_reviewed_at, academic_leader_note,
		       final_status, created_at, updated_at
		FROM identity.facilitator_proposals WHERE id = $1`

	p := &FacilitatorProposal{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&p.ID, &p.CourseID, &p.ProposedBy, &p.FacilitatorID, &p.FeeTierID, &p.FeeBasis,
		&p.DeptLeaderStatus, &p.DeptLeaderReviewedAt, &p.DeptLeaderNote,
		&p.AcademicLeaderStatus, &p.AcademicLeaderReviewedAt, &p.AcademicLeaderNote,
		&p.FinalStatus, &p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("identity.GetFacilitatorProposalByID: %w", err)
	}
	return p, nil
}

func (r *repository) UpdateFacilitatorProposal(ctx context.Context, p *FacilitatorProposal) error {
	now := time.Now()
	query := `
		UPDATE identity.facilitator_proposals SET
		  dept_leader_status=$1, dept_leader_reviewed_at=$2, dept_leader_note=$3,
		  academic_leader_status=$4, academic_leader_reviewed_at=$5, academic_leader_note=$6,
		  final_status=$7
		WHERE id=$8 RETURNING updated_at`

	err := r.pool.QueryRow(ctx, query,
		p.DeptLeaderStatus, p.DeptLeaderReviewedAt, p.DeptLeaderNote,
		p.AcademicLeaderStatus, p.AcademicLeaderReviewedAt, p.AcademicLeaderNote,
		p.FinalStatus, p.ID,
	).Scan(&now)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("identity.UpdateFacilitatorProposal: %w", err)
	}
	p.UpdatedAt = now
	return nil
}
