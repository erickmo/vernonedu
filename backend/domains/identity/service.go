package identity

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// Service exposes identity domain business logic.
type Service struct {
	repo      Repository
	bus       events.Bus
	log       *zap.Logger
	jwtSecret string
	jwtExpiry time.Duration
}

// NewService constructs an identity Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger, jwtSecret string, jwtExpiry time.Duration) *Service {
	return &Service{
		repo:      repo,
		bus:       bus,
		log:       log,
		jwtSecret: jwtSecret,
		jwtExpiry: jwtExpiry,
	}
}

// RegisterInput is the data needed to create a new user + student.
type RegisterInput struct {
	Email    string
	Password string
	Name     string
	Phone    string
	Role     UserRole
	Source   StudentSource
	Partner  *uuid.UUID
}

// RegisterOutput is returned by RegisterStudent.
type RegisterOutput struct {
	User    User
	Student Student
}

// RegisterStudent creates a user (role=student) and the linked student profile.
// It is the dedicated entry point for student self-registration; the legacy
// Register method is kept temporarily for backward compatibility.
func (s *Service) RegisterStudent(ctx context.Context, in RegisterInput) (*RegisterOutput, error) {
	existing, err := s.repo.GetUserByEmail(ctx, in.Email)
	if err == nil && existing != nil {
		return nil, apperrors.Validationf("email already registered")
	}

	hash, err := HashPassword(in.Password)
	if err != nil {
		return nil, apperrors.Validationf(err.Error())
	}

	user := &User{
		ID:           uuid.New(),
		Email:        in.Email,
		PasswordHash: hash,
		Role:         RoleStudent,
		IsActive:     true,
	}
	if err := s.repo.CreateUser(ctx, user); err != nil {
		return nil, err
	}

	student := &Student{
		ID:        uuid.New(),
		UserID:    user.ID,
		Name:      in.Name,
		Email:     in.Email,
		Phone:     in.Phone,
		Source:    in.Source,
		PartnerID: in.Partner,
	}
	if err := s.repo.CreateStudent(ctx, student); err != nil {
		return nil, err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.UserCreated,
		Payload: UserCreatedPayload{UserID: user.ID, Email: user.Email, Role: string(user.Role)},
	})

	return &RegisterOutput{User: *user, Student: *student}, nil
}

// Register creates a user record and, if role==student, a student record.
func (s *Service) Register(ctx context.Context, in RegisterInput) (*User, error) {
	existing, err := s.repo.GetUserByEmail(ctx, in.Email)
	if err == nil && existing != nil {
		return nil, apperrors.Conflictf("email already registered")
	}

	hash, err := HashPassword(in.Password)
	if err != nil {
		return nil, fmt.Errorf("identity.Register hash: %w", err)
	}

	user := &User{
		ID:           uuid.New(),
		Email:        in.Email,
		PasswordHash: hash,
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

// LoginOutput is returned by Login: authenticated user + signed JWT.
type LoginOutput struct {
	User  User
	Token string
}

// Login validates credentials and returns the user with a signed JWT.
func (s *Service) Login(ctx context.Context, email, password string) (*LoginOutput, error) {
	user, err := s.repo.GetUserByEmail(ctx, email)
	if err != nil || user == nil {
		return nil, apperrors.ErrUnauthorized
	}

	if !user.IsActive {
		return nil, apperrors.ErrUnauthorized
	}

	if !VerifyPassword(user.PasswordHash, password) {
		return nil, apperrors.ErrUnauthorized
	}

	token, err := s.issueJWT(user)
	if err != nil {
		return nil, fmt.Errorf("identity.Login issue jwt: %w", err)
	}

	return &LoginOutput{User: *user, Token: token}, nil
}

// jwtClaims mirrors internal/middleware.jwtClaims so the middleware can
// validate tokens issued by this service. Keep the JSON tags aligned.
type jwtClaims struct {
	jwt.RegisteredClaims
	Role  string `json:"role"`
	Email string `json:"email"`
}

// issueJWT signs an HS256 JWT for the given user using the configured secret.
func (s *Service) issueJWT(u *User) (string, error) {
	now := time.Now()
	claims := jwtClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   u.ID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.jwtExpiry)),
		},
		Role:  string(u.Role),
		Email: u.Email,
	}
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return tok.SignedString([]byte(s.jwtSecret))
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

// Profile field constants. Values match identity.gender_type / id_card_type enums.
const (
	GenderMale     = "male"
	GenderFemale   = "female"
	IDTypeKTP      = "ktp"
	IDTypePassport = "passport"
	IDTypeSIM      = "sim"
)

// ProfileInput captures partial or full student profile data.
// All fields are optional; HasAllRequired determines profile completion.
type ProfileInput struct {
	DateOfBirth *time.Time
	Gender      *string
	IDType      *string
	IDNumber    *string
	Address     *string
	City        *string
	Province    *string
	PostalCode  *string
}

// HasAllRequired returns true when every profile field is populated.
func (in ProfileInput) HasAllRequired() bool {
	return in.DateOfBirth != nil &&
		nonEmpty(in.Gender) && nonEmpty(in.IDType) && nonEmpty(in.IDNumber) &&
		nonEmpty(in.Address) && nonEmpty(in.City) &&
		nonEmpty(in.Province) && nonEmpty(in.PostalCode)
}

func nonEmpty(s *string) bool { return s != nil && *s != "" }

// UpdateStudentProfile upserts the student profile and emits
// student.profile_completed exactly once when the profile transitions
// from incomplete to complete.
func (s *Service) UpdateStudentProfile(ctx context.Context, studentID uuid.UUID, in ProfileInput) (*StudentProfile, error) {
	prev, err := s.repo.GetStudentProfileByStudentID(ctx, studentID)
	if err != nil && !errors.Is(err, apperrors.ErrNotFound) {
		return nil, err
	}

	complete := in.HasAllRequired()
	p, err := s.repo.UpsertStudentProfile(ctx, studentID, in, complete)
	if err != nil {
		return nil, err
	}

	if complete && (prev == nil || !prev.ProfileComplete) {
		_ = s.bus.Publish(ctx, events.Event{
			Type:    events.StudentProfileCompleted,
			Payload: map[string]any{"student_id": studentID},
		})
	}
	return p, nil
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

// CreateTeamMemberInput captures fields required to create a team member.
type CreateTeamMemberInput struct {
	UserID           uuid.UUID
	FullName         string
	Phone            string
	Role             UserRole
	DepartmentID     *uuid.UUID
	EmploymentStatus EmploymentStatus
	IsFacilitator    bool
}

// CreateTeamMember creates a team member record and publishes
// team_member.created with the typed payload from internal/events.
func (s *Service) CreateTeamMember(ctx context.Context, in CreateTeamMemberInput) (*TeamMember, error) {
	status := in.EmploymentStatus
	if status == "" {
		status = StatusActive
	}

	tm := &TeamMember{
		ID:               uuid.New(),
		UserID:           in.UserID,
		FullName:         in.FullName,
		Phone:            in.Phone,
		DepartmentID:     in.DepartmentID,
		Role:             in.Role,
		EmploymentStatus: status,
		JoinedAt:         time.Now(),
		IsFacilitator:    in.IsFacilitator,
	}
	if err := s.repo.CreateTeamMember(ctx, tm); err != nil {
		return nil, err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type: events.TeamMemberCreated,
		Payload: events.TeamMemberCreatedPayload{
			TeamMemberID: tm.ID,
			UserID:       tm.UserID,
			Role:         string(tm.Role),
			DepartmentID: tm.DepartmentID,
			Status:       string(tm.EmploymentStatus),
		},
	})

	return tm, nil
}

// UpdateTeamMemberStatus changes employment status. It is a noop when the
// new status equals the current one. On change it persists the new value
// and publishes team_member.status_changed with old + new status.
func (s *Service) UpdateTeamMemberStatus(ctx context.Context, id uuid.UUID, newStatus EmploymentStatus) error {
	current, err := s.repo.GetTeamMemberByID(ctx, id)
	if err != nil {
		return err
	}
	if current.EmploymentStatus == newStatus {
		return nil
	}

	oldStatus := current.EmploymentStatus
	if err := s.repo.UpdateTeamMemberStatus(ctx, id, newStatus); err != nil {
		return err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type: events.TeamMemberStatusChanged,
		Payload: events.TeamMemberStatusChangedPayload{
			TeamMemberID: id,
			OldStatus:    string(oldStatus),
			NewStatus:    string(newStatus),
		},
	})

	return nil
}

// DeactivateTeamMember sets a team member's employment status to inactive.
// Delegates to UpdateTeamMemberStatus so the status_changed event fires.
func (s *Service) DeactivateTeamMember(ctx context.Context, id uuid.UUID) error {
	return s.UpdateTeamMemberStatus(ctx, id, StatusInactive)
}

// GetTeamMember fetches a team member by primary key.
func (s *Service) GetTeamMember(ctx context.Context, id uuid.UUID) (*TeamMember, error) {
	return s.repo.GetTeamMemberByID(ctx, id)
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

// Approval flow stage labels emitted on facilitator.rejected events.
const (
	StageDeptLeader      = "dept_leader"
	StageAcademicLeader  = "academic_leader"
)

// ProposeFacilitatorInput carries data needed to create a proposal.
type ProposeFacilitatorInput struct {
	ProposedByTeamMemberID  uuid.UUID
	CourseID                uuid.UUID
	FacilitatorTeamMemberID uuid.UUID
	FeeTierID               uuid.UUID
	FeeBasis                FeeBasis
}

// ProposeFacilitator creates a pending facilitator proposal after verifying
// the proposer is a course_creator team member and the candidate has a
// FacilitatorProfile. Publishes facilitator.proposed on success.
func (s *Service) ProposeFacilitator(ctx context.Context, in ProposeFacilitatorInput) (*FacilitatorProposal, error) {
	proposer, err := s.repo.GetTeamMemberByID(ctx, in.ProposedByTeamMemberID)
	if err != nil {
		return nil, err
	}
	if proposer.Role != RoleCourseCreator {
		return nil, apperrors.Validationf("proposer must be course_creator")
	}
	if _, err := s.repo.GetFacilitatorProfileByTeamMemberID(ctx, in.FacilitatorTeamMemberID); err != nil {
		if errors.Is(err, apperrors.ErrNotFound) {
			return nil, apperrors.Validationf("facilitator has no facilitator profile")
		}
		return nil, err
	}

	p := &FacilitatorProposal{
		ID:                   uuid.New(),
		CourseID:             in.CourseID,
		ProposedBy:           in.ProposedByTeamMemberID,
		FacilitatorID:        in.FacilitatorTeamMemberID,
		FeeTierID:            in.FeeTierID,
		FeeBasis:             in.FeeBasis,
		DeptLeaderStatus:     ProposalPending,
		AcademicLeaderStatus: ProposalPending,
		FinalStatus:          ProposalPending,
	}
	if err := s.repo.CreateFacilitatorProposal(ctx, p); err != nil {
		return nil, err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type: events.FacilitatorProposed,
		Payload: events.FacilitatorProposedPayload{
			ProposalID:    p.ID,
			CourseID:      p.CourseID,
			ProposedBy:    p.ProposedBy,
			FacilitatorID: p.FacilitatorID,
		},
	})

	return p, nil
}

// ApproveProposalDeptLeader marks dept-leader stage approved. Final status
// remains pending until academic leader also approves.
func (s *Service) ApproveProposalDeptLeader(ctx context.Context, proposalID, deptLeaderID uuid.UUID, note *string) error {
	p, err := s.repo.GetFacilitatorProposalByID(ctx, proposalID)
	if err != nil {
		return err
	}
	if p.DeptLeaderStatus != ProposalPending {
		return apperrors.Validationf("dept leader already reviewed")
	}
	now := time.Now()
	p.DeptLeaderStatus = ProposalApproved
	p.DeptLeaderReviewedAt = &now
	p.DeptLeaderNote = note
	// Final status stays pending — academic leader still required.
	return s.repo.UpdateFacilitatorProposal(ctx, p)
}

// RejectProposalDeptLeader marks dept-leader stage rejected and finalises
// the proposal as rejected. Publishes facilitator.rejected.
func (s *Service) RejectProposalDeptLeader(ctx context.Context, proposalID, deptLeaderID uuid.UUID, note *string) error {
	p, err := s.repo.GetFacilitatorProposalByID(ctx, proposalID)
	if err != nil {
		return err
	}
	if p.DeptLeaderStatus != ProposalPending {
		return apperrors.Validationf("dept leader already reviewed")
	}
	now := time.Now()
	p.DeptLeaderStatus = ProposalRejected
	p.DeptLeaderReviewedAt = &now
	p.DeptLeaderNote = note
	p.FinalStatus = ProposalRejected
	if err := s.repo.UpdateFacilitatorProposal(ctx, p); err != nil {
		return err
	}
	_ = s.bus.Publish(ctx, events.Event{
		Type: events.FacilitatorRejected,
		Payload: events.FacilitatorRejectedPayload{
			ProposalID:    p.ID,
			CourseID:      p.CourseID,
			FacilitatorID: p.FacilitatorID,
			Stage:         StageDeptLeader,
			RejectedBy:    deptLeaderID,
		},
	})
	return nil
}

// ApproveProposalAcademicLeader requires dept leader approval first, then
// finalises the proposal as approved and publishes facilitator.approved.
func (s *Service) ApproveProposalAcademicLeader(ctx context.Context, proposalID, academicLeaderID uuid.UUID, note *string) error {
	p, err := s.repo.GetFacilitatorProposalByID(ctx, proposalID)
	if err != nil {
		return err
	}
	if p.DeptLeaderStatus != ProposalApproved {
		return apperrors.Validationf("dept leader has not approved")
	}
	if p.AcademicLeaderStatus != ProposalPending {
		return apperrors.Validationf("academic leader already reviewed")
	}
	now := time.Now()
	p.AcademicLeaderStatus = ProposalApproved
	p.AcademicLeaderReviewedAt = &now
	p.AcademicLeaderNote = note
	p.FinalStatus = ProposalApproved
	if err := s.repo.UpdateFacilitatorProposal(ctx, p); err != nil {
		return err
	}
	_ = s.bus.Publish(ctx, events.Event{
		Type: events.FacilitatorApproved,
		Payload: events.FacilitatorApprovedPayload{
			ProposalID:    p.ID,
			CourseID:      p.CourseID,
			FacilitatorID: p.FacilitatorID,
			ApprovedBy:    academicLeaderID,
		},
	})
	return nil
}

// RejectProposalAcademicLeader requires dept leader approval first, then
// finalises the proposal as rejected and publishes facilitator.rejected.
func (s *Service) RejectProposalAcademicLeader(ctx context.Context, proposalID, academicLeaderID uuid.UUID, note *string) error {
	p, err := s.repo.GetFacilitatorProposalByID(ctx, proposalID)
	if err != nil {
		return err
	}
	if p.DeptLeaderStatus != ProposalApproved {
		return apperrors.Validationf("dept leader has not approved")
	}
	if p.AcademicLeaderStatus != ProposalPending {
		return apperrors.Validationf("academic leader already reviewed")
	}
	now := time.Now()
	p.AcademicLeaderStatus = ProposalRejected
	p.AcademicLeaderReviewedAt = &now
	p.AcademicLeaderNote = note
	p.FinalStatus = ProposalRejected
	if err := s.repo.UpdateFacilitatorProposal(ctx, p); err != nil {
		return err
	}
	_ = s.bus.Publish(ctx, events.Event{
		Type: events.FacilitatorRejected,
		Payload: events.FacilitatorRejectedPayload{
			ProposalID:    p.ID,
			CourseID:      p.CourseID,
			FacilitatorID: p.FacilitatorID,
			Stage:         StageAcademicLeader,
			RejectedBy:    academicLeaderID,
		},
	})
	return nil
}
