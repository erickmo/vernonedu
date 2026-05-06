package update_franchisee

import (
	"context"
	"time"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	writeRepo franchise.WriteRepository
	readRepo  franchise.ReadRepository
}

func NewHandler(writeRepo franchise.WriteRepository, readRepo franchise.ReadRepository) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateFranchiseeCommand)
	if !ok {
		return ErrInvalidCommand
	}
	f, err := h.readRepo.GetFranchiseeByID(ctx, c.ID)
	if err != nil {
		return err
	}
	f.Name = c.Name
	f.BranchName = c.BranchName
	f.Location = c.Location
	f.Contact = c.Contact
	f.Status = c.Status
	f.UpdatedAt = time.Now()
	return h.writeRepo.UpdateFranchisee(ctx, f)
}
