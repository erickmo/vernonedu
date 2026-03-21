package accept_delegation

import (
	"context"

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
	c, ok := cmd.(*AcceptDelegationCommand)
	if !ok {
		return ErrInvalidCommand
	}

	d, err := h.writeRepo.GetByID(ctx, c.DelegationID)
	if err != nil {
		log.Error().Err(err).Str("delegation_id", c.DelegationID.String()).Msg("delegation not found for accept")
		return err
	}

	if err := d.Accept(); err != nil {
		return err
	}

	if err := h.writeRepo.Update(ctx, d); err != nil {
		log.Error().Err(err).Msg("failed to update delegation status to accepted")
		return err
	}

	log.Info().Str("delegation_id", d.ID.String()).Msg("delegation accepted")
	return nil
}
