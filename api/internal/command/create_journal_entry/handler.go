package create_journal_entry

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/finance"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo finance.JournalWriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo finance.JournalWriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateJournalEntryCommand)
	if !ok {
		return ErrInvalidCommand
	}

	entry := finance.NewJournalEntry(
		c.TransactionID, c.AccountID,
		c.Debit, c.Credit,
		c.Description, finance.JournalSource(c.Source),
	)

	if err := h.writeRepo.Save(ctx, entry); err != nil {
		log.Error().Err(err).Msg("failed to save journal entry")
		return err
	}

	log.Info().Str("journal_entry_id", entry.ID.String()).Msg("journal entry created")
	return nil
}
