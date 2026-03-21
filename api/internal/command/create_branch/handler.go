package create_branch

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/branch"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo branch.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo branch.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateBranchCommand)
	if !ok {
		return ErrInvalidCommand
	}
	now := time.Now()
	b := &branch.Branch{
		ID:        uuid.New(),
		Name:      c.Name,
		City:      c.City,
		Address:   c.Address,
		IsActive:  c.IsActive,
		CreatedAt: now,
		UpdatedAt: now,
	}
	if c.PartnerID != "" {
		pid, err := uuid.Parse(c.PartnerID)
		if err == nil {
			b.PartnerID = &pid
		}
	}
	return h.writeRepo.Save(ctx, b)
}
