package accounting

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type Transaction struct {
	ID                uuid.UUID
	ReferenceNumber   string
	Description       string
	TransactionType   string // income, expense, transfer
	Amount            float64
	DebitAccountCode  string
	CreditAccountCode string
	Category          string
	RelatedEntityType string
	RelatedEntityID   *uuid.UUID
	TransactionDate   time.Time
	Status            string // draft, completed, cancelled
	CreatedBy         *uuid.UUID
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type AccountingStats struct {
	TotalRevenue float64
	TotalExpense float64
	NetProfit    float64
	CashAndBank  float64
	Receivables  float64
	Payables     float64
}

type BudgetItem struct {
	Category     string
	IsPendapatan bool
	Anggaran     float64
	Realisasi    float64
}

type TransactionWriteRepository interface {
	Create(ctx context.Context, t *Transaction) error
}

type TransactionReadRepository interface {
	List(ctx context.Context, offset, limit, month, year int, txType string) ([]*Transaction, int, error)
	GetStats(ctx context.Context, month, year int) (*AccountingStats, error)
	GetBudgetVsActual(ctx context.Context, month, year int) ([]*BudgetItem, error)
}
