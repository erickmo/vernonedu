package budget

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// batchCreatedPayload matches the course.batch.created event payload shape.
type batchCreatedPayload struct {
	BatchID  uuid.UUID `json:"batch_id"`
	CourseID uuid.UUID `json:"course_id"`
	ActorID  uuid.UUID `json:"actor_id"`
}

// RegisterSubscriptions wires budget domain into the event bus.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.BatchCreated, handleBatchCreated(svc))
}

func handleBatchCreated(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		payload, err := decodeBatchCreatedPayload(e.Payload)
		if err != nil {
			svc.log.Error("budget: failed to decode BatchCreated payload", zap.Error(err))
			return err
		}
		return svc.OnBatchCreated(ctx, payload.BatchID, payload.CourseID, payload.ActorID)
	}
}

func decodeBatchCreatedPayload(raw any) (*batchCreatedPayload, error) {
	b, err := json.Marshal(raw)
	if err != nil {
		return nil, err
	}
	var p batchCreatedPayload
	if err := json.Unmarshal(b, &p); err != nil {
		return nil, err
	}
	return &p, nil
}
