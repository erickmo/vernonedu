package create_item

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

type CreateItemCommand struct {
	BusinessID  uuid.UUID `validate:"required"`
	CanvasType  string    `validate:"required"`
	SectionID   string    `validate:"required"`
	Text        string    `validate:"required,min=1"`
	Note        string
	CreatedItem *item.Item // populated by handler after save
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
	createCmd, ok := cmd.(*CreateItemCommand)
	if !ok {
		return errors.New("invalid create item command")
	}

	newItem, err := item.NewItem(createCmd.BusinessID, createCmd.CanvasType, createCmd.SectionID, createCmd.Text, createCmd.Note)
	if err != nil {
		log.Error().Err(err).Msg("failed to create item")
		return err
	}

	if err := h.itemWriteRepo.Save(ctx, newItem); err != nil {
		log.Error().Err(err).Msg("failed to save item")
		return err
	}

	createCmd.CreatedItem = newItem

	event := &item.ItemCreated{
		ItemID:    newItem.ID,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish item created event")
		return err
	}

	log.Info().Str("item_id", newItem.ID.String()).Msg("item created successfully")
	return nil
}
