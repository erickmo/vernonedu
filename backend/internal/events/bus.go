package events

import (
	"context"
	"fmt"
	"sync"

	"go.uber.org/zap"
)

// EventType is a string identifier for an event.
type EventType string

// Event carries type and payload across domain boundaries.
type Event struct {
	Type    EventType
	Payload any
}

// HandlerFunc processes a domain event.
type HandlerFunc func(ctx context.Context, event Event) error

// Bus publishes events and dispatches them to subscribers.
type Bus interface {
	Publish(ctx context.Context, event Event) error
	Subscribe(eventType EventType, handler HandlerFunc)
}

type bus struct {
	mu       sync.RWMutex
	handlers map[EventType][]HandlerFunc
	log      *zap.Logger
}

// NewBus constructs an in-process event bus (FX-injectable).
func NewBus(log *zap.Logger) Bus {
	return &bus{
		handlers: make(map[EventType][]HandlerFunc),
		log:      log,
	}
}

// Subscribe registers handler for eventType. Safe for concurrent use.
func (b *bus) Subscribe(eventType EventType, handler HandlerFunc) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.handlers[eventType] = append(b.handlers[eventType], handler)
	b.log.Debug("event handler registered", zap.String("event", string(eventType)))
}

// Publish dispatches event to all registered handlers synchronously.
// Returns combined error if any handler fails.
func (b *bus) Publish(ctx context.Context, event Event) error {
	b.mu.RLock()
	handlers := b.handlers[event.Type]
	b.mu.RUnlock()

	if len(handlers) == 0 {
		b.log.Debug("no handlers for event", zap.String("event", string(event.Type)))
		return nil
	}

	var errs []error
	for _, h := range handlers {
		if err := h(ctx, event); err != nil {
			b.log.Error("event handler error",
				zap.String("event", string(event.Type)),
				zap.Error(err),
			)
			errs = append(errs, err)
		}
	}

	if len(errs) > 0 {
		return fmt.Errorf("event %s: %d handler(s) failed: %v", event.Type, len(errs), errs)
	}
	return nil
}
