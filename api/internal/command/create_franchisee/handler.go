package create_franchisee

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	writeRepo franchise.WriteRepository
}

func NewHandler(writeRepo franchise.WriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateFranchiseeCommand)
	if !ok {
		return ErrInvalidCommand
	}
	now := time.Now()
	status := c.Status
	if status == "" {
		status = "active"
	}
	f := &franchise.Franchisee{
		ID:         uuid.New(),
		Name:       c.Name,
		BranchName: c.BranchName,
		Location:   c.Location,
		Contact:    c.Contact,
		Status:     status,
		CreatedBy:  c.CreatedBy,
		CreatedAt:  now,
		UpdatedAt:  now,
	}
	return h.writeRepo.SaveFranchisee(ctx, f)
}
