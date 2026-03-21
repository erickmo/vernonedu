package create_partner_group

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
	c, ok := cmd.(*CreatePartnerGroupCommand)
	if !ok {
		return ErrInvalidCommand
	}
	now := time.Now()
	g := &partner.PartnerGroup{
		ID:          uuid.New(),
		Name:        c.Name,
		Description: c.Description,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	if err := h.writeRepo.SaveGroup(ctx, g); err != nil {
		return err
	}
	log.Info().Str("group_id", g.ID.String()).Str("name", g.Name).Msg("partner group created")
	return nil
}
