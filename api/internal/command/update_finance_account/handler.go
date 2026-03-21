package update_finance_account

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
	readRepo  finance.AccountReadRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo finance.AccountWriteRepository, readRepo finance.AccountReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateFinanceAccountCommand)
	if !ok {
		return ErrInvalidCommand
	}

	acct, err := h.readRepo.GetByID(ctx, c.ID)
	if err != nil {
		return err
	}

	acct.Name = c.Name
	acct.IsActive = c.IsActive
	acct.UpdatedAt = time.Now()

	if err := h.writeRepo.Update(ctx, acct); err != nil {
		log.Error().Err(err).Msg("failed to update finance account")
		return err
	}

	log.Info().Str("account_id", acct.ID.String()).Msg("finance account updated")
	return nil
}
