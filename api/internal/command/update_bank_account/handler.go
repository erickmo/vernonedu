package update_bank_account

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	writeRepo accounting.BankAccountWriteRepository
	readRepo  accounting.BankAccountReadRepository
}

func NewHandler(writeRepo accounting.BankAccountWriteRepository, readRepo accounting.BankAccountReadRepository) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateBankAccountCommand)
	if !ok {
		return ErrInvalidCommand
	}
	existing, err := h.readRepo.Get(ctx, c.ID)
	if err != nil {
		return err
	}
	existing.Name = c.Name
	existing.AccountNumber = c.AccountNumber
	existing.BankName = c.BankName
	existing.BalanceCents = c.BalanceCents
	if c.Currency != "" {
		existing.Currency = c.Currency
	}
	existing.CoaCode = c.CoaCode
	if err := existing.Validate(); err != nil {
		return err
	}
	if err := h.writeRepo.Update(ctx, existing); err != nil {
		log.Error().Err(err).Msg("failed to update bank account")
		return err
	}
	return nil
}
