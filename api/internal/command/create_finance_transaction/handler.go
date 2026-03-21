package create_finance_transaction

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/finance"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo finance.TransactionWriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo finance.TransactionWriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateFinanceTransactionCommand)
	if !ok {
		return ErrInvalidCommand
	}

	txn, err := finance.NewTransaction(
		c.Description,
		c.AccountDebitID, c.AccountCreditID,
		c.BranchID, c.CreatedBy,
		c.Amount,
		c.Reference, c.AttachmentURL,
	)
	if err != nil {
		return err
	}

	// Auto-create double-entry journal entries
	debitEntry := finance.NewJournalEntry(txn.ID, txn.AccountDebitID, txn.Amount, 0, txn.Description, finance.JournalSourceManual)
	creditEntry := finance.NewJournalEntry(txn.ID, txn.AccountCreditID, 0, txn.Amount, txn.Description, finance.JournalSourceManual)

	if err := h.writeRepo.Save(ctx, txn, []*finance.JournalEntry{debitEntry, creditEntry}); err != nil {
		log.Error().Err(err).Msg("failed to save finance transaction")
		return err
	}

	event := &finance.TransactionCreatedEvent{
		EventType:     "FinanceTransactionCreated",
		TransactionID: txn.ID,
		Timestamp:     time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish FinanceTransactionCreated event")
	}

	log.Info().Str("transaction_id", txn.ID.String()).Msg("finance transaction created")
	return nil
}
