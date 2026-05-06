package create_lead_source

import (
	"context"
	"errors"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

var ErrInvalidCommand = errors.New("invalid create lead source command")

type Handler struct {
	sourceWriteRepo lead.SourceWriteRepository
}

func NewHandler(sourceWriteRepo lead.SourceWriteRepository) *Handler {
	return &Handler{sourceWriteRepo: sourceWriteRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateLeadSourceCommand)
	if !ok {
		return ErrInvalidCommand
	}
	s := lead.NewLeadSource(c.Name)
	if err := h.sourceWriteRepo.SaveSource(ctx, s); err != nil {
		log.Error().Err(err).Msg("failed to save lead source")
		return err
	}
	log.Info().Str("source_id", s.ID.String()).Msg("lead source created")
	return nil
}
