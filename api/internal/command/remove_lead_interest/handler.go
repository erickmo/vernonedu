package remove_lead_interest

import (
	"context"
	"errors"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

var ErrInvalidCommand = errors.New("invalid remove lead interest command")

type Handler struct {
	interestWriteRepo lead.InterestWriteRepository
}

func NewHandler(interestWriteRepo lead.InterestWriteRepository) *Handler {
	return &Handler{interestWriteRepo: interestWriteRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*RemoveLeadInterestCommand)
	if !ok {
		return ErrInvalidCommand
	}
	if err := h.interestWriteRepo.DeleteInterest(ctx, c.LeadID, c.InterestID); err != nil {
		log.Error().Err(err).Msg("failed to delete lead interest")
		return err
	}
	log.Info().Str("interest_id", c.InterestID.String()).Msg("lead interest removed")
	return nil
}
