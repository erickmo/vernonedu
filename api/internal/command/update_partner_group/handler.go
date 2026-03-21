package update_partner_group

import (
	"context"
	"time"

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
	c, ok := cmd.(*UpdatePartnerGroupCommand)
	if !ok {
		return ErrInvalidCommand
	}
	id, err := uuid.Parse(c.ID)
	if err != nil {
		return ErrInvalidGroupID
	}
	g := &partner.PartnerGroup{
		ID:          id,
		Name:        c.Name,
		Description: c.Description,
		UpdatedAt:   time.Now(),
	}
	if err := h.writeRepo.UpdateGroup(ctx, g); err != nil {
		return err
	}
	log.Info().Str("group_id", id.String()).Msg("partner group updated")
	return nil
}
