# Spec: Accounting Backend — Bank Accounts + Transactions + COA Tree + Balance

**Date:** 2026-05-02
**Status:** Draft
**Branch:** feat/accounting-backend

## Context

The VernonEdu API already ships a substantial finance/accounting stack:
- `chart_of_accounts` (mig 038) seeded with Indonesian COA (1xxx asset … 5xxx expense)
- `finance_accounts` (mig 052) — duplicate hierarchical COA with `parent_id` + `branch_id`
- `finance_transactions` + `journal_entries` (mig 052) — double-entry transactions
- Accounting domain (`internal/domain/accounting/`) — transaction, invoice, coa, analysis
- HTTP routes under `/api/v1/accounting/*` and `/api/v1/finance/*`
- FX wiring for repos, command/query handlers, HTTP handlers

What is **missing** for branch-based bank/cash transaction management:
1. **Named bank accounts** (e.g. "BCA 5050-xxx Cabang Jakarta") — there is no `bank_accounts` table.
2. **Transaction update / delete** — only `Create` exists.
3. **Balance-by-account** query — only ad-hoc analysis, no per-account running balance endpoint.
4. **COA tree response** — current `list_coa` is flat.

## Goals

Add the missing pieces with minimal duplication, branch-scoped, money in int64 cents.

## Non-Goals

- Replacing existing `finance_accounts` / `finance_transactions` — too disruptive.
- Touching existing journal_entries, invoices, payables.

## Schema (Migration `057_create_bank_accounts.sql`)

```sql
CREATE TABLE IF NOT EXISTS bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    account_number VARCHAR(64) NOT NULL DEFAULT '',
    bank_name VARCHAR(128) NOT NULL DEFAULT '',
    balance_cents BIGINT NOT NULL DEFAULT 0,
    currency CHAR(3) NOT NULL DEFAULT 'IDR',
    coa_id UUID REFERENCES finance_accounts(id),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_branch ON bank_accounts(branch_id);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_coa ON bank_accounts(coa_id);
```

Plus, ensure `finance_transactions` carries `bank_account_id` (nullable for cash):

Migration `058_add_bank_account_to_finance_transactions.sql`:
```sql
ALTER TABLE finance_transactions
    ADD COLUMN IF NOT EXISTS bank_account_id UUID REFERENCES bank_accounts(id),
    ADD COLUMN IF NOT EXISTS txn_date DATE NOT NULL DEFAULT CURRENT_DATE;
CREATE INDEX IF NOT EXISTS idx_finance_transactions_bank_account ON finance_transactions(bank_account_id);
CREATE INDEX IF NOT EXISTS idx_finance_transactions_txn_date ON finance_transactions(txn_date);
```

## Domain Types (`internal/domain/accounting/bank_account.go`)

```go
type BankAccount struct {
    ID            uuid.UUID
    BranchID      uuid.UUID
    Name          string
    AccountNumber string
    BankName      string
    BalanceCents  int64
    Currency      string  // ISO 4217, default IDR
    CoaID         *uuid.UUID
    IsActive      bool
    CreatedBy     *uuid.UUID
    CreatedAt     time.Time
    UpdatedAt     time.Time
}

type BankAccountWriteRepository interface {
    Create(ctx context.Context, b *BankAccount) error
    Update(ctx context.Context, b *BankAccount) error
    Delete(ctx context.Context, id uuid.UUID) error
}

type BankAccountReadRepository interface {
    Get(ctx context.Context, id uuid.UUID) (*BankAccount, error)
    List(ctx context.Context, branchID *uuid.UUID, includeInactive bool) ([]*BankAccount, error)
}
```

## Domain Types (`internal/domain/accounting/coa.go` — extend)

Add `CoaNode` for tree response (parent_code grouping).

## Domain Types (transaction extensions)

Add to `internal/domain/accounting/transaction.go`:
- `BalanceByAccount` query result type
- `Update` / `Delete` repo methods on `TransactionWriteRepository`

## Commands

| Command | Folder | Purpose |
|---|---|---|
| `CreateBankAccountCommand` | `command/create_bank_account/` | Insert |
| `UpdateBankAccountCommand` | `command/update_bank_account/` | Mutate name/number/active |
| `DeleteBankAccountCommand` | `command/delete_bank_account/` | Soft-set inactive |
| `UpdateTransactionCommand` | `command/update_transaction/` | Mutate description / category |
| `DeleteTransactionCommand` | `command/delete_transaction/` | Soft cancel |

## Queries

| Query | Folder |
|---|---|
| `ListBankAccountsQuery(branch_id?)` | `query/list_bank_accounts/` |
| `GetBankAccountQuery(id)` | `query/get_bank_account/` |
| `GetBalanceByAccountQuery(coa_id, branch_id?, date_to?)` | `query/get_balance_by_account/` |
| `ListCoaTreeQuery` | `query/list_coa_tree/` |

## HTTP Endpoints

```
GET    /api/v1/accounting/coa/tree            → COA in tree form
GET    /api/v1/accounting/bank-accounts       ?branch_id&active
POST   /api/v1/accounting/bank-accounts
GET    /api/v1/accounting/bank-accounts/{id}
PUT    /api/v1/accounting/bank-accounts/{id}
DELETE /api/v1/accounting/bank-accounts/{id}
PUT    /api/v1/accounting/transactions/{id}
DELETE /api/v1/accounting/transactions/{id}
GET    /api/v1/accounting/balance             ?coa_id&branch_id&date_to
```

## Permission Matrix (enforced at HTTP layer middleware — already present pattern)

| Role | bank-accounts | transactions | balance |
|---|---|---|---|
| director | RWD | RWD | R |
| accounting_leader | RWD | RWD | R |
| accounting_staff | R | RWD | R (own branch) |
| others | R (own branch) | R (own branch) | R (own branch) |

Branch scoping: non-director users automatically filtered to their `branch_id` from JWT claims. Implemented via `currentBranchIDFromCtx(r)` helper analogous to existing `currentUserIDFromCtx`.

## Constants (no magic strings)

In `internal/domain/accounting/const.go`:
```go
const (
    CurrencyIDR     = "IDR"
    TxnTypeDebit    = "debit"
    TxnTypeCredit   = "credit"
    TxnStatusActive = "completed"
    TxnStatusVoid   = "cancelled"
)
```

## Test Plan

- `bank_account_test.go` — validation: name required, currency default, branch isolation invariant.
- `create_bank_account/handler_test.go` — happy path, missing branch error.
- `update_bank_account/handler_test.go` — happy path, not-found error.
- `delete_bank_account/handler_test.go` — soft delete sets is_active=false.
- `get_balance_by_account/handler_test.go` — sums debit – credit.
- `transaction_test.go` (extend) — debit/credit type validator.

Target: ≥ 8 unit tests pass.

## Out of Scope

- Audit log
- Multi-currency conversion
- Bank reconciliation imports
