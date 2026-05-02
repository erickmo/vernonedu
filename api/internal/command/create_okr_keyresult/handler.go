package create_okr_keyresult

import (
	"context"
	"fmt"
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
	c, ok := cmd.(*CreateOkrKeyResultCommand)
	if !ok {
		return ErrInvalidCommand
	}
	objID, err := uuid.Parse(c.ObjectiveID)
	if err != nil {
		return fmt.Errorf("invalid objective id: %w", err)
	}
	now := time.Now()
	kr := &okr.KeyResult{
		ID:          uuid.New(),
		ObjectiveID: objID,
		Title:       c.Title,
		Progress:    c.Progress,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	return h.writeRepo.SaveKeyResult(ctx, kr)
}
