# Finance Domain — Full Audit + Complete

**Date:** 2026-05-05  
**Scope:** web-dashboard Finance pages (`src/pages/Finance/`) + services (`src/services/`)

---

## Problem Statement

Finance domain has 13 implemented pages and 8 stub "Coming Soon" pages. API endpoints for all features already exist. Goal: audit existing pages for correctness against API, implement all stubs.

---

## Existing Pages (Audit Target)

| Page | File | Status |
|---|---|---|
| Bank Accounts List | `BankAccountsPage.tsx` | Implemented — audit |
| Bank Account Form | `BankAccountFormPage.tsx` | Implemented — audit |
| Chart of Accounts | `ChartOfAccountsPage.tsx` | Implemented — audit |
| COA Form | `CoaFormPage.tsx` | Implemented — audit |
| Transaction List | `TransactionListPage.tsx` | Implemented — audit |
| Transaction Form | `TransactionFormPage.tsx` | Implemented — audit |
| Journal | `JournalPage.tsx` | Implemented — audit |
| Invoice List | `InvoiceListPage.tsx` | Implemented — audit |
| Manual Invoice Form | `ManualInvoiceFormPage.tsx` | Implemented — audit |
| Invoice Detail | `InvoiceDetailPage.tsx` | Implemented — audit |
| Payable List | `PayableListPage.tsx` | Implemented — audit |
| Payable Form | `PayableFormPage.tsx` | Implemented — audit |
| Payable Detail | `PayableDetailPage.tsx` | Implemented — audit |

**Audit checklist per page:**
- API endpoints match `api/CLAUDE.md` Finance section
- Service paths use correct prefix (`/finance/...`, no double `/api/v1`)
- No missing CRUD operations vs. API docs
- Error handling present
- Loading states present

---

## Stub Pages (Implementation Target)

### FinanceMainPage (`/finance`)

Dashboard overview with:
- KPI cards: Total Revenue (month), Total Expenses (month), Outstanding Invoices (count + amount), Payables Due (count + amount)
- Recent Transactions table (last 10, with date/description/amount/type)
- Quick action shortcuts: New Transaction, New Invoice, View Reports
- Source: `GET /api/v1/finance/stats?month=&year=`, `GET /api/v1/finance/transactions?limit=10`

### ReportNavigationPage (`/finance/reports`)

Navigation grid showing all 5 reports with title, description, and link:
- Balance Sheet — snapshot aset & liabilitas
- Profit & Loss — pendapatan vs biaya
- Cash Flow — arus kas
- General Ledger — buku besar per akun
- Trial Balance — saldo semua akun

### BalanceSheetPage (`/finance/reports/balance-sheet`)

- Filters: period (month/year), branch_id
- Table: Assets (current + non-current), Liabilities, Equity
- Source: `GET /api/v1/finance/reports/balance-sheet?period=&branch_id=`

### ProfitLossPage (`/finance/reports/profit-loss`)

- Filters: period, branch_id
- Table: Revenue rows, Expense rows, Net Profit/Loss
- Source: `GET /api/v1/finance/reports/profit-loss`

### CashFlowPage (`/finance/reports/cash-flow`)

- Filters: period, branch_id
- Table: Operating, Investing, Financing activities + Net Change
- Source: `GET /api/v1/finance/reports/cash-flow`

### GeneralLedgerPage (`/finance/reports/ledger`)

- Filters: account (COA select), period
- Table: date, description, debit, credit, running balance
- Source: `GET /api/v1/finance/reports/ledger?account=&period=`

### TrialBalancePage (`/finance/reports/trial-balance`)

- Filters: period, branch_id
- Table: account code, account name, debit total, credit total
- Source: `GET /api/v1/finance/reports/trial-balance`

### FinancialAnalysisPage (`/finance/analysis`)

- Financial ratios panel (liquidity, profitability)
- Revenue trend chart (placeholder with table fallback)
- Batch profitability table (top batches by profit)
- Cash forecast table (next N months)
- Alerts panel (from `/finance/analysis/alerts`)
- Sources: all `/api/v1/finance/analysis/*` endpoints

---

## Services

| Service | File | Coverage |
|---|---|---|
| `accountingService` | `accounting.service.ts` | Transactions, COA, bank accounts, basic invoices |
| `invoiceService` | `invoice.service.ts` | Invoice CRUD + actions |
| `payableService` | `payable.service.ts` | Payable CRUD + actions |
| `financeReportsService` | `finance-reports.service.ts` | All 5 report endpoints |
| `financeAnalysisService` | `finance-analysis.service.ts` | All analysis endpoints |

Services must use paths starting with `/finance/` (no `/api/v1` prefix — already in base URL).

---

## Parallel Agent Decomposition

Work is divided into 5 independent agents with no shared files:

| Agent | Domain | Files |
|---|---|---|
| **A** | Implement Report Pages | `BalanceSheetPage`, `ProfitLossPage`, `CashFlowPage`, `GeneralLedgerPage`, `TrialBalancePage`, `ReportNavigationPage`, `finance-reports.service.ts` |
| **B** | Implement Dashboard + Analysis | `FinanceMainPage`, `FinancialAnalysisPage`, `finance-analysis.service.ts` |
| **C** | Audit BankAccounts + COA | `BankAccountsPage`, `BankAccountFormPage`, `ChartOfAccountsPage`, `CoaFormPage` |
| **D** | Audit Transaction + Journal | `TransactionListPage`, `TransactionFormPage`, `JournalPage`, `accounting.service.ts` |
| **E** | Audit Invoice + Payable | `InvoiceListPage`, `ManualInvoiceFormPage`, `InvoiceDetailPage`, `PayableListPage`, `PayableFormPage`, `PayableDetailPage`, `invoice.service.ts`, `payable.service.ts` |

---

## API Reference (Finance)

```
# Invoices
GET    /finance/invoices               ?status, batch_id, student_id
GET    /finance/invoices/{id}
POST   /finance/invoices
PUT    /finance/invoices/{id}/pay
PUT    /finance/invoices/{id}/cancel

# Payables
GET    /finance/payables               ?type, status, batch_id
GET    /finance/payables/{id}
PUT    /finance/payables/{id}/pay

# Transactions & Journal
GET    /finance/transactions           ?type, account, branch_id, source
POST   /finance/transactions
GET    /finance/journal                ?account, source, date_range

# COA
GET    /finance/coa                    → tree
GET    /finance/coa/{id}
POST   /finance/coa
PUT    /finance/coa/{id}

# Bank Accounts
GET    /finance/bank-accounts
GET    /finance/bank-accounts/{id}
POST   /finance/bank-accounts
PUT    /finance/bank-accounts/{id}
DELETE /finance/bank-accounts/{id}

# Reports
GET    /finance/reports/balance-sheet  ?period, branch_id
GET    /finance/reports/profit-loss    ?period, branch_id
GET    /finance/reports/cash-flow      ?period, branch_id
GET    /finance/reports/ledger         ?account, period
GET    /finance/reports/trial-balance  ?period, branch_id

# Analysis
GET    /finance/analysis/ratios        ?period, branch_id
GET    /finance/analysis/revenue       ?period, branch_id, group_by
GET    /finance/analysis/costs         ?period, branch_id, group_by
GET    /finance/analysis/batch-profit  ?period, branch_id, sort, limit
GET    /finance/analysis/cash-forecast ?months, branch_id
GET    /finance/analysis/alerts
GET    /finance/analysis/suggestions
```

---

## Key Constraints

- No `/api/v1` prefix in service paths (base URL already includes it)
- All paths start with `/finance/`
- No accounting domain — use finance prefix (per cerebrum Do-Not-Repeat)
- CSS Modules (no Tailwind) — follow existing page patterns
- `any` types acceptable for now (no strict typing requirement for this iteration)
