package identity

import (
	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// UserCreatedPayload is published when a new user registers.
type UserCreatedPayload struct {
	UserID uuid.UUID `json:"user_id"`
	Email  string    `json:"email"`
	Role   string    `json:"role"`
}

// UserDeactivatedPayload is published when a user is deactivated.
type UserDeactivatedPayload struct {
	UserID uuid.UUID `json:"user_id"`
}

// TeamMemberCreatedPayload is published when a team member is created.
type TeamMemberCreatedPayload struct {
	TeamMemberID uuid.UUID `json:"team_member_id"`
	UserID       uuid.UUID `json:"user_id"`
}

// TeamMemberStatusChangedPayload is published on employment status change.
type TeamMemberStatusChangedPayload struct {
	TeamMemberID uuid.UUID `json:"team_member_id"`
	Status       string    `json:"status"`
}

// FacilitatorProposedPayload is published on proposal create/review.
type FacilitatorProposedPayload struct {
	ProposalID    uuid.UUID `json:"proposal_id"`
	CourseID      uuid.UUID `json:"course_id"`
	FacilitatorID uuid.UUID `json:"facilitator_id"`
}

// RegisterSubscriptions subscribes to events this domain cares about.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	// No cross-domain events consumed by identity currently.
	_ = bus
	_ = svc
}
