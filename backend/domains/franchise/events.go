package franchise

import (
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// RegisterSubscriptions subscribes franchise to cross-domain events.
// Franchise domain fires no events and listens to none currently.
func RegisterSubscriptions(_ events.Bus, _ *Service) {
}
