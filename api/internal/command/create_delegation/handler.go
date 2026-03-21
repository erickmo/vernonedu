package create_delegation

import (
	"context"
	"time"

	"github.com/google/uuid"

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
	c, ok := cmd.(*CreateDelegationCommand)
	if !ok {
		return ErrInvalidCommand
	}
	now := time.Now()
	d := &delegation.Delegation{
		ID:               uuid.New(),
		Title:            c.Title,
		Type:             c.Type,
		Description:      c.Description,
		AssignedToName:   c.AssignedToName,
		AssignedByName:   c.AssignedByName,
		Priority:         c.Priority,
		Status:           "pending",
		LinkedEntityID:   c.LinkedEntityID,
		LinkedEntityType: c.LinkedEntityType,
		CreatedAt:        now,
		UpdatedAt:        now,
	}
	if d.Type == "" {
		d.Type = "delegate_task"
	}
	if d.Priority == "" {
		d.Priority = "medium"
	}
	if c.AssignedToID != "" {
		aid, err := uuid.Parse(c.AssignedToID)
		if err == nil {
			d.AssignedToID = &aid
		}
	}
	if c.AssignedByID != "" {
		bid, err := uuid.Parse(c.AssignedByID)
		if err == nil {
			d.AssignedByID = &bid
		}
	}
	if c.Deadline != "" {
		dl, err := time.Parse(time.RFC3339, c.Deadline)
		if err == nil {
			d.Deadline = &dl
		}
	}
	return h.writeRepo.Save(ctx, d)
}
