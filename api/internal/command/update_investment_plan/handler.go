package update_investment_plan

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/investment"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo investment.WriteRepository
	readRepo  investment.ReadRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo investment.WriteRepository, readRepo investment.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateInvestmentPlanCommand)
	if !ok {
		return ErrInvalidCommand
	}
	id, err := uuid.Parse(c.ID)
	if err != nil {
		return ErrInvalidID
	}
	existing, err := h.readRepo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	existing.Title = c.Title
	existing.Category = c.Category
	existing.ProposedBy = c.ProposedBy
	existing.Amount = c.Amount
	existing.ExpectedROI = c.ExpectedROI
	existing.ActualSpend = c.ActualSpend
	if c.Status != "" {
		existing.Status = c.Status
	}
	existing.ApprovedBy = c.ApprovedBy
	existing.Notes = c.Notes
	existing.UpdatedAt = time.Now()
	return h.writeRepo.Update(ctx, existing)
}
