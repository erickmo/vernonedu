package delete_item

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/item"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type DeleteItemCommand struct {
	ItemID uuid.UUID `validate:"required"`
}

type Handler struct {
	itemWriteRepo item.WriteRepository
	eventBus      eventbus.EventBus
}

func NewHandler(itemWriteRepo item.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		itemWriteRepo: itemWriteRepo,
		eventBus:      eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	deleteCmd, ok := cmd.(*DeleteItemCommand)
	if !ok {
		return errors.New("invalid delete item command")
	}

	if err := h.itemWriteRepo.Delete(ctx, deleteCmd.ItemID); err != nil {
		log.Error().Err(err).Str("item_id", deleteCmd.ItemID.String()).Msg("failed to delete item")
		return err
	}

	event := &item.ItemDeleted{
		ItemID:    deleteCmd.ItemID,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish item deleted event")
		return err
	}

	log.Info().Str("item_id", deleteCmd.ItemID.String()).Msg("item deleted successfully")
	return nil
}
