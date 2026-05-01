package team_member

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

const (
	roleVernonAdmin  = "vernonedu_admin"
	roleCourseCreator = "course_creator"
)

// Service holds team_member business logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs team_member Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

// ── CreateMemberInput ─────────────────────────────────────────

// CreateMemberInput carries parameters for creating a TeamMember.
type CreateMemberInput struct {
	UserID           uuid.UUID
	FullName         string
	Phone            string
	DepartmentID     *uuid.UUID
	EmploymentStatus EmploymentStatus
	JoinedAt         time.Time
	IsFacilitator    bool
	Specialization   string
	Bio              string
}

// CreateTeamMember creates a new TeamMember and optionally a FacilitatorProfile.
func (s *Service) CreateTeamMember(ctx context.Context, in CreateMemberInput) (*TeamMember, error) {
	if in.FullName == "" {
		return nil, apperrors.Validationf("full_name is required")
	}
	if in.Phone == "" {
		return nil, apperrors.Validationf("phone is required")
	}

	m := &TeamMember{
		ID:               uuid.New(),
		UserID:           in.UserID,
		FullName:         in.FullName,
		Phone:            in.Phone,
		DepartmentID:     in.DepartmentID,
		EmploymentStatus: in.EmploymentStatus,
		JoinedAt:         in.JoinedAt,
		IsFacilitator:    in.IsFacilitator,
	}
	if m.EmploymentStatus == "" {
		m.EmploymentStatus = StatusActive
	}

	if err := s.repo.CreateTeamMember(ctx, m); err != nil {
		return nil, err
	}

	if in.IsFacilitator {
		if in.Specialization == "" {
			return nil, apperrors.Validationf("specialization required for facilitators")
		}
		profile := &FacilitatorProfile{
			ID:             uuid.New(),
			TeamMemberID:   m.ID,
			Specialization: in.Specialization,
			Bio:            in.Bio,
		}
		if err := s.repo.CreateFacilitatorProfile(ctx, profile); err != nil {
			return nil, err
		}
	}

	return m, nil
}

// GetTeamMember fetches a TeamMember by ID.
func (s *Service) GetTeamMember(ctx context.Context, id uuid.UUID) (*TeamMember, error) {
	return s.repo.GetTeamMemberByID(ctx, id)
}

// ListTeamMembers returns all team members.
func (s *Service) ListTeamMembers(ctx context.Context) ([]*TeamMember, error) {
	return s.repo.ListTeamMembers(ctx)
}

// ── FeeTier ───────────────────────────────────────────────────

// CreateFeeTierInput carries fee tier creation parameters.
type CreateFeeTierInput struct {
	Name            string
	AmountPerClass  *decimal.Decimal
	AmountPerCourse *decimal.Decimal
	CreatedBy       uuid.UUID
}

// CreateFeeTier creates a new FeeTier (admin only — caller must enforce).
func (s *Service) CreateFeeTier(ctx context.Context, in CreateFeeTierInput) (*FeeTier, error) {
	if in.Name == "" {
		return nil, apperrors.Validationf("name is required")
	}
	if in.AmountPerClass == nil && in.AmountPerCourse == nil {
		return nil, apperrors.Validationf("at least one of amount_per_class or amount_per_course is required")
	}

	t := &FeeTier{
		ID:              uuid.New(),
		Name:            in.Name,
		AmountPerClass:  in.AmountPerClass,
		AmountPerCourse: in.AmountPerCourse,
		IsActive:        true,
		CreatedBy:       in.CreatedBy,
	}
	if err := s.repo.CreateFeeTier(ctx, t); err != nil {
		return nil, err
	}
	return t, nil
}

// ListFeeTiers returns all fee tiers.
func (s *Service) ListFeeTiers(ctx context.Context) ([]*FeeTier, error) {
	return s.repo.ListFeeTiers(ctx)
}

// ── FacilitatorProposal ───────────────────────────────────────

// CreateProposalInput carries proposal creation parameters.
type CreateProposalInput struct {
	CourseID      uuid.UUID
	ProposedByID  uuid.UUID // team_member.id of proposer
	ProposerUserID uuid.UUID // identity.users.id of proposer (for role check)
	FacilitatorID uuid.UUID
	FeeTierID     uuid.UUID
	FeeBasis      FeeBasis
}

// CreateProposal validates business rules and persists a new proposal.
func (s *Service) CreateProposal(ctx context.Context, in CreateProposalInput) (*FacilitatorProposal, error) {
	role, err := s.repo.GetUserRole(ctx, in.ProposerUserID)
	if err != nil {
		return nil, err
	}
	if role != roleCourseCreator {
		return nil, apperrors.ErrForbidden
	}

	facilitator, err := s.repo.GetTeamMemberByID(ctx, in.FacilitatorID)
	if err != nil {
		return nil, apperrors.Validationf("facilitator not found")
	}
	if !facilitator.IsFacilitator {
		return nil, apperrors.Validationf("team member is not a facilitator")
	}
	if facilitator.EmploymentStatus != StatusActive {
		return nil, apperrors.Validationf("facilitator is not active")
	}

	tier, err := s.repo.GetFeeTierByID(ctx, in.FeeTierID)
	if err != nil {
		return nil, apperrors.Validationf("fee tier not found")
	}
	if !tier.IsActive {
		return nil, apperrors.Validationf("fee tier is not active")
	}

	p := &FacilitatorProposal{
		ID:            uuid.New(),
		CourseID:      in.CourseID,
		ProposedBy:    in.ProposedByID,
		FacilitatorID: in.FacilitatorID,
		FeeTierID:     in.FeeTierID,
		FeeBasis:      in.FeeBasis,
	}
	if err := s.repo.CreateProposal(ctx, p); err != nil {
		return nil, err
	}
	return p, nil
}

// GetProposal fetches a proposal by ID.
func (s *Service) GetProposal(ctx context.Context, id uuid.UUID) (*FacilitatorProposal, error) {
	return s.repo.GetProposalByID(ctx, id)
}

// ReviewInput carries review parameters.
type ReviewInput struct {
	ProposalID uuid.UUID
	Status     ReviewStatus
	Note       *string
}

// DeptLeaderReview applies the dept leader's decision to a proposal.
func (s *Service) DeptLeaderReview(ctx context.Context, in ReviewInput) error {
	p, err := s.repo.GetProposalByID(ctx, in.ProposalID)
	if err != nil {
		return err
	}
	if p.DeptLeaderStatus != ReviewPending {
		return apperrors.Validationf("proposal already reviewed by dept leader")
	}

	if err := s.repo.UpdateProposalDeptReview(ctx, in.ProposalID, in.Status, in.Note); err != nil {
		return err
	}

	if in.Status == ReviewRejected {
		if err := s.repo.UpdateProposalFinalStatus(ctx, in.ProposalID, ReviewRejected); err != nil {
			return err
		}
		s.publishRejected(ctx, p)
	}
	return nil
}

// AcademicLeaderReview applies the academic leader's decision; dept must be approved first.
func (s *Service) AcademicLeaderReview(ctx context.Context, in ReviewInput) error {
	p, err := s.repo.GetProposalByID(ctx, in.ProposalID)
	if err != nil {
		return err
	}
	if p.DeptLeaderStatus != ReviewApproved {
		return apperrors.Validationf("dept leader must approve before academic leader review")
	}
	if p.AcademicLeaderStatus != ReviewPending {
		return apperrors.Validationf("proposal already reviewed by academic leader")
	}

	if err := s.repo.UpdateProposalAcademicReview(ctx, in.ProposalID, in.Status, in.Note); err != nil {
		return err
	}

	finalStatus := in.Status
	if err := s.repo.UpdateProposalFinalStatus(ctx, in.ProposalID, finalStatus); err != nil {
		return err
	}

	if finalStatus == ReviewApproved {
		s.publishApproved(ctx, p)
	} else {
		s.publishRejected(ctx, p)
	}
	return nil
}

func (s *Service) publishApproved(ctx context.Context, p *FacilitatorProposal) {
	err := s.bus.Publish(ctx, events.Event{
		Type: EventProposalApproved,
		Payload: ProposalApprovedPayload{
			ProposalID:    p.ID,
			CourseID:      p.CourseID,
			FacilitatorID: p.FacilitatorID,
			FeeTierID:     p.FeeTierID,
			FeeBasis:      p.FeeBasis,
		},
	})
	if err != nil {
		s.log.Error("team_member: failed to publish proposal approved event",
			zap.String("proposal_id", p.ID.String()),
			zap.Error(err),
		)
	}
}

func (s *Service) publishRejected(ctx context.Context, p *FacilitatorProposal) {
	err := s.bus.Publish(ctx, events.Event{
		Type: EventProposalRejected,
		Payload: ProposalRejectedPayload{
			ProposalID:    p.ID,
			CourseID:      p.CourseID,
			FacilitatorID: p.FacilitatorID,
		},
	})
	if err != nil {
		s.log.Error("team_member: failed to publish proposal rejected event",
			zap.String("proposal_id", p.ID.String()),
			zap.Error(err),
		)
	}
}
