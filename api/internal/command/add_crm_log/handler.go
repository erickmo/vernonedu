package add_crm_log

import (
	"context"
	"errors"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	leadReadRepo lead.ReadRepository
	crmLogRepo   lead.CrmLogWriteRepository
	eventBus     eventbus.EventBus
}

func NewHandler(leadReadRepo lead.ReadRepository, crmLogRepo lead.CrmLogWriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		leadReadRepo: leadReadRepo,
		crmLogRepo:   crmLogRepo,
		eventBus:     eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	addCmd, ok := cmd.(*AddCrmLogCommand)
	if !ok {
		return ErrInvalidCommand
	}

	_, err := h.leadReadRepo.GetByID(ctx, addCmd.LeadID)
	if err != nil {
		if errors.Is(err, lead.ErrLeadNotFound) {
			return lead.ErrLeadNotFound
		}
		log.Error().Err(err).Str("lead_id", addCmd.LeadID.String()).Msg("failed to get lead")
		return err
	}

	crmLog := lead.NewCrmLog(
		addCmd.LeadID,
		addCmd.ContactedByID,
		addCmd.ContactMethod,
		addCmd.Response,
		addCmd.FollowUpDate,
	)

	if err := h.crmLogRepo.SaveCrmLog(ctx, crmLog); err != nil {
		log.Error().Err(err).Msg("failed to save crm log")
		return err
	}

	log.Info().
		Str("lead_id", addCmd.LeadID.String()).
		Str("crm_log_id", crmLog.ID.String()).
		Msg("crm log added successfully")
	return nil
}
