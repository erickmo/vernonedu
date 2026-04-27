package calendar

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.BatchCreated, handleBatchCreated(svc))
	bus.Subscribe(events.ClassFacilitatorAssigned, handleFacilitatorAssigned(svc))
	bus.Subscribe(events.ClassRescheduled, handleClassRescheduled(svc))
	bus.Subscribe(events.ClassCancelled, handleClassCancelled(svc))
	bus.Subscribe(events.PaymentTermDue, handlePaymentTermDue(svc))
	bus.Subscribe(events.FacilitatorApproved, handleFacilitatorApproved(svc))
}

func handleBatchCreated(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			BatchID  uuid.UUID `json:"batch_id"`
			CourseID uuid.UUID `json:"course_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			svc.log.Error("calendar: parse BatchCreated payload", zap.Error(err))
			return nil
		}
		if err := svc.HandleBatchCreated(ctx, p.BatchID, p.CourseID); err != nil {
			svc.log.Error("calendar: HandleBatchCreated", zap.Error(err))
		}
		return nil
	}
}

func handleFacilitatorAssigned(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			ClassID       uuid.UUID `json:"class_id"`
			FacilitatorID uuid.UUID `json:"facilitator_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			return nil
		}
		if err := svc.HandleFacilitatorAssigned(ctx, p.ClassID, p.FacilitatorID); err != nil {
			svc.log.Error("calendar: HandleFacilitatorAssigned", zap.Error(err))
		}
		return nil
	}
}

func handleClassRescheduled(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			ClassID uuid.UUID `json:"class_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			return nil
		}
		if err := svc.HandleClassRescheduled(ctx, p.ClassID); err != nil {
			svc.log.Error("calendar: HandleClassRescheduled", zap.Error(err))
		}
		return nil
	}
}

func handleClassCancelled(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			ClassID uuid.UUID `json:"class_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			return nil
		}
		if err := svc.HandleClassCancelled(ctx, p.ClassID); err != nil {
			svc.log.Error("calendar: HandleClassCancelled", zap.Error(err))
		}
		return nil
	}
}

func handlePaymentTermDue(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			TermID    uuid.UUID `json:"term_id"`
			PaymentID uuid.UUID `json:"payment_id"`
			DueDate   time.Time `json:"due_date"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			return nil
		}
		systemUser := uuid.MustParse("00000000-0000-0000-0000-000000000001")
		if err := svc.HandlePaymentTermDue(ctx, p.TermID, p.DueDate, systemUser); err != nil {
			svc.log.Error("calendar: HandlePaymentTermDue", zap.Error(err))
		}
		return nil
	}
}

func handleFacilitatorApproved(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		var p struct {
			ProposalID    uuid.UUID `json:"proposal_id"`
			CourseID      uuid.UUID `json:"course_id"`
			FacilitatorID uuid.UUID `json:"facilitator_id"`
		}
		if err := unmarshalPayload(e.Payload, &p); err != nil {
			return nil
		}
		if err := svc.HandleFacilitatorApproved(ctx, p.CourseID, p.FacilitatorID); err != nil {
			svc.log.Error("calendar: HandleFacilitatorApproved", zap.Error(err))
		}
		return nil
	}
}

func unmarshalPayload(payload any, dst any) error {
	b, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	return json.Unmarshal(b, dst)
}
