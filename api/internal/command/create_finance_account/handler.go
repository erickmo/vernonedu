package create_finance_account

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/finance"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo finance.AccountWriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo finance.AccountWriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateFinanceAccountCommand)
	if !ok {
		return ErrInvalidCommand
	}

	acctType, err := finance.ParseAccountType(c.Type)
	if err != nil {
		return err
	}

	acct, err := finance.NewChartOfAccount(c.Code, c.Name, acctType, c.ParentID, c.BranchID)
	if err != nil {
		return err
	}

	if err := h.writeRepo.Save(ctx, acct); err != nil {
		log.Error().Err(err).Msg("failed to save finance account")
		return err
	}

	event := &finance.AccountCreatedEvent{
		EventType: "FinanceAccountCreated",
		AccountID: acct.ID,
		Timestamp: time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish FinanceAccountCreated event")
	}

	log.Info().Str("account_id", acct.ID.String()).Msg("finance account created")
	return nil
}
