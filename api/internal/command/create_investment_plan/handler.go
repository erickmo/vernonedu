package create_investment_plan

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
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo investment.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateInvestmentPlanCommand)
	if !ok {
		return ErrInvalidCommand
	}
	now := time.Now()
	p := &investment.InvestmentPlan{
		ID:          uuid.New(),
		Title:       c.Title,
		Category:    c.Category,
		ProposedBy:  c.ProposedBy,
		Amount:      c.Amount,
		ExpectedROI: c.ExpectedROI,
		ActualSpend: 0,
		Status:      c.Status,
		Notes:       c.Notes,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	if p.Status == "" {
		p.Status = "draft"
	}
	return h.writeRepo.Save(ctx, p)
}
