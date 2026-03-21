package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type transactionRecord struct {
	ID                uuid.UUID  `db:"id"`
	ReferenceNumber   string     `db:"reference_number"`
	Description       string     `db:"description"`
	TransactionType   string     `db:"transaction_type"`
	Amount            float64    `db:"amount"`
	DebitAccountCode  string     `db:"debit_account_code"`
	CreditAccountCode string     `db:"credit_account_code"`
	Category          string     `db:"category"`
	RelatedEntityType string     `db:"related_entity_type"`
	RelatedEntityID   *uuid.UUID `db:"related_entity_id"`
	TransactionDate   time.Time  `db:"transaction_date"`
	Status            string     `db:"status"`
	CreatedBy         *uuid.UUID `db:"created_by"`
	CreatedAt         time.Time  `db:"created_at"`
	UpdatedAt         time.Time  `db:"updated_at"`
}

type AccountingTransactionRepository struct {
	db *sqlx.DB
}

func NewAccountingTransactionRepository(db *sqlx.DB) *AccountingTransactionRepository {
	return &AccountingTransactionRepository{db: db}
}

func (r *AccountingTransactionRepository) Create(ctx context.Context, t *accounting.Transaction) error {
	query := `
		INSERT INTO accounting_transactions
			(id, reference_number, description, transaction_type, amount,
			 debit_account_code, credit_account_code, category,
			 related_entity_type, related_entity_id,
			 transaction_date, status, created_by, created_at, updated_at)
		VALUES
			($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
	`
	_, err := r.db.ExecContext(ctx, query,
		t.ID, t.ReferenceNumber, t.Description, t.TransactionType, t.Amount,
		t.DebitAccountCode, t.CreditAccountCode, t.Category,
		t.RelatedEntityType, t.RelatedEntityID,
		t.TransactionDate, t.Status, t.CreatedBy, t.CreatedAt, t.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to create transaction: %w", err)
	}
	return nil
}

func (r *AccountingTransactionRepository) List(ctx context.Context, offset, limit, month, year int, txType string) ([]*accounting.Transaction, int, error) {
	var total int
	countQuery := `
		SELECT COUNT(*) FROM accounting_transactions
		WHERE ($1=0 OR EXTRACT(MONTH FROM transaction_date)=$1)
		  AND ($2=0 OR EXTRACT(YEAR FROM transaction_date)=$2)
		  AND ($3='' OR transaction_type=$3)
	`
	if err := r.db.GetContext(ctx, &total, countQuery, month, year, txType); err != nil {
		return nil, 0, fmt.Errorf("failed to count transactions: %w", err)
	}

	var rows []transactionRecord
	query := `
		SELECT id, COALESCE(reference_number,'') AS reference_number, description, transaction_type, amount,
		       COALESCE(debit_account_code,'') AS debit_account_code,
		       COALESCE(credit_account_code,'') AS credit_account_code,
		       COALESCE(category,'') AS category,
		       COALESCE(related_entity_type,'') AS related_entity_type,
		       related_entity_id, transaction_date, status, created_by, created_at, updated_at
		FROM accounting_transactions
		WHERE ($1=0 OR EXTRACT(MONTH FROM transaction_date)=$1)
		  AND ($2=0 OR EXTRACT(YEAR FROM transaction_date)=$2)
		  AND ($3='' OR transaction_type=$3)
		ORDER BY transaction_date DESC, created_at DESC
		LIMIT $4 OFFSET $5
	`
	if err := r.db.SelectContext(ctx, &rows, query, month, year, txType, limit, offset); err != nil {
		return nil, 0, fmt.Errorf("failed to list transactions: %w", err)
	}

	out := make([]*accounting.Transaction, len(rows))
	for i, row := range rows {
		out[i] = &accounting.Transaction{
			ID:                row.ID,
			ReferenceNumber:   row.ReferenceNumber,
			Description:       row.Description,
			TransactionType:   row.TransactionType,
			Amount:            row.Amount,
			DebitAccountCode:  row.DebitAccountCode,
			CreditAccountCode: row.CreditAccountCode,
			Category:          row.Category,
			RelatedEntityType: row.RelatedEntityType,
			RelatedEntityID:   row.RelatedEntityID,
			TransactionDate:   row.TransactionDate,
			Status:            row.Status,
			CreatedBy:         row.CreatedBy,
			CreatedAt:         row.CreatedAt,
			UpdatedAt:         row.UpdatedAt,
		}
	}
	return out, total, nil
}

func (r *AccountingTransactionRepository) GetStats(ctx context.Context, month, year int) (*accounting.AccountingStats, error) {
	type statsRow struct {
		TxType string  `db:"transaction_type"`
		Total  float64 `db:"total"`
	}
	var rows []statsRow
	query := `
		SELECT transaction_type, COALESCE(SUM(amount),0) AS total
		FROM accounting_transactions
		WHERE status = 'completed'
		  AND ($1=0 OR EXTRACT(MONTH FROM transaction_date)=$1)
		  AND ($2=0 OR EXTRACT(YEAR FROM transaction_date)=$2)
		GROUP BY transaction_type
	`
	if err := r.db.SelectContext(ctx, &rows, query, month, year); err != nil {
		return nil, fmt.Errorf("failed to get stats: %w", err)
	}

	stats := &accounting.AccountingStats{}
	for _, row := range rows {
		switch row.TxType {
		case "income":
			stats.TotalRevenue = row.Total
		case "expense":
			stats.TotalExpense = row.Total
		}
	}
	stats.NetProfit = stats.TotalRevenue - stats.TotalExpense

	// Cash & Bank = cumulative all-time income minus expense
	type cashRow struct {
		Total float64 `db:"total"`
	}
	var cashBalance cashRow
	cashQuery := `
		SELECT COALESCE(
			SUM(CASE WHEN transaction_type='income' THEN amount ELSE -amount END), 0
		) AS total
		FROM accounting_transactions
		WHERE status='completed'
		  AND transaction_type IN ('income','expense')
	`
	if err := r.db.GetContext(ctx, &cashBalance, cashQuery); err != nil {
		return nil, fmt.Errorf("failed to get cash balance: %w", err)
	}
	stats.CashAndBank = cashBalance.Total
	stats.Receivables = 0
	stats.Payables = 0

	return stats, nil
}

func (r *AccountingTransactionRepository) GetBudgetVsActual(ctx context.Context, month, year int) ([]*accounting.BudgetItem, error) {
	type budgetRow struct {
		Category string  `db:"category"`
		Total    float64 `db:"total"`
	}
	var rows []budgetRow
	query := `
		SELECT COALESCE(category,'Lainnya') AS category, COALESCE(SUM(amount),0) AS total
		FROM accounting_transactions
		WHERE status='completed'
		  AND transaction_type='expense'
		  AND ($1=0 OR EXTRACT(MONTH FROM transaction_date)=$1)
		  AND ($2=0 OR EXTRACT(YEAR FROM transaction_date)=$2)
		GROUP BY category
		ORDER BY total DESC
	`
	if err := r.db.SelectContext(ctx, &rows, query, month, year); err != nil {
		return nil, fmt.Errorf("failed to get budget vs actual: %w", err)
	}

	out := make([]*accounting.BudgetItem, len(rows))
	for i, row := range rows {
		out[i] = &accounting.BudgetItem{
			Category:     row.Category,
			IsPendapatan: false,
			Anggaran:     0,
			Realisasi:    row.Total,
		}
	}
	return out, nil
}
