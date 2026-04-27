package credentialing

import (
	"context"

	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// RegisterSubscriptions subscribes credentialing to enrollment completion.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.EnrollmentCompleted, func(_ context.Context, _ events.Event) error {
		return nil
	})
}
