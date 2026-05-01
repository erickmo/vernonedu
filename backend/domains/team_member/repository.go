package team_member

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// Repository defines team_member data access.
type Repository interface {
	// TeamMember
	CreateTeamMember(ctx context.Context, m *TeamMember) error
	GetTeamMemberByID(ctx context.Context, id uuid.UUID) (*TeamMember, error)
	ListTeamMembers(ctx context.Context) ([]*TeamMember, error)

	// FacilitatorProfile
	CreateFacilitatorProfile(ctx context.Context, p *FacilitatorProfile) error
	GetFacilitatorProfileByMemberID(ctx context.Context, memberID uuid.UUID) (*FacilitatorProfile, error)

	// FeeTier
	CreateFeeTier(ctx context.Context, t *FeeTier) error
	GetFeeTierByID(ctx context.Context, id uuid.UUID) (*FeeTier, error)
	ListFeeTiers(ctx context.Context) ([]*FeeTier, error)

	// FacilitatorProposal
	CreateProposal(ctx context.Context, p *FacilitatorProposal) error
	GetProposalByID(ctx context.Context, id uuid.UUID) (*FacilitatorProposal, error)
	UpdateProposalDeptReview(ctx context.Context, id uuid.UUID, status ReviewStatus, note *string) error
	UpdateProposalAcademicReview(ctx context.Context, id uuid.UUID, status ReviewStatus, note *string) error
	UpdateProposalFinalStatus(ctx context.Context, id uuid.UUID, status ReviewStatus) error

	// Cross-checks
	GetUserRole(ctx context.Context, userID uuid.UUID) (string, error)
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository constructs a team_member repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

// ── TeamMember ────────────────────────────────────────────────

func (r *repository) CreateTeamMember(ctx context.Context, m *TeamMember) error {
	query := `
		INSERT INTO team_member.team_members
		  (id, user_id, full_name, phone, department_id, employment_status, joined_at, is_facilitator)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		m.ID, m.UserID, m.FullName, m.Phone, m.DepartmentID,
		m.EmploymentStatus, m.JoinedAt, m.IsFacilitator,
	).Scan(&m.CreatedAt, &m.UpdatedAt)
	if err != nil {
		return fmt.Errorf("team_member.CreateTeamMember: %w", err)
	}
	return nil
}

func (r *repository) GetTeamMemberByID(ctx context.Context, id uuid.UUID) (*TeamMember, error) {
	query := `
		SELECT id, user_id, full_name, phone, department_id, employment_status,
		       joined_at, is_facilitator, created_at, updated_at
		FROM team_member.team_members WHERE id = $1`

	m := &TeamMember{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&m.ID, &m.UserID, &m.FullName, &m.Phone, &m.DepartmentID,
		&m.EmploymentStatus, &m.JoinedAt, &m.IsFacilitator, &m.CreatedAt, &m.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("team_member.GetTeamMemberByID: %w", err)
	}
	return m, nil
}

func (r *repository) ListTeamMembers(ctx context.Context) ([]*TeamMember, error) {
	query := `
		SELECT id, user_id, full_name, phone, department_id, employment_status,
		       joined_at, is_facilitator, created_at, updated_at
		FROM team_member.team_members ORDER BY full_name ASC`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("team_member.ListTeamMembers: %w", err)
	}
	defer rows.Close()

	var members []*TeamMember
	for rows.Next() {
		m := &TeamMember{}
		if err := rows.Scan(
			&m.ID, &m.UserID, &m.FullName, &m.Phone, &m.DepartmentID,
			&m.EmploymentStatus, &m.JoinedAt, &m.IsFacilitator, &m.CreatedAt, &m.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("team_member.ListTeamMembers scan: %w", err)
		}
		members = append(members, m)
	}
	return members, rows.Err()
}

// ── FacilitatorProfile ────────────────────────────────────────

func (r *repository) CreateFacilitatorProfile(ctx context.Context, p *FacilitatorProfile) error {
	query := `
		INSERT INTO team_member.facilitator_profiles (id, team_member_id, specialization, bio)
		VALUES ($1,$2,$3,$4)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query, p.ID, p.TeamMemberID, p.Specialization, p.Bio).
		Scan(&p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		return fmt.Errorf("team_member.CreateFacilitatorProfile: %w", err)
	}
	return nil
}

func (r *repository) GetFacilitatorProfileByMemberID(ctx context.Context, memberID uuid.UUID) (*FacilitatorProfile, error) {
	query := `
		SELECT id, team_member_id, specialization, bio, created_at, updated_at
		FROM team_member.facilitator_profiles WHERE team_member_id = $1`

	p := &FacilitatorProfile{}
	err := r.pool.QueryRow(ctx, query, memberID).Scan(
		&p.ID, &p.TeamMemberID, &p.Specialization, &p.Bio, &p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("team_member.GetFacilitatorProfileByMemberID: %w", err)
	}
	return p, nil
}

// ── FeeTier ───────────────────────────────────────────────────

func (r *repository) CreateFeeTier(ctx context.Context, t *FeeTier) error {
	query := `
		INSERT INTO team_member.fee_tiers
		  (id, name, amount_per_class, amount_per_course, is_active, created_by)
		VALUES ($1,$2,$3,$4,$5,$6)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		t.ID, t.Name, t.AmountPerClass, t.AmountPerCourse, t.IsActive, t.CreatedBy,
	).Scan(&t.CreatedAt, &t.UpdatedAt)
	if err != nil {
		return fmt.Errorf("team_member.CreateFeeTier: %w", err)
	}
	return nil
}

func (r *repository) GetFeeTierByID(ctx context.Context, id uuid.UUID) (*FeeTier, error) {
	query := `
		SELECT id, name, amount_per_class, amount_per_course, is_active, created_by, created_at, updated_at
		FROM team_member.fee_tiers WHERE id = $1`

	t := &FeeTier{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&t.ID, &t.Name, &t.AmountPerClass, &t.AmountPerCourse,
		&t.IsActive, &t.CreatedBy, &t.CreatedAt, &t.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("team_member.GetFeeTierByID: %w", err)
	}
	return t, nil
}

func (r *repository) ListFeeTiers(ctx context.Context) ([]*FeeTier, error) {
	query := `
		SELECT id, name, amount_per_class, amount_per_course, is_active, created_by, created_at, updated_at
		FROM team_member.fee_tiers ORDER BY name ASC`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("team_member.ListFeeTiers: %w", err)
	}
	defer rows.Close()

	var tiers []*FeeTier
	for rows.Next() {
		t := &FeeTier{}
		if err := rows.Scan(
			&t.ID, &t.Name, &t.AmountPerClass, &t.AmountPerCourse,
			&t.IsActive, &t.CreatedBy, &t.CreatedAt, &t.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("team_member.ListFeeTiers scan: %w", err)
		}
		tiers = append(tiers, t)
	}
	return tiers, rows.Err()
}

// ── FacilitatorProposal ───────────────────────────────────────

func (r *repository) CreateProposal(ctx context.Context, p *FacilitatorProposal) error {
	query := `
		INSERT INTO team_member.facilitator_proposals
		  (id, course_id, proposed_by, facilitator_id, fee_tier_id, fee_basis,
		   dept_leader_status, academic_leader_status, final_status)
		VALUES ($1,$2,$3,$4,$5,$6,'pending','pending','pending')
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		p.ID, p.CourseID, p.ProposedBy, p.FacilitatorID, p.FeeTierID, p.FeeBasis,
	).Scan(&p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		return fmt.Errorf("team_member.CreateProposal: %w", err)
	}
	p.DeptLeaderStatus = ReviewPending
	p.AcademicLeaderStatus = ReviewPending
	p.FinalStatus = ReviewPending
	return nil
}

func (r *repository) GetProposalByID(ctx context.Context, id uuid.UUID) (*FacilitatorProposal, error) {
	query := `
		SELECT id, course_id, proposed_by, facilitator_id, fee_tier_id, fee_basis,
		       dept_leader_status, dept_leader_reviewed_at, dept_leader_note,
		       academic_leader_status, academic_leader_reviewed_at, academic_leader_note,
		       final_status, created_at, updated_at
		FROM team_member.facilitator_proposals WHERE id = $1`

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
		return nil, fmt.Errorf("team_member.GetProposalByID: %w", err)
	}
	return p, nil
}

func (r *repository) UpdateProposalDeptReview(ctx context.Context, id uuid.UUID, status ReviewStatus, note *string) error {
	query := `
		UPDATE team_member.facilitator_proposals
		SET dept_leader_status = $1, dept_leader_reviewed_at = now(), dept_leader_note = $2
		WHERE id = $3`
	ct, err := r.pool.Exec(ctx, query, status, note, id)
	if err != nil {
		return fmt.Errorf("team_member.UpdateProposalDeptReview: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) UpdateProposalAcademicReview(ctx context.Context, id uuid.UUID, status ReviewStatus, note *string) error {
	query := `
		UPDATE team_member.facilitator_proposals
		SET academic_leader_status = $1, academic_leader_reviewed_at = now(), academic_leader_note = $2
		WHERE id = $3`
	ct, err := r.pool.Exec(ctx, query, status, note, id)
	if err != nil {
		return fmt.Errorf("team_member.UpdateProposalAcademicReview: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) UpdateProposalFinalStatus(ctx context.Context, id uuid.UUID, status ReviewStatus) error {
	query := `UPDATE team_member.facilitator_proposals SET final_status = $1 WHERE id = $2`
	ct, err := r.pool.Exec(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("team_member.UpdateProposalFinalStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) GetUserRole(ctx context.Context, userID uuid.UUID) (string, error) {
	var role string
	err := r.pool.QueryRow(ctx, `SELECT role FROM identity.users WHERE id = $1`, userID).Scan(&role)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", apperrors.ErrNotFound
		}
		return "", fmt.Errorf("team_member.GetUserRole: %w", err)
	}
	return role, nil
}
