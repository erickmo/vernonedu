package review_leave_request

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type ReviewLeaveRequestCommand struct {
	ID         string `validate:"required"`
	Status     string `validate:"required,oneof=approved rejected"`
	ReviewedBy string `validate:"required"`
}

type Handler struct {
	writeRepo hrm.WriteRepository
	readRepo  hrm.ReadRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo hrm.WriteRepository, readRepo hrm.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*ReviewLeaveRequestCommand)
	if !ok {
		return ErrInvalidCommand
	}

	id, err := uuid.Parse(c.ID)
	if err != nil {
		return ErrInvalidCommand
	}

	reviewedBy, err := uuid.Parse(c.ReviewedBy)
	if err != nil {
		return ErrInvalidCommand
	}

	lr, err := h.readRepo.GetLeaveRequestByID(ctx, id)
	if err != nil {
		log.Error().Err(err).Msg("failed to get leave request")
		return err
	}

	if lr.Status != "pending" {
		return hrm.ErrAlreadyReviewed
	}

	now := time.Now()
	lr.Status = c.Status
	lr.ReviewedBy = &reviewedBy
	lr.ReviewedAt = &now
	lr.UpdatedAt = now

	if err := h.writeRepo.UpdateLeaveRequestStatus(ctx, lr); err != nil {
		log.Error().Err(err).Msg("failed to update leave request status")
		return err
	}

	log.Info().Str("leave_request_id", id.String()).Str("status", c.Status).Msg("leave request reviewed")
	return nil
}
