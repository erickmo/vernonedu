package delete_lead

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	leadWriteRepo lead.WriteRepository
	eventBus      eventbus.EventBus
}

func NewHandler(leadWriteRepo lead.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		leadWriteRepo: leadWriteRepo,
		eventBus:      eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	deleteCmd, ok := cmd.(*DeleteLeadCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.leadWriteRepo.Delete(ctx, deleteCmd.ID); err != nil {
		log.Error().Err(err).Str("lead_id", deleteCmd.ID.String()).Msg("failed to delete lead")
		return err
	}

	event := &lead.LeadDeletedEvent{
		EventType: "LeadDeleted",
		LeadID:    deleteCmd.ID,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish LeadDeleted event")
		return err
	}

	log.Info().Str("lead_id", deleteCmd.ID.String()).Msg("lead deleted successfully")
	return nil
}
