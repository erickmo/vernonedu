package assignbatchfacilitator

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// AssignFacilitatorWriter is the thin write interface needed by this command.
type AssignFacilitatorWriter interface {
	AssignFacilitator(ctx context.Context, batchID uuid.UUID, facilitatorID *uuid.UUID) error
}

type Handler struct {
	repo  AssignFacilitatorWriter
	event eventbus.EventBus
}

func NewHandler(repo AssignFacilitatorWriter, event eventbus.EventBus) *Handler {
	return &Handler{repo: repo, event: event}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*AssignBatchFacilitatorCommand)
	if !ok {
		return fmt.Errorf("invalid command type")
	}

	batchID, err := uuid.Parse(c.BatchID)
	if err != nil {
		return fmt.Errorf("invalid batch id: %w", err)
	}

	var facilitatorID *uuid.UUID
	if c.FacilitatorID != "" {
		fid, err := uuid.Parse(c.FacilitatorID)
		if err != nil {
			return fmt.Errorf("invalid facilitator id: %w", err)
		}
		facilitatorID = &fid
	}

	return h.repo.AssignFacilitator(ctx, batchID, facilitatorID)
}
