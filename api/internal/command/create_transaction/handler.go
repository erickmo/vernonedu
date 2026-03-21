package create_transaction

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo accounting.TransactionWriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo accounting.TransactionWriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		writeRepo: writeRepo,
		eventBus:  eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateTransactionCommand)
	if !ok {
		return ErrInvalidCommand
	}

	txDate := time.Now()
	if c.TransactionDate != "" {
		parsed, err := time.Parse("2006-01-02", c.TransactionDate)
		if err == nil {
			txDate = parsed
		}
	}

	status := c.Status
	if status == "" {
		status = "completed"
	}

	t := &accounting.Transaction{
		ID:                uuid.New(),
		Description:       c.Description,
		TransactionType:   c.TransactionType,
		Amount:            c.Amount,
		DebitAccountCode:  c.DebitAccountCode,
		CreditAccountCode: c.CreditAccountCode,
		Category:          c.Category,
		TransactionDate:   txDate,
		Status:            status,
		CreatedAt:         time.Now(),
		UpdatedAt:         time.Now(),
	}

	if err := h.writeRepo.Create(ctx, t); err != nil {
		log.Error().Err(err).Msg("failed to create transaction")
		return err
	}

	log.Info().Str("transaction_id", t.ID.String()).Msg("transaction created successfully")
	return nil
}
