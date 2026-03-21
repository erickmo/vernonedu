package complete_delegation

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
	c, ok := cmd.(*CompleteDelegationCommand)
	if !ok {
		return ErrInvalidCommand
	}

	d, err := h.writeRepo.GetByID(ctx, c.DelegationID)
	if err != nil {
		log.Error().Err(err).Str("delegation_id", c.DelegationID.String()).Msg("delegation not found for complete")
		return err
	}

	var notes *string
	if c.Notes != "" {
		n := c.Notes
		notes = &n
	}

	if err := d.Complete(notes); err != nil {
		return err
	}

	if err := h.writeRepo.Update(ctx, d); err != nil {
		log.Error().Err(err).Msg("failed to update delegation status to completed")
		return err
	}

	event := &delegation.DelegationCompletedEvent{
		DelegationID:   d.ID,
		Title:          d.Title,
		RequestedByID:  d.RequestedByID,
		AssignedToName: d.AssignedToName,
		Timestamp:      time.Now().Unix(),
	}
	if d.AssignedToID != nil {
		event.AssignedToID = *d.AssignedToID
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish DelegationCompleted event")
	}

	log.Info().Str("delegation_id", d.ID.String()).Msg("delegation completed")
	return nil
}
