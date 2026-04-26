package identity

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"
)

// Service exposes identity domain business logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs an identity Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

// RegisterInput is the data needed to create a new user + student.
type RegisterInput struct {
	Email    string
	Password string
	Name     string
	Phone    string
	Role     UserRole
	Source   StudentSource
}

// Register creates a user record and, if role==student, a student record.
func (s *Service) Register(ctx context.Context, in RegisterInput) (*User, error) {
	existing, err := s.repo.GetUserByEmail(ctx, in.Email)
	if err == nil && existing != nil {
		return nil, apperrors.Conflictf("email already registered")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(in.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("identity.Register hash: %w", err)
	}

	user := &User{
		ID:           uuid.New(),
		Email:        in.Email,
		PasswordHash: string(hash),
		Role:         in.Role,
		IsActive:     true,
	}

	if err := s.repo.CreateUser(ctx, user); err != nil {
		return nil, err
	}

	if in.Role == RoleStudent {
		student := &Student{
			ID:     uuid.New(),
			UserID: user.ID,
			Name:   in.Name,
			Email:  in.Email,
			Phone:  in.Phone,
			Source: in.Source,
		}
		if err := s.repo.CreateStudent(ctx, student); err != nil {
			return nil, err
		}
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.UserCreated,
		Payload: UserCreatedPayload{UserID: user.ID, Email: user.Email, Role: string(user.Role)},
	})

	return user, nil
}

// Login validates credentials and returns the user.
func (s *Service) Login(ctx context.Context, email, password string) (*User, error) {
	user, err := s.repo.GetUserByEmail(ctx, email)
	if err != nil {
		return nil, apperrors.ErrUnauthorized
	}

	if !user.IsActive {
		return nil, apperrors.Validationf("account is deactivated")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return nil, apperrors.ErrUnauthorized
	}

	return user, nil
}

// GetUser fetches a user by ID.
func (s *Service) GetUser(ctx context.Context, id uuid.UUID) (*User, error) {
	return s.repo.GetUserByID(ctx, id)
}

// DeactivateUser soft-deactivates a user account.
func (s *Service) DeactivateUser(ctx context.Context, id uuid.UUID) error {
	if err := s.repo.DeactivateUser(ctx, id); err != nil {
		return err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.UserDeactivated,
		Payload: UserDeactivatedPayload{UserID: id},
	})

	return nil
}

// GetStudentByID fetches student by primary key.
func (s *Service) GetStudentByID(ctx context.Context, id uuid.UUID) (*Student, error) {
	return s.repo.GetStudentByID(ctx, id)
}

// GetStudentByUserID fetches the student profile linked to a user.
func (s *Service) GetStudentByUserID(ctx context.Context, userID uuid.UUID) (*Student, error) {
	return s.repo.GetStudentByUserID(ctx, userID)
}

// ListStudents paginates the student list.
func (s *Service) ListStudents(ctx context.Context, limit, offset int) ([]*Student, error) {
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	return s.repo.ListStudents(ctx, limit, offset)
}

// CreateTeamMember creates a team member record.
func (s *Service) CreateTeamMember(ctx context.Context, tm *TeamMember) error {
	tm.ID = uuid.New()
	if err := s.repo.CreateTeamMember(ctx, tm); err != nil {
		return err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.TeamMemberCreated,
		Payload: TeamMemberCreatedPayload{TeamMemberID: tm.ID, UserID: tm.UserID},
	})

	return nil
}

// UpdateTeamMemberStatus updates employment status and publishes event.
func (s *Service) UpdateTeamMemberStatus(ctx context.Context, id uuid.UUID, status EmploymentStatus) error {
	if err := s.repo.UpdateTeamMemberStatus(ctx, id, status); err != nil {
		return err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.TeamMemberStatusChanged,
		Payload: TeamMemberStatusChangedPayload{TeamMemberID: id, Status: string(status)},
	})

	return nil
}

// CreateDepartment creates a department.
func (s *Service) CreateDepartment(ctx context.Context, dept *Department) error {
	dept.ID = uuid.New()
	return s.repo.CreateDepartment(ctx, dept)
}

// ListDepartments returns active departments.
func (s *Service) ListDepartments(ctx context.Context) ([]*Department, error) {
	return s.repo.ListDepartments(ctx)
}

// ProposeF acilitator creates a facilitator proposal and publishes the event.
func (s *Service) ProposeFacilitator(ctx context.Context, p *FacilitatorProposal) error {
	p.ID = uuid.New()
	p.DeptLeaderStatus = ProposalPending
	p.AcademicLeaderStatus = ProposalPending
	p.FinalStatus = ProposalPending

	if err := s.repo.CreateFacilitatorProposal(ctx, p); err != nil {
		return err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.FacilitatorProposed,
		Payload: FacilitatorProposedPayload{ProposalID: p.ID, CourseID: p.CourseID, FacilitatorID: p.FacilitatorID},
	})

	return nil
}

// ReviewProposal updates dept or academic leader review status.
func (s *Service) ReviewProposal(ctx context.Context, id uuid.UUID, reviewer string, status ProposalStatus, note *string) error {
	p, err := s.repo.GetFacilitatorProposalByID(ctx, id)
	if err != nil {
		return err
	}

	switch reviewer {
	case "dept_leader":
		p.DeptLeaderStatus = status
		p.DeptLeaderNote = note
	case "academic_leader":
		p.AcademicLeaderStatus = status
		p.AcademicLeaderNote = note
	default:
		return apperrors.Validationf("invalid reviewer type")
	}

	// Compute final status
	if p.DeptLeaderStatus == ProposalApproved && p.AcademicLeaderStatus == ProposalApproved {
		p.FinalStatus = ProposalApproved
	} else if p.DeptLeaderStatus == ProposalRejected || p.AcademicLeaderStatus == ProposalRejected {
		p.FinalStatus = ProposalRejected
	}

	if err := s.repo.UpdateFacilitatorProposal(ctx, p); err != nil {
		return err
	}

	evType := events.FacilitatorProposed
	if p.FinalStatus == ProposalApproved {
		evType = events.FacilitatorApproved
	} else if p.FinalStatus == ProposalRejected {
		evType = events.FacilitatorRejected
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    evType,
		Payload: FacilitatorProposedPayload{ProposalID: p.ID, CourseID: p.CourseID, FacilitatorID: p.FacilitatorID},
	})

	return nil
}
