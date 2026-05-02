package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type bankAccountRecord struct {
	ID            uuid.UUID      `db:"id"`
	BranchID      uuid.UUID      `db:"branch_id"`
	Name          string         `db:"name"`
	AccountNumber string         `db:"account_number"`
	BankName      string         `db:"bank_name"`
	BalanceCents  int64          `db:"balance_cents"`
	Currency      string         `db:"currency"`
	CoaCode       sql.NullString `db:"coa_code"`
	IsActive      bool           `db:"is_active"`
	CreatedBy     *uuid.UUID     `db:"created_by"`
	CreatedAt     time.Time      `db:"created_at"`
	UpdatedAt     time.Time      `db:"updated_at"`
}

// BankAccountRepository persists and reads bank_accounts.
type BankAccountRepository struct {
	db *sqlx.DB
}

func NewBankAccountRepository(db *sqlx.DB) *BankAccountRepository {
	return &BankAccountRepository{db: db}
}

func (r *BankAccountRepository) Create(ctx context.Context, b *accounting.BankAccount) error {
	const q = `INSERT INTO bank_accounts
		(id, branch_id, name, account_number, bank_name, balance_cents,
		 currency, coa_code, is_active, created_by, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,NULLIF($8,''),$9,$10,$11,$12)`
	_, err := r.db.ExecContext(ctx, q,
		b.ID, b.BranchID, b.Name, b.AccountNumber, b.BankName, b.BalanceCents,
		b.Currency, b.CoaCode, b.IsActive, b.CreatedBy, b.CreatedAt, b.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to create bank account: %w", err)
	}
	return nil
}

func (r *BankAccountRepository) Update(ctx context.Context, b *accounting.BankAccount) error {
	const q = `UPDATE bank_accounts SET
		 name=$2, account_number=$3, bank_name=$4, balance_cents=$5,
		 currency=$6, coa_code=NULLIF($7,''), updated_at=NOW()
		WHERE id=$1`
	res, err := r.db.ExecContext(ctx, q,
		b.ID, b.Name, b.AccountNumber, b.BankName, b.BalanceCents, b.Currency, b.CoaCode,
	)
	if err != nil {
		return fmt.Errorf("failed to update bank account: %w", err)
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("bank account %s not found", b.ID)
	}
	return nil
}

func (r *BankAccountRepository) SetActive(ctx context.Context, id uuid.UUID, active bool) error {
	const q = `UPDATE bank_accounts SET is_active=$2, updated_at=NOW() WHERE id=$1`
	res, err := r.db.ExecContext(ctx, q, id, active)
	if err != nil {
		return fmt.Errorf("failed to toggle bank account: %w", err)
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("bank account %s not found", id)
	}
	return nil
}

func (r *BankAccountRepository) Get(ctx context.Context, id uuid.UUID) (*accounting.BankAccount, error) {
	var rec bankAccountRecord
	err := r.db.GetContext(ctx, &rec, `SELECT id, branch_id, name, account_number, bank_name,
		balance_cents, currency, coa_code, is_active, created_by, created_at, updated_at
		FROM bank_accounts WHERE id=$1`, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get bank account: %w", err)
	}
	return rowToBankAccount(&rec), nil
}

func (r *BankAccountRepository) List(ctx context.Context, branchID *uuid.UUID, includeInactive bool) ([]*accounting.BankAccount, error) {
	var rows []bankAccountRecord
	q := `SELECT id, branch_id, name, account_number, bank_name, balance_cents,
		     currency, coa_code, is_active, created_by, created_at, updated_at
		FROM bank_accounts
		WHERE ($1::uuid IS NULL OR branch_id=$1)
		  AND ($2 OR is_active=true)
		ORDER BY name`
	if err := r.db.SelectContext(ctx, &rows, q, branchID, includeInactive); err != nil {
		return nil, fmt.Errorf("failed to list bank accounts: %w", err)
	}
	out := make([]*accounting.BankAccount, len(rows))
	for i := range rows {
		out[i] = rowToBankAccount(&rows[i])
	}
	return out, nil
}

func rowToBankAccount(r *bankAccountRecord) *accounting.BankAccount {
	coa := ""
	if r.CoaCode.Valid {
		coa = r.CoaCode.String
	}
	return &accounting.BankAccount{
		ID:            r.ID,
		BranchID:      r.BranchID,
		Name:          r.Name,
		AccountNumber: r.AccountNumber,
		BankName:      r.BankName,
		BalanceCents:  r.BalanceCents,
		Currency:      r.Currency,
		CoaCode:       coa,
		IsActive:      r.IsActive,
		CreatedBy:     r.CreatedBy,
		CreatedAt:     r.CreatedAt,
		UpdatedAt:     r.UpdatedAt,
	}
}
