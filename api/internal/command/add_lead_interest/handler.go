package add_lead_interest

import (
	"context"
	"errors"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

var ErrInvalidCommand = errors.New("invalid add lead interest command")

type Handler struct {
	interestWriteRepo lead.InterestWriteRepository
}

func NewHandler(interestWriteRepo lead.InterestWriteRepository) *Handler {
	return &Handler{interestWriteRepo: interestWriteRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*AddLeadInterestCommand)
	if !ok {
		return ErrInvalidCommand
	}
	i := lead.NewLeadInterest(c.LeadID, c.EntityType, c.EntityID)
	if err := h.interestWriteRepo.SaveInterest(ctx, i); err != nil {
		log.Error().Err(err).Msg("failed to save lead interest")
		return err
	}
	log.Info().Str("interest_id", i.ID.String()).Msg("lead interest added")
	return nil
}
