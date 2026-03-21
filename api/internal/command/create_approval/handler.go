package create_approval

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
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo approval.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateApprovalCommand)
	if !ok {
		return ErrInvalidCommand
	}

	steps := make([]approval.StepInput, len(c.Steps))
	for i, s := range c.Steps {
		steps[i] = approval.StepInput{
			ApproverID:   s.ApproverID,
			ApproverRole: s.ApproverRole,
		}
	}

	req, err := approval.NewApprovalRequest(approval.Type(c.Type), c.EntityType, c.EntityID, c.InitiatorID, c.Reason, steps)
	if err != nil {
		log.Error().Err(err).Msg("failed to create approval request")
		return err
	}

	if err := h.writeRepo.Save(ctx, req); err != nil {
		log.Error().Err(err).Msg("failed to save approval request")
		return err
	}

	event := &approval.ApprovalCreatedEvent{
		EventType:  "ApprovalCreated",
		ApprovalID: req.ID,
		Timestamp:  time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish ApprovalCreated event")
	}

	log.Info().Str("approval_id", req.ID.String()).Msg("approval request created")
	return nil
}
