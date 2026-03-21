package create_partner

import (
	"context"
	"time"

	"github.com/google/uuid"

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
	c, ok := cmd.(*CreatePartnerCommand)
	if !ok {
		return ErrInvalidCommand
	}
	now := time.Now()
	p := &partner.Partner{
		ID:            uuid.New(),
		Name:          c.Name,
		Industry:      c.Industry,
		Status:        c.Status,
		GroupID:       c.GroupID,
		ContactEmail:  c.ContactEmail,
		ContactPhone:  c.ContactPhone,
		ContactPerson: c.ContactPerson,
		Website:       c.Website,
		Address:       c.Address,
		Notes:         c.Notes,
		CreatedAt:     now,
		UpdatedAt:     now,
	}
	if p.Status == "" {
		p.Status = "prospect"
	}
	return h.writeRepo.Save(ctx, p)
}
