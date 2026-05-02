package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type coaRecord struct {
	ID          uuid.UUID `db:"id"`
	Code        string    `db:"code"`
	Name        string    `db:"name"`
	AccountType string    `db:"account_type"`
	ParentCode  string    `db:"parent_code"`
	IsActive    bool      `db:"is_active"`
	CreatedAt   time.Time `db:"created_at"`
}

type CoaRepository struct {
	db *sqlx.DB
}

func NewCoaRepository(db *sqlx.DB) *CoaRepository {
	return &CoaRepository{db: db}
}

// GetBalance returns the running balance for coaCode based on completed
// accounting_transactions, optionally filtered by branch and date.
func (r *CoaRepository) GetBalance(ctx context.Context, coaCode string, branchID *uuid.UUID, dateTo *time.Time) (*accounting.BalanceByAccount, error) {
	const q = `SELECT
		COALESCE(SUM(
			CASE
				WHEN debit_account_code=$1 THEN amount
				WHEN credit_account_code=$1 THEN -amount
				ELSE 0
			END
		),0) AS balance,
		COALESCE((SELECT account_type FROM chart_of_accounts WHERE code=$1),'') AS account_type
		FROM accounting_transactions
		WHERE status='completed'
		  AND ($1 IN (debit_account_code, credit_account_code))
		  AND ($2::uuid IS NULL OR branch_id=$2)
		  AND ($3::date IS NULL OR transaction_date <= $3)`
	type row struct {
		Balance     float64 `db:"balance"`
		AccountType string  `db:"account_type"`
	}
	var rec row
	if err := r.db.GetContext(ctx, &rec, q, coaCode, branchID, dateTo); err != nil {
		return nil, fmt.Errorf("failed to get balance: %w", err)
	}
	return &accounting.BalanceByAccount{
		CoaCode:      coaCode,
		AccountType:  rec.AccountType,
		BalanceCents: int64(rec.Balance * 100),
	}, nil
}

func (r *CoaRepository) List(ctx context.Context) ([]*accounting.ChartOfAccount, error) {
	var rows []coaRecord
	err := r.db.SelectContext(ctx, &rows,
		`SELECT id, code, name, account_type, COALESCE(parent_code,'') AS parent_code, is_active, created_at
		 FROM chart_of_accounts
		 WHERE is_active = true
		 ORDER BY code`)
	if err != nil {
		return nil, fmt.Errorf("failed to list chart of accounts: %w", err)
	}

	out := make([]*accounting.ChartOfAccount, len(rows))
	for i, row := range rows {
		out[i] = &accounting.ChartOfAccount{
			ID:          row.ID,
			Code:        row.Code,
			Name:        row.Name,
			AccountType: row.AccountType,
			ParentCode:  row.ParentCode,
			IsActive:    row.IsActive,
			CreatedAt:   row.CreatedAt,
		}
	}
	return out, nil
}
