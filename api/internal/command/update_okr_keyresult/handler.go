package update_okr_keyresult

import (
	"context"
	"fmt"

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
	c, ok := cmd.(*UpdateOkrKeyResultCommand)
	if !ok {
		return ErrInvalidCommand
	}
	id, err := uuid.Parse(c.ID)
	if err != nil {
		return fmt.Errorf("invalid key result id: %w", err)
	}
	existing, err := h.writeRepo.GetKeyResult(ctx, id)
	if err != nil {
		return err
	}
	if c.Title != nil {
		existing.Title = *c.Title
	}
	if c.Progress != nil {
		existing.Progress = *c.Progress
	}
	return h.writeRepo.UpdateKeyResult(ctx, existing)
}
