package create_business

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

type CreateBusinessCommand struct {
	UserID uuid.UUID `validate:"required"`
	Name   string    `validate:"required,min=1"`
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
	createCmd, ok := cmd.(*CreateBusinessCommand)
	if !ok {
		return errors.New("invalid create business command")
	}

	newBusiness, err := business.NewBusiness(createCmd.UserID, createCmd.Name)
	if err != nil {
		log.Error().Err(err).Msg("failed to create business")
		return err
	}

	if err := h.businessWriteRepo.Save(ctx, newBusiness); err != nil {
		log.Error().Err(err).Msg("failed to save business")
		return err
	}

	event := &business.BusinessCreated{
		BusinessID: newBusiness.ID,
		Name:       newBusiness.Name,
		Timestamp:  time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish BusinessCreated event")
		return err
	}

	log.Info().Str("business_id", newBusiness.ID.String()).Msg("business created successfully")
	return nil
}
