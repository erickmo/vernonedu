package create_lead

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
	createCmd, ok := cmd.(*CreateLeadCommand)
	if !ok {
		return ErrInvalidCommand
	}

	newLead, err := lead.NewLead(
		createCmd.Name,
		createCmd.Email,
		createCmd.Phone,
		createCmd.Interest,
		createCmd.Source,
		createCmd.Notes,
		createCmd.PicID,
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to create lead")
		return err
	}

	if err := h.leadWriteRepo.Save(ctx, newLead); err != nil {
		log.Error().Err(err).Msg("failed to save lead")
		return err
	}

	event := &lead.LeadCreatedEvent{
		EventType: "LeadCreated",
		LeadID:    newLead.ID,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish LeadCreated event")
		return err
	}

	log.Info().Str("lead_id", newLead.ID.String()).Msg("lead created successfully")
	return nil
}
