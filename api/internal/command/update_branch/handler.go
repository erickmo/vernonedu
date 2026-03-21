package update_branch

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/branch"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	readRepo  branch.ReadRepository
	writeRepo branch.WriteRepository
}

func NewHandler(readRepo branch.ReadRepository, writeRepo branch.WriteRepository) *Handler {
	return &Handler{readRepo: readRepo, writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateBranchCommand)
	if !ok {
		return ErrInvalidCommand
	}

	b, err := h.readRepo.GetByID(ctx, c.ID)
	if err != nil {
		if errors.Is(err, branch.ErrBranchNotFound) {
			return ErrBranchNotFound
		}
		log.Error().Err(err).Msg("failed to get branch for update")
		return err
	}

	b.Name = c.Name
	b.Address = c.Address
	b.City = c.City
	b.Region = c.Region
	b.ContactName = c.ContactName
	b.ContactPhone = c.ContactPhone
	b.Status = c.Status
	b.IsActive = c.Status == "active"
	b.UpdatedAt = time.Now()

	if err := h.writeRepo.Update(ctx, b); err != nil {
		log.Error().Err(err).Msg("failed to update branch")
		return err
	}

	log.Info().Str("branch_id", c.ID.String()).Msg("branch updated")
	return nil
}
