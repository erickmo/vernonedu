package delete_bank_account

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	writeRepo accounting.BankAccountWriteRepository
}

func NewHandler(writeRepo accounting.BankAccountWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteBankAccountCommand)
	if !ok {
		return ErrInvalidCommand
	}
	if err := h.writeRepo.SetActive(ctx, c.ID, false); err != nil {
		log.Error().Err(err).Str("id", c.ID.String()).Msg("failed to deactivate bank account")
		return err
	}
	return nil
}
