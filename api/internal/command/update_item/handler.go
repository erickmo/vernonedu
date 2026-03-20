package update_item

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

type UpdateItemCommand struct {
	ItemID uuid.UUID `validate:"required"`
	Text   string    `validate:"required,min=1"`
	Note   string
}

type Handler struct {
	itemReadRepo  item.ReadRepository
	itemWriteRepo item.WriteRepository
	eventBus      eventbus.EventBus
}

func NewHandler(itemReadRepo item.ReadRepository, itemWriteRepo item.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		itemReadRepo:  itemReadRepo,
		itemWriteRepo: itemWriteRepo,
		eventBus:      eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	updateCmd, ok := cmd.(*UpdateItemCommand)
	if !ok {
		return errors.New("invalid update item command")
	}

	existingItem, err := h.itemReadRepo.GetByID(ctx, updateCmd.ItemID)
	if err != nil {
		if errors.Is(err, item.ErrItemNotFound) {
			return item.ErrItemNotFound
		}
		log.Error().Err(err).Str("item_id", updateCmd.ItemID.String()).Msg("failed to get item")
		return err
	}

	if err := existingItem.Update(updateCmd.Text, updateCmd.Note); err != nil {
		log.Error().Err(err).Msg("failed to update item")
		return err
	}

	if err := h.itemWriteRepo.Update(ctx, existingItem); err != nil {
		log.Error().Err(err).Msg("failed to update item in repository")
		return err
	}

	event := &item.ItemUpdated{
		ItemID:    existingItem.ID,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish item updated event")
		return err
	}

	log.Info().Str("item_id", existingItem.ID.String()).Msg("item updated successfully")
	return nil
}
