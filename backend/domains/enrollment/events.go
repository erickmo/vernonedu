package enrollment

import (
	"context"

	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// RegisterSubscriptions subscribes enrollment to cross-domain events.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.PaymentConfirmed, func(_ context.Context, _ events.Event) error {
		return nil
	})
}
