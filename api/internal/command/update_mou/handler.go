package update_mou

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/partner"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	readRepo  partner.ReadRepository
	writeRepo partner.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(readRepo partner.ReadRepository, writeRepo partner.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{readRepo: readRepo, writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateMOUCommand)
	if !ok {
		return ErrInvalidCommand
	}
	id, err := uuid.Parse(c.ID)
	if err != nil {
		return ErrInvalidMOUID
	}
	m, err := h.readRepo.GetMOUByID(ctx, id)
	if err != nil {
		return ErrMOUNotFound
	}
	if c.DocumentNumber != "" {
		m.DocumentNumber = c.DocumentNumber
	}
	if c.Title != "" {
		m.Title = c.Title
	}
	if c.StartDate != "" {
		m.StartDate = c.StartDate
	}
	if c.EndDate != "" {
		m.EndDate = c.EndDate
	}
	if c.Status != "" {
		m.Status = c.Status
	}
	if c.DocumentURL != "" {
		m.DocumentURL = c.DocumentURL
	}
	if c.Notes != "" {
		m.Notes = c.Notes
	}
	if err := h.writeRepo.UpdateMOU(ctx, m); err != nil {
		return err
	}
	log.Info().Str("mou_id", id.String()).Msg("mou updated")
	return nil
}
