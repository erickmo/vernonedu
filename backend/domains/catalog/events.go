package catalog

import (
	"context"

	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// Catalog domain consumes the canonical event payload types defined in
// internal/events/payloads.go (BatchCreatedPayload, BatchClosedPayload, etc.).
// No domain-local duplicates — keeps the wire contract single-sourced.

// RegisterSubscriptions subscribes catalog to relevant cross-domain events.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.EnrollmentCompleted, func(_ context.Context, _ events.Event) error {
		return nil
	})
}
