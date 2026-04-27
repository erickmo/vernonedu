package team_member

import (
	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// Event type constants for team_member domain.
const (
	EventProposalApproved events.EventType = "team_member.facilitator.proposal.approved"
	EventProposalRejected events.EventType = "team_member.facilitator.proposal.rejected"
)

// ProposalApprovedPayload is published when a facilitator proposal is fully approved.
type ProposalApprovedPayload struct {
	ProposalID    uuid.UUID `json:"proposal_id"`
	CourseID      uuid.UUID `json:"course_id"`
	FacilitatorID uuid.UUID `json:"facilitator_id"`
	FeeTierID     uuid.UUID `json:"fee_tier_id"`
	FeeBasis      FeeBasis  `json:"fee_basis"`
}

// ProposalRejectedPayload is published when a proposal is rejected at any stage.
type ProposalRejectedPayload struct {
	ProposalID    uuid.UUID `json:"proposal_id"`
	CourseID      uuid.UUID `json:"course_id"`
	FacilitatorID uuid.UUID `json:"facilitator_id"`
}

// RegisterSubscriptions subscribes team_member to cross-domain events.
// No inbound subscriptions required per spec.
func RegisterSubscriptions(_ events.Bus, _ *Service) {}
