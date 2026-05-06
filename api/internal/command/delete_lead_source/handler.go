package delete_lead_source

import (
	"context"
	"errors"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

var ErrInvalidCommand = errors.New("invalid delete lead source command")

type Handler struct {
	sourceWriteRepo lead.SourceWriteRepository
}

func NewHandler(sourceWriteRepo lead.SourceWriteRepository) *Handler {
	return &Handler{sourceWriteRepo: sourceWriteRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteLeadSourceCommand)
	if !ok {
		return ErrInvalidCommand
	}
	if err := h.sourceWriteRepo.DeleteSource(ctx, c.ID); err != nil {
		log.Error().Err(err).Str("source_id", c.ID.String()).Msg("failed to delete lead source")
		return err
	}
	log.Info().Str("source_id", c.ID.String()).Msg("lead source deleted")
	return nil
}
