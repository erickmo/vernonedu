package update_business

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

type UpdateBusinessCommand struct {
	BusinessID uuid.UUID `validate:"required"`
	Name       string    `validate:"required,min=1"`
}

type Handler struct {
	businessReadRepo  business.ReadRepository
	businessWriteRepo business.WriteRepository
	eventBus          eventbus.EventBus
}

func NewHandler(businessReadRepo business.ReadRepository, businessWriteRepo business.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		businessReadRepo:  businessReadRepo,
		businessWriteRepo: businessWriteRepo,
		eventBus:          eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	updateCmd, ok := cmd.(*UpdateBusinessCommand)
	if !ok {
		return errors.New("invalid update business command")
	}

	existingBusiness, err := h.businessReadRepo.GetByID(ctx, updateCmd.BusinessID)
	if err != nil {
		if errors.Is(err, business.ErrBusinessNotFound) {
			return business.ErrBusinessNotFound
		}
		log.Error().Err(err).Str("business_id", updateCmd.BusinessID.String()).Msg("failed to get business")
		return err
	}

	if err := existingBusiness.UpdateName(updateCmd.Name); err != nil {
		log.Error().Err(err).Msg("failed to update business name")
		return err
	}

	if err := h.businessWriteRepo.Update(ctx, existingBusiness); err != nil {
		log.Error().Err(err).Msg("failed to update business")
		return err
	}

	event := &business.BusinessUpdated{
		BusinessID: existingBusiness.ID,
		Name:       existingBusiness.Name,
		Timestamp:  time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish BusinessUpdated event")
		return err
	}

	log.Info().Str("business_id", existingBusiness.ID.String()).Msg("business updated successfully")
	return nil
}
