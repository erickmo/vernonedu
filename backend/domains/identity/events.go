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

// RegisterSubscriptions subscribes to events this domain cares about.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	// No cross-domain events consumed by identity currently.
	_ = bus
	_ = svc
}
