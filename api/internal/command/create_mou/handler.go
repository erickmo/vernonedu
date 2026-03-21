package create_mou

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
	c, ok := cmd.(*CreateMOUCommand)
	if !ok {
		return ErrInvalidCommand
	}
	partnerID, err := uuid.Parse(c.PartnerIDStr)
	if err != nil {
		return ErrInvalidPartnerID
	}
	now := time.Now()
	m := &partner.MOU{
		ID:             uuid.New(),
		PartnerID:      partnerID,
		DocumentNumber: c.DocumentNumber,
		StartDate:      c.StartDate,
		EndDate:        c.EndDate,
		Notes:          c.Notes,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
	return h.writeRepo.SaveMOU(ctx, m)
}
