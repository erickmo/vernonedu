package module

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// classCompletedPayload is the expected shape of attendance.class_completed.
type classCompletedPayload struct {
	ClassID uuid.UUID `json:"class_id"`
}

// RegisterSubscriptions wires module domain into the event bus.
func RegisterSubscriptions(bus events.Bus, svc *Service, log *zap.Logger) {
	bus.Subscribe(events.ClassCompleted, handleClassCompleted(svc, log))
}

func handleClassCompleted(svc *Service, log *zap.Logger) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		payload, err := decodeClassCompletedPayload(e.Payload)
		if err != nil {
			log.Error("module: failed to decode ClassCompleted payload", zap.Error(err))
			return err
		}
		if err := svc.AutoFlipPlannedToCovered(ctx, payload.ClassID); err != nil {
			log.Error("module: AutoFlipPlannedToCovered failed",
				zap.String("class_id", payload.ClassID.String()),
				zap.Error(err))
			return err
		}
		return nil
	}
}

func decodeClassCompletedPayload(raw any) (*classCompletedPayload, error) {
	b, err := json.Marshal(raw)
	if err != nil {
		return nil, err
	}
	var p classCompletedPayload
	if err := json.Unmarshal(b, &p); err != nil {
		return nil, err
	}
	return &p, nil
}
