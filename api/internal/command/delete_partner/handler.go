package delete_partner

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/partner"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo partner.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo partner.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeletePartnerCommand)
	if !ok {
		return ErrInvalidCommand
	}
	id, err := uuid.Parse(c.ID)
	if err != nil {
		return ErrInvalidPartnerID
	}
	if err := h.writeRepo.Delete(ctx, id); err != nil {
		return err
	}
	log.Info().Str("partner_id", id.String()).Msg("partner deleted")
	return nil
}
