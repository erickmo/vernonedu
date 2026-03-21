package update_delegation

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/delegation"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo delegation.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo delegation.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateDelegationCommand)
	if !ok {
		return ErrInvalidCommand
	}

	d, err := h.writeRepo.GetByID(ctx, c.DelegationID)
	if err != nil {
		log.Error().Err(err).Str("delegation_id", c.DelegationID.String()).Msg("delegation not found for update")
		return err
	}

	if c.Title != "" {
		d.Title = c.Title
	}
	if c.Description != "" {
		d.Description = c.Description
	}
	if c.DueDate != "" {
		dl, err := time.Parse(time.RFC3339, c.DueDate)
		if err == nil {
			d.DueDate = &dl
		}
	}
	if c.Priority != "" {
		if !delegation.ValidPriority(c.Priority) {
			return delegation.ErrInvalidPriority
		}
		d.Priority = delegation.Priority(c.Priority)
	}
	if c.Notes != "" {
		n := c.Notes
		d.Notes = &n
	}

	d.UpdatedAt = time.Now()

	if err := h.writeRepo.Update(ctx, d); err != nil {
		log.Error().Err(err).Msg("failed to update delegation")
		return err
	}

	log.Info().Str("delegation_id", d.ID.String()).Msg("delegation updated")
	return nil
}
