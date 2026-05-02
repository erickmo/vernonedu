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
	BranchID          *uuid.UUID
	BankAccountID     *uuid.UUID
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

// TransactionUpdate carries mutable fields for update_transaction.
type TransactionUpdate struct {
	ID          uuid.UUID
	Description string
	Category    string
}

type TransactionWriteRepository interface {
	Create(ctx context.Context, t *Transaction) error
	Update(ctx context.Context, u *TransactionUpdate) error
	SoftDelete(ctx context.Context, id uuid.UUID) error
}

type TransactionReadRepository interface {
	List(ctx context.Context, offset, limit, month, year int, txType string) ([]*Transaction, int, error)
	GetStats(ctx context.Context, month, year int) (*AccountingStats, error)
	GetBudgetVsActual(ctx context.Context, month, year int) ([]*BudgetItem, error)
}
