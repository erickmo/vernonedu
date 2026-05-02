package accounting

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

// BankAccount represents a named bank or cash account scoped to a branch.
// A nil/empty CoaCode means cash-on-hand without an explicit COA link.
type BankAccount struct {
	ID            uuid.UUID
	BranchID      uuid.UUID
	Name          string
	AccountNumber string
	BankName      string
	BalanceCents  int64
	Currency      string
	CoaCode       string
	IsActive      bool
	CreatedBy     *uuid.UUID
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

// Validation errors.
var (
	ErrBankAccountNameRequired = errors.New("bank account name is required")
	ErrBankAccountNameTooLong  = errors.New("bank account name too long")
	ErrBankAccountBranch       = errors.New("bank account branch_id is required")
	ErrBankAccountCurrency     = errors.New("bank account currency is invalid")
)

// Validate checks invariants of a BankAccount before persistence.
func (b *BankAccount) Validate() error {
	name := strings.TrimSpace(b.Name)
	if len(name) < BankAccountNameMinLen {
		return ErrBankAccountNameRequired
	}
	if len(name) > BankAccountNameMaxLen {
		return ErrBankAccountNameTooLong
	}
	if b.BranchID == uuid.Nil {
		return ErrBankAccountBranch
	}
	if b.Currency == "" {
		b.Currency = CurrencyIDR
	}
	if len(b.Currency) != 3 {
		return ErrBankAccountCurrency
	}
	return nil
}

// BankAccountWriteRepository persists bank account changes.
type BankAccountWriteRepository interface {
	Create(ctx context.Context, b *BankAccount) error
	Update(ctx context.Context, b *BankAccount) error
	SetActive(ctx context.Context, id uuid.UUID, active bool) error
}

// BankAccountReadRepository fetches bank accounts.
type BankAccountReadRepository interface {
	Get(ctx context.Context, id uuid.UUID) (*BankAccount, error)
	List(ctx context.Context, branchID *uuid.UUID, includeInactive bool) ([]*BankAccount, error)
}
