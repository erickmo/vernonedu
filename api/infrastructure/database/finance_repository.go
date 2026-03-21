package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/finance"
)

// ─── Chart of Accounts ───────────────────────────────────────────────────────

type financeAccountRecord struct {
	ID        uuid.UUID  `db:"id"`
	Code      string     `db:"code"`
	Name      string     `db:"name"`
	Type      string     `db:"type"`
	ParentID  *uuid.UUID `db:"parent_id"`
	IsActive  bool       `db:"is_active"`
	BranchID  *uuid.UUID `db:"branch_id"`
	CreatedAt time.Time  `db:"created_at"`
	UpdatedAt time.Time  `db:"updated_at"`
}

type FinanceAccountRepository struct {
	db *sqlx.DB
}

func NewFinanceAccountRepository(db *sqlx.DB) *FinanceAccountRepository {
	return &FinanceAccountRepository{db: db}
}

func (r *FinanceAccountRepository) Save(ctx context.Context, a *finance.ChartOfAccount) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO finance_accounts (id, code, name, type, parent_id, is_active, branch_id, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
	`, a.ID, a.Code, a.Name, string(a.Type), a.ParentID, a.IsActive, a.BranchID, a.CreatedAt, a.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to save finance account: %w", err)
	}
	return nil
}

func (r *FinanceAccountRepository) Update(ctx context.Context, a *finance.ChartOfAccount) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE finance_accounts SET name=$2, is_active=$3, updated_at=$4 WHERE id=$1
	`, a.ID, a.Name, a.IsActive, a.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to update finance account: %w", err)
	}
	return nil
}

func (r *FinanceAccountRepository) GetByID(ctx context.Context, id uuid.UUID) (*finance.ChartOfAccount, error) {
	var rec financeAccountRecord
	err := r.db.GetContext(ctx, &rec, `
		SELECT id, code, name, type, parent_id, is_active, branch_id, created_at, updated_at
		FROM finance_accounts WHERE id=$1
	`, id)
	if err == sql.ErrNoRows {
		return nil, finance.ErrAccountNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get finance account: %w", err)
	}
	return financeAccountToEntity(&rec), nil
}

func (r *FinanceAccountRepository) ListAll(ctx context.Context, branchID *uuid.UUID) ([]*finance.ChartOfAccount, error) {
	var rows []financeAccountRecord
	var err error
	if branchID != nil {
		err = r.db.SelectContext(ctx, &rows, `
			SELECT id, code, name, type, parent_id, is_active, branch_id, created_at, updated_at
			FROM finance_accounts
			WHERE (branch_id IS NULL OR branch_id=$1) AND is_active=true
			ORDER BY code
		`, *branchID)
	} else {
		err = r.db.SelectContext(ctx, &rows, `
			SELECT id, code, name, type, parent_id, is_active, branch_id, created_at, updated_at
			FROM finance_accounts
			WHERE is_active=true
			ORDER BY code
		`)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to list finance accounts: %w", err)
	}

	out := make([]*finance.ChartOfAccount, len(rows))
	for i, row := range rows {
		out[i] = financeAccountToEntity(&row)
	}
	return out, nil
}

func financeAccountToEntity(r *financeAccountRecord) *finance.ChartOfAccount {
	return &finance.ChartOfAccount{
		ID:        r.ID,
		Code:      r.Code,
		Name:      r.Name,
		Type:      finance.AccountType(r.Type),
		ParentID:  r.ParentID,
		IsActive:  r.IsActive,
		BranchID:  r.BranchID,
		CreatedAt: r.CreatedAt,
		UpdatedAt: r.UpdatedAt,
	}
}

// ─── Transactions ─────────────────────────────────────────────────────────────

type financeTransactionRecord struct {
	ID              uuid.UUID `db:"id"`
	Code            string    `db:"code"`
	Description     string    `db:"description"`
	AccountDebitID  uuid.UUID `db:"account_debit_id"`
	AccountCreditID uuid.UUID `db:"account_credit_id"`
	Amount          float64   `db:"amount"`
	Reference       string    `db:"reference"`
	BranchID        uuid.UUID `db:"branch_id"`
	Source          string    `db:"source"`
	AttachmentURL   string    `db:"attachment_url"`
	CreatedBy       uuid.UUID `db:"created_by"`
	CreatedAt       time.Time `db:"created_at"`
}

type FinanceTransactionRepository struct {
	db *sqlx.DB
}

func NewFinanceTransactionRepository(db *sqlx.DB) *FinanceTransactionRepository {
	return &FinanceTransactionRepository{db: db}
}

func (r *FinanceTransactionRepository) Save(ctx context.Context, t *finance.Transaction, entries []*finance.JournalEntry) error {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	_, err = tx.ExecContext(ctx, `
		INSERT INTO finance_transactions
			(id, code, description, account_debit_id, account_credit_id, amount, reference, branch_id, source, attachment_url, created_by, created_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
	`, t.ID, t.Code, t.Description, t.AccountDebitID, t.AccountCreditID,
		t.Amount, t.Reference, t.BranchID, string(t.Source), t.AttachmentURL, t.CreatedBy, t.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to insert finance transaction: %w", err)
	}

	for _, e := range entries {
		_, err = tx.ExecContext(ctx, `
			INSERT INTO journal_entries (id, transaction_id, account_id, debit, credit, description, source, created_at)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
		`, e.ID, e.TransactionID, e.AccountID, e.Debit, e.Credit, e.Description, string(e.Source), e.CreatedAt)
		if err != nil {
			return fmt.Errorf("failed to insert journal entry: %w", err)
		}
	}

	return tx.Commit()
}

func (r *FinanceTransactionRepository) List(ctx context.Context, opts finance.TransactionFilter) ([]*finance.Transaction, int, error) {
	where := "WHERE 1=1"
	args := []interface{}{}
	i := 1

	if opts.Source != "" {
		where += fmt.Sprintf(" AND source=$%d", i)
		args = append(args, opts.Source)
		i++
	}
	if opts.AccountID != nil {
		where += fmt.Sprintf(" AND (account_debit_id=$%d OR account_credit_id=$%d)", i, i+1)
		args = append(args, *opts.AccountID, *opts.AccountID)
		i += 2
	}
	if opts.BranchID != nil {
		where += fmt.Sprintf(" AND branch_id=$%d", i)
		args = append(args, *opts.BranchID)
		i++
	}
	if opts.DateFrom != nil {
		where += fmt.Sprintf(" AND created_at>=$%d", i)
		args = append(args, *opts.DateFrom)
		i++
	}
	if opts.DateTo != nil {
		where += fmt.Sprintf(" AND created_at<=$%d", i)
		args = append(args, *opts.DateTo)
		i++
	}

	var total int
	if err := r.db.GetContext(ctx, &total, "SELECT COUNT(*) FROM finance_transactions "+where, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count finance transactions: %w", err)
	}

	args = append(args, opts.Limit, opts.Offset)
	listSQL := fmt.Sprintf(`
		SELECT id, code, description, account_debit_id, account_credit_id, amount,
		       COALESCE(reference,'') AS reference, branch_id, source,
		       COALESCE(attachment_url,'') AS attachment_url, created_by, created_at
		FROM finance_transactions %s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d
	`, where, i, i+1)

	var rows []financeTransactionRecord
	if err := r.db.SelectContext(ctx, &rows, listSQL, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to list finance transactions: %w", err)
	}

	out := make([]*finance.Transaction, len(rows))
	for j, row := range rows {
		out[j] = &finance.Transaction{
			ID:              row.ID,
			Code:            row.Code,
			Description:     row.Description,
			AccountDebitID:  row.AccountDebitID,
			AccountCreditID: row.AccountCreditID,
			Amount:          row.Amount,
			Reference:       row.Reference,
			BranchID:        row.BranchID,
			Source:          finance.TransactionSource(row.Source),
			AttachmentURL:   row.AttachmentURL,
			CreatedBy:       row.CreatedBy,
			CreatedAt:       row.CreatedAt,
		}
	}
	return out, total, nil
}

// ─── Journal Entries ──────────────────────────────────────────────────────────

type journalEntryRecord struct {
	ID            uuid.UUID `db:"id"`
	TransactionID uuid.UUID `db:"transaction_id"`
	AccountID     uuid.UUID `db:"account_id"`
	Debit         float64   `db:"debit"`
	Credit        float64   `db:"credit"`
	Description   string    `db:"description"`
	Source        string    `db:"source"`
	CreatedAt     time.Time `db:"created_at"`
}

type FinanceJournalRepository struct {
	db *sqlx.DB
}

func NewFinanceJournalRepository(db *sqlx.DB) *FinanceJournalRepository {
	return &FinanceJournalRepository{db: db}
}

func (r *FinanceJournalRepository) Save(ctx context.Context, e *finance.JournalEntry) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO journal_entries (id, transaction_id, account_id, debit, credit, description, source, created_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
	`, e.ID, e.TransactionID, e.AccountID, e.Debit, e.Credit, e.Description, string(e.Source), e.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to save journal entry: %w", err)
	}
	return nil
}

func (r *FinanceJournalRepository) List(ctx context.Context, opts finance.JournalFilter) ([]*finance.JournalEntry, int, error) {
	where := "WHERE 1=1"
	args := []interface{}{}
	i := 1

	if opts.Source != "" {
		where += fmt.Sprintf(" AND source=$%d", i)
		args = append(args, opts.Source)
		i++
	}
	if opts.AccountID != nil {
		where += fmt.Sprintf(" AND account_id=$%d", i)
		args = append(args, *opts.AccountID)
		i++
	}
	if opts.DateFrom != nil {
		where += fmt.Sprintf(" AND created_at>=$%d", i)
		args = append(args, *opts.DateFrom)
		i++
	}
	if opts.DateTo != nil {
		where += fmt.Sprintf(" AND created_at<=$%d", i)
		args = append(args, *opts.DateTo)
		i++
	}

	var total int
	if err := r.db.GetContext(ctx, &total, "SELECT COUNT(*) FROM journal_entries "+where, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count journal entries: %w", err)
	}

	args = append(args, opts.Limit, opts.Offset)
	listSQL := fmt.Sprintf(`
		SELECT id, transaction_id, account_id, debit, credit, description, source, created_at
		FROM journal_entries %s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d
	`, where, i, i+1)

	var rows []journalEntryRecord
	if err := r.db.SelectContext(ctx, &rows, listSQL, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to list journal entries: %w", err)
	}

	out := make([]*finance.JournalEntry, len(rows))
	for j, row := range rows {
		out[j] = &finance.JournalEntry{
			ID:            row.ID,
			TransactionID: row.TransactionID,
			AccountID:     row.AccountID,
			Debit:         row.Debit,
			Credit:        row.Credit,
			Description:   row.Description,
			Source:        finance.JournalSource(row.Source),
			CreatedAt:     row.CreatedAt,
		}
	}
	return out, total, nil
}
