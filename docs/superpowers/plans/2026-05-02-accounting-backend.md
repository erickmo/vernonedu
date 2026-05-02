# Plan: Accounting Backend Implementation

**Branch:** feat/accounting-backend
**Spec:** `docs/superpowers/specs/2026-05-02-accounting-backend-design.md`

## Steps

1. Migrations
   - `057_create_bank_accounts.sql`
   - `058_add_bank_account_to_finance_transactions.sql`

2. Domain
   - `internal/domain/accounting/bank_account.go` — entity + repo interfaces + validators
   - `internal/domain/accounting/const.go` — currency, txn type, status constants
   - extend `internal/domain/accounting/coa.go` — `CoaNode` tree
   - extend `internal/domain/accounting/transaction.go` — Update/Delete repo methods + BalanceByAccount type

3. Infrastructure (sqlx repos)
   - `infrastructure/database/bank_account_repository.go`
   - extend `accounting_transaction_repository.go` with Update/Delete
   - extend `accounting_coa_repository.go` with `ListTree`, `GetBalance`

4. Commands (one folder each)
   - `command/create_bank_account/`
   - `command/update_bank_account/`
   - `command/delete_bank_account/`
   - `command/update_transaction/`
   - `command/delete_transaction/`

5. Queries
   - `query/list_bank_accounts/`
   - `query/get_bank_account/`
   - `query/get_balance_by_account/`
   - `query/list_coa_tree/`

6. HTTP — extend `delivery/http/accounting_handler.go`
   - bank-account CRUD handlers
   - transaction update/delete handlers
   - balance handler
   - coa tree handler
   - register routes

7. FX wiring in `cmd/api/main.go`
   - add `BankAccountRepo` to Params
   - register all new commands and queries

8. Tests
   - domain validation tests
   - command handler tests with in-memory fakes
   - target ≥ 8 unit tests, all passing

9. `cd api && go build ./... && go test ./internal/domain/accounting/... ./internal/command/create_bank_account/... ./internal/command/update_bank_account/... ./internal/command/delete_bank_account/...`

10. Commit `feat(accounting): add COA tree + bank/cash transactions backend` and push, open PR.

## Constraints

- Money in int64 cents (BalanceCents, AmountCents fields)
- ≤ 40 LOC per func, ≤ 300 LOC per file
- No magic strings — use `accounting/const.go`
- DI everywhere — repos passed via constructor
- HTTP handler thin — only decode + dispatch
