package create_okr_objective

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/okr"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo okr.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo okr.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateOkrObjectiveCommand)
	if !ok {
		return ErrInvalidCommand
	}
	now := time.Now()
	obj := &okr.Objective{
		ID:        uuid.New(),
		Title:     c.Title,
		OwnerName: c.OwnerName,
		Period:    c.Period,
		Level:     c.Level,
		Status:    c.Status,
		Progress:  0,
		CreatedAt: now,
		UpdatedAt: now,
	}
	if obj.Level == "" {
		obj.Level = "company"
	}
	if obj.Status == "" {
		obj.Status = "on_track"
	}
	if c.OwnerID != "" {
		oid, err := uuid.Parse(c.OwnerID)
		if err == nil {
			obj.OwnerID = &oid
		}
	}
	return h.writeRepo.Save(ctx, obj)
}
