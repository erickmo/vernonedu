package delete_transaction

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	writeRepo accounting.TransactionWriteRepository
}

func NewHandler(writeRepo accounting.TransactionWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteTransactionCommand)
	if !ok {
		return ErrInvalidCommand
	}
	if err := h.writeRepo.SoftDelete(ctx, c.ID); err != nil {
		log.Error().Err(err).Str("id", c.ID.String()).Msg("failed to delete transaction")
		return err
	}
	return nil
}
