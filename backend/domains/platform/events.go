package platform

import (
	"context"

	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// RegisterSubscriptions subscribes platform to all notification-triggering events.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.PaymentTermOverdue, func(_ context.Context, _ events.Event) error {
		return nil
	})
	bus.Subscribe(events.InvoiceOverdue, func(_ context.Context, _ events.Event) error {
		return nil
	})
	bus.Subscribe(events.CertificateIssued, func(_ context.Context, _ events.Event) error {
		return nil
	})
	bus.Subscribe(events.EnrollmentConfirmed, func(_ context.Context, _ events.Event) error {
		return nil
	})
}
