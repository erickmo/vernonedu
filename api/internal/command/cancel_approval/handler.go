package cancel_approval

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/approval"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo approval.WriteRepository
	readRepo  approval.ReadRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo approval.WriteRepository, readRepo approval.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CancelApprovalCommand)
	if !ok {
		return ErrInvalidCommand
	}

	req, err := h.readRepo.GetByID(ctx, c.ApprovalID)
	if err != nil {
		return err
	}

	if req.Status != approval.StatusPending {
		return approval.ErrAlreadyFinalized
	}

	now := time.Now()
	req.Status = approval.StatusCancelled
	req.UpdatedAt = now

	if err := h.writeRepo.Update(ctx, req); err != nil {
		log.Error().Err(err).Msg("failed to cancel approval request")
		return err
	}

	event := &approval.ApprovalCancelledEvent{
		EventType:  "ApprovalCancelled",
		ApprovalID: req.ID,
		Timestamp:  now.Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish ApprovalCancelled event")
	}

	log.Info().Str("approval_id", req.ID.String()).Msg("approval cancelled")
	return nil
}
