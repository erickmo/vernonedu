package investment

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var ErrInvestmentNotFound = errors.New("investment plan not found")

type InvestmentPlan struct {
	ID          uuid.UUID
	Title       string
	Category    string
	ProposedBy  string
	Amount      int64
	ExpectedROI float64
	ActualSpend int64
	Status      string
	ApprovedBy  string
	Notes       string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type WriteRepository interface {
	Save(ctx context.Context, p *InvestmentPlan) error
	Update(ctx context.Context, p *InvestmentPlan) error
}

type ReadRepository interface {
	List(ctx context.Context, offset, limit int, status string) ([]*InvestmentPlan, int, error)
	Stats(ctx context.Context) (*InvestmentStats, error)
}

type InvestmentStats struct {
	TotalPlanned    int64
	OngoingCount    int
	OngoingAmount   int64
	CompletedCount  int
	CompletedAmount int64
	AvgROI          float64
}
