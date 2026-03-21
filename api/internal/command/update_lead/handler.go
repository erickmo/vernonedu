package update_lead

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	leadReadRepo  lead.ReadRepository
	leadWriteRepo lead.WriteRepository
	eventBus      eventbus.EventBus
}

func NewHandler(leadWriteRepo lead.WriteRepository, leadReadRepo lead.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		leadReadRepo:  leadReadRepo,
		leadWriteRepo: leadWriteRepo,
		eventBus:      eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	updateCmd, ok := cmd.(*UpdateLeadCommand)
	if !ok {
		return ErrInvalidCommand
	}

	existingLead, err := h.leadReadRepo.GetByID(ctx, updateCmd.ID)
	if err != nil {
		if errors.Is(err, lead.ErrLeadNotFound) {
			return lead.ErrLeadNotFound
		}
		log.Error().Err(err).Str("lead_id", updateCmd.ID.String()).Msg("failed to get lead")
		return err
	}

	existingLead.Name = updateCmd.Name
	existingLead.Email = updateCmd.Email
	existingLead.Phone = updateCmd.Phone
	existingLead.Interest = updateCmd.Interest
	existingLead.Source = updateCmd.Source
	existingLead.Notes = updateCmd.Notes
	existingLead.Status = updateCmd.Status
	existingLead.PicID = updateCmd.PicID
	existingLead.UpdatedAt = time.Now()

	if err := h.leadWriteRepo.Update(ctx, existingLead); err != nil {
		log.Error().Err(err).Msg("failed to update lead")
		return err
	}

	event := &lead.LeadUpdatedEvent{
		EventType: "LeadUpdated",
		LeadID:    existingLead.ID,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish LeadUpdated event")
		return err
	}

	log.Info().Str("lead_id", existingLead.ID.String()).Msg("lead updated successfully")
	return nil
}
