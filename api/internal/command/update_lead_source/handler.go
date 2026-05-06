package update_lead_source

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/lead"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

var ErrInvalidCommand = errors.New("invalid update lead source command")

type Handler struct {
	sourceReadRepo  lead.SourceReadRepository
	sourceWriteRepo lead.SourceWriteRepository
}

func NewHandler(sourceWriteRepo lead.SourceWriteRepository, sourceReadRepo lead.SourceReadRepository) *Handler {
	return &Handler{sourceWriteRepo: sourceWriteRepo, sourceReadRepo: sourceReadRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateLeadSourceCommand)
	if !ok {
		return ErrInvalidCommand
	}
	s, err := h.sourceReadRepo.GetSourceByID(ctx, c.ID)
	if err != nil {
		return lead.ErrSourceNotFound
	}
	s.Name = c.Name
	s.IsActive = c.IsActive
	s.UpdatedAt = time.Now()
	if err := h.sourceWriteRepo.UpdateSource(ctx, s); err != nil {
		log.Error().Err(err).Msg("failed to update lead source")
		return err
	}
	log.Info().Str("source_id", s.ID.String()).Msg("lead source updated")
	return nil
}
