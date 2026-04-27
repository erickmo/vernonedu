package profit_split

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// ProfitSplitCalculatedPayload is published when a batch split is calculated.
type ProfitSplitCalculatedPayload struct {
	BatchID             uuid.UUID       `json:"batch_id"`
	CourseID            uuid.UUID       `json:"course_id"`
	Period              string          `json:"period"`
	NetProfit           decimal.Decimal `json:"net_profit"`
	VernonEduAmount     decimal.Decimal `json:"vernonedu_amount"`
	CourseCreatorAmount decimal.Decimal `json:"course_creator_amount"`
	DeptLeaderAmount    decimal.Decimal `json:"dept_leader_amount"`
}

// RegisterSubscriptions subscribes profit_split to cross-domain events.
func RegisterSubscriptions(bus events.Bus, svc *Service, log *zap.Logger) {
	bus.Subscribe(events.BatchClosed, func(ctx context.Context, e events.Event) error {
		payload, err := decodeBatchClosedPayload(e.Payload)
		if err != nil {
			log.Error("profit_split: failed to decode batch.closed payload", zap.Error(err))
			return err
		}

		_, calcErr := svc.CalculateBatchSplit(ctx, CalculateBatchSplitInput{
			BatchID:      payload.BatchID,
			CourseID:     payload.CourseID,
			GrossRevenue: decimal.Zero, // gross is computed from enrollments in a real system
		})
		if calcErr != nil {
			log.Error("profit_split: CalculateBatchSplit failed",
				zap.Stringer("batch_id", payload.BatchID),
				zap.Error(calcErr),
			)
			return calcErr
		}
		return nil
	})
}

// decodeBatchClosedPayload extracts BatchClosedPayload from an event payload.
func decodeBatchClosedPayload(raw any) (*batchClosedPayload, error) {
	b, err := json.Marshal(raw)
	if err != nil {
		return nil, err
	}
	var p batchClosedPayload
	if err := json.Unmarshal(b, &p); err != nil {
		return nil, err
	}
	return &p, nil
}

// batchClosedPayload mirrors the catalog BatchClosedPayload without importing it.
type batchClosedPayload struct {
	BatchID  uuid.UUID `json:"batch_id"`
	CourseID uuid.UUID `json:"course_id"`
}
