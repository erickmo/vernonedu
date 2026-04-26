package partnerships

import (
	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// PartnershipMeetingScheduledPayload published when a meeting is scheduled for a partnership.
type PartnershipMeetingScheduledPayload struct {
	AgreementID uuid.UUID `json:"agreement_id"`
	EventID     uuid.UUID `json:"event_id"`
}

// RegisterSubscriptions subscribes partnerships to cross-domain events.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	_ = bus
	_ = svc
}
