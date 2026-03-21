package finance

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
)

var (
	ErrAccountNotFound     = errors.New("finance account not found")
	ErrTransactionNotFound = errors.New("finance transaction not found")
	ErrInvalidAccountType  = errors.New("invalid account type")
)

type AccountType string

const (
	AssetType     AccountType = "asset"
	LiabilityType AccountType = "liability"
	EquityType    AccountType = "equity"
	RevenueType   AccountType = "revenue"
	ExpenseType   AccountType = "expense"
)

func ParseAccountType(s string) (AccountType, error) {
	switch AccountType(s) {
	case AssetType, LiabilityType, EquityType, RevenueType, ExpenseType:
		return AccountType(s), nil
	}
	return "", ErrInvalidAccountType
}

type TransactionSource string

const (
	SourceManual TransactionSource = "manual"
	SourceAuto   TransactionSource = "auto"
)

type JournalSource string

const (
	JournalSourceManual         JournalSource = "manual"
	JournalSourceAutoInvoice    JournalSource = "auto_invoice"
	JournalSourceAutoPayable    JournalSource = "auto_payable"
	JournalSourceAutoCommission JournalSource = "auto_commission"
)

// ChartOfAccount is the finance-module account entity (branch-aware, UUID-referenced).
type ChartOfAccount struct {
	ID        uuid.UUID
	Code      string
	Name      string
	Type      AccountType
	ParentID  *uuid.UUID
	IsActive  bool
	BranchID  *uuid.UUID // nil = global / shared
	CreatedAt time.Time
	UpdatedAt time.Time
}

func NewChartOfAccount(code, name string, acctType AccountType, parentID, branchID *uuid.UUID) (*ChartOfAccount, error) {
	if code == "" {
		return nil, errors.New("account code is required")
	}
	if name == "" {
		return nil, errors.New("account name is required")
	}
	now := time.Now()
	return &ChartOfAccount{
		ID:        uuid.New(),
		Code:      code,
		Name:      name,
		Type:      acctType,
		ParentID:  parentID,
		IsActive:  true,
		BranchID:  branchID,
		CreatedAt: now,
		UpdatedAt: now,
	}, nil
}

// Transaction represents a finance transaction that auto-posts journal entries.
type Transaction struct {
	ID              uuid.UUID
	Code            string
	Description     string
	AccountDebitID  uuid.UUID
	AccountCreditID uuid.UUID
	Amount          float64
	Reference       string
	BranchID        uuid.UUID
	Source          TransactionSource
	AttachmentURL   string
	CreatedBy       uuid.UUID
	CreatedAt       time.Time
}

func NewTransaction(description string, debitID, creditID, branchID, createdBy uuid.UUID, amount float64, reference, attachmentURL string) (*Transaction, error) {
	if description == "" {
		return nil, errors.New("description is required")
	}
	if amount <= 0 {
		return nil, errors.New("amount must be positive")
	}
	return &Transaction{
		ID:              uuid.New(),
		Code:            fmt.Sprintf("TXN-%s", uuid.New().String()[:8]),
		Description:     description,
		AccountDebitID:  debitID,
		AccountCreditID: creditID,
		Amount:          amount,
		Reference:       reference,
		BranchID:        branchID,
		Source:          SourceManual,
		AttachmentURL:   attachmentURL,
		CreatedBy:       createdBy,
		CreatedAt:       time.Now(),
	}, nil
}

// JournalEntry represents one line of a double-entry journal.
type JournalEntry struct {
	ID            uuid.UUID
	TransactionID uuid.UUID
	AccountID     uuid.UUID
	Debit         float64
	Credit        float64
	Description   string
	Source        JournalSource
	CreatedAt     time.Time
}

func NewJournalEntry(transactionID, accountID uuid.UUID, debit, credit float64, description string, source JournalSource) *JournalEntry {
	return &JournalEntry{
		ID:            uuid.New(),
		TransactionID: transactionID,
		AccountID:     accountID,
		Debit:         debit,
		Credit:        credit,
		Description:   description,
		Source:        source,
		CreatedAt:     time.Now(),
	}
}

// Repository interfaces

type AccountWriteRepository interface {
	Save(ctx context.Context, a *ChartOfAccount) error
	Update(ctx context.Context, a *ChartOfAccount) error
}

type AccountReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*ChartOfAccount, error)
	ListAll(ctx context.Context, branchID *uuid.UUID) ([]*ChartOfAccount, error)
}

type TransactionWriteRepository interface {
	Save(ctx context.Context, t *Transaction, entries []*JournalEntry) error
}

type TransactionReadRepository interface {
	List(ctx context.Context, opts TransactionFilter) ([]*Transaction, int, error)
}

type JournalWriteRepository interface {
	Save(ctx context.Context, e *JournalEntry) error
}

type JournalReadRepository interface {
	List(ctx context.Context, opts JournalFilter) ([]*JournalEntry, int, error)
}

type TransactionFilter struct {
	Offset    int
	Limit     int
	Source    string
	AccountID *uuid.UUID
	BranchID  *uuid.UUID
	DateFrom  *time.Time
	DateTo    *time.Time
}

type JournalFilter struct {
	Offset    int
	Limit     int
	Source    string
	AccountID *uuid.UUID
	DateFrom  *time.Time
	DateTo    *time.Time
}
