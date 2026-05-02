package create_bank_account

import (
	"context"
	"time"

	"github.com/google/uuid"
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
	c, ok := cmd.(*CreateBankAccountCommand)
	if !ok {
		return ErrInvalidCommand
	}
	now := time.Now()
	id := c.ID
	if id == uuid.Nil {
		id = uuid.New()
	}
	currency := c.Currency
	if currency == "" {
		currency = accounting.CurrencyIDR
	}
	b := &accounting.BankAccount{
		ID:            id,
		BranchID:      c.BranchID,
		Name:          c.Name,
		AccountNumber: c.AccountNumber,
		BankName:      c.BankName,
		BalanceCents:  c.BalanceCents,
		Currency:      currency,
		CoaCode:       c.CoaCode,
		IsActive:      true,
		CreatedBy:     c.CreatedBy,
		CreatedAt:     now,
		UpdatedAt:     now,
	}
	if err := b.Validate(); err != nil {
		return err
	}
	if err := h.writeRepo.Create(ctx, b); err != nil {
		log.Error().Err(err).Msg("failed to create bank account")
		return err
	}
	log.Info().Str("bank_account_id", b.ID.String()).Msg("bank account created")
	return nil
}
