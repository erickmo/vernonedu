package delete_business

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/business"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type DeleteBusinessCommand struct {
	BusinessID uuid.UUID `validate:"required"`
}

type Handler struct {
	businessWriteRepo business.WriteRepository
	eventBus          eventbus.EventBus
}

func NewHandler(businessWriteRepo business.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		businessWriteRepo: businessWriteRepo,
		eventBus:          eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	deleteCmd, ok := cmd.(*DeleteBusinessCommand)
	if !ok {
		return errors.New("invalid delete business command")
	}

	if err := h.businessWriteRepo.Delete(ctx, deleteCmd.BusinessID); err != nil {
		log.Error().Err(err).Str("business_id", deleteCmd.BusinessID.String()).Msg("failed to delete business")
		return err
	}

	event := &business.BusinessDeleted{
		BusinessID: deleteCmd.BusinessID,
		Timestamp:  time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish BusinessDeleted event")
		return err
	}

	log.Info().Str("business_id", deleteCmd.BusinessID.String()).Msg("business deleted successfully")
	return nil
}
