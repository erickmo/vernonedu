package eventbus

import (
	"context"
	"encoding/json"
	"sync"

	"github.com/rs/zerolog/log"
)

type DomainEvent interface {
	EventName() string
	EventData() interface{}
}

type EventBus interface {
	Publish(ctx context.Context, event DomainEvent) error
	Subscribe(ctx context.Context, eventName string, handler MessageHandler) error
	Close() error
}

type MessageHandler func(ctx context.Context, data []byte) error

type InMemoryEventBus struct {
	mu       sync.RWMutex
	handlers map[string][]MessageHandler
}

func NewInMemoryEventBus() *InMemoryEventBus {
	return &InMemoryEventBus{
		handlers: make(map[string][]MessageHandler),
	}
}

func (eb *InMemoryEventBus) Publish(ctx context.Context, event DomainEvent) error {
	data, err := json.Marshal(event.EventData())
	if err != nil {
		log.Error().Err(err).Str("event", event.EventName()).Msg("failed to marshal event")
		return err
	}

	eb.mu.RLock()
	handlers, ok := eb.handlers[event.EventName()]
	eb.mu.RUnlock()

	if !ok {
		return nil
	}

	for _, handler := range handlers {
		go func(h MessageHandler) {
			if err := h(ctx, data); err != nil {
				log.Error().Err(err).Str("event", event.EventName()).Msg("handler error")
			}
		}(handler)
	}

	return nil
}

func (eb *InMemoryEventBus) Subscribe(ctx context.Context, eventName string, handler MessageHandler) error {
	eb.mu.Lock()
	eb.handlers[eventName] = append(eb.handlers[eventName], handler)
	eb.mu.Unlock()
	return nil
}

func (eb *InMemoryEventBus) Close() error {
	eb.mu.Lock()
	defer eb.mu.Unlock()
	eb.handlers = make(map[string][]MessageHandler)
	return nil
}
