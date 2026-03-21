package mark_payable_paid

import (
	"context"
	"fmt"
	"time"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/payable"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	readRepo  payable.ReadRepository
	writeRepo payable.WriteRepository
	txRepo    accounting.TransactionWriteRepository
	bus       eventbus.EventBus
}

func NewHandler(
	readRepo payable.ReadRepository,
	writeRepo payable.WriteRepository,
	txRepo accounting.TransactionWriteRepository,
	bus eventbus.EventBus,
) *Handler {
	return &Handler{readRepo: readRepo, writeRepo: writeRepo, txRepo: txRepo, bus: bus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*MarkPayablePaidCommand)
	if !ok || c == nil {
		return ErrInvalidCommand
	}

	p, err := h.readRepo.GetByID(ctx, c.ID)
	if err != nil {
		return err
	}

	if p.Status != payable.StatusApproved {
		return ErrNotApproved
	}

	cashAccount := c.AccountCode
	if cashAccount == "" {
		cashAccount = payable.AccountKas
	}

	now := time.Now()
	if err := h.writeRepo.UpdateStatus(ctx, c.ID, payable.StatusPaid, &now, c.PaymentProof); err != nil {
		return err
	}

	// Journal entry: Debit hutang / Credit kas
	hutangCode := payable.HutangAccount(p.Type)
	tx := &accounting.Transaction{
		ReferenceNumber:   fmt.Sprintf("PAY-%s", now.Format("20060102-150405")),
		Description:       fmt.Sprintf("Pembayaran %s - %s", p.Type, p.RecipientName),
		TransactionType:   "expense",
		Amount:            float64(p.Amount),
		DebitAccountCode:  hutangCode,
		CreditAccountCode: cashAccount,
		Category:          "payable_payment",
		RelatedEntityType: "payable",
		RelatedEntityID:   &p.ID,
		TransactionDate:   now,
		Status:            "completed",
	}
	if err := h.txRepo.Create(ctx, tx); err != nil {
		return err
	}

	_ = h.bus.Publish(ctx, &payable.PayablePaidEvent{
		EventType:   "PayablePaid",
		PayableID:   p.ID,
		PayableType: p.Type,
		RecipientID: p.RecipientID,
		Amount:      p.Amount,
		Timestamp:   now.Unix(),
	})

	return nil
}
