# Domain: Accounting

> Chart of Accounts, branch-based transactions, auto-invoicing, batch budgeting, commission system, and financial report generation.

---

## Overview

The accounting system handles:
1. **Chart of Accounts (CoA)** — Preset CoA seeded on application init
2. **Branch-based accounting** — All transactions and reports are per-branch (franchise model)
3. **Manual transaction input** — Accounting staff enters bank and cash transactions
4. **Auto-generated invoices** — System creates invoices per enrollment based on payment method
5. **Batch budgeting** — Each course batch has a budget; spending/earning tracked against it
6. **Commission system** — Auto-calculated and posted to accounting journal
7. **Financial reports** — System auto-generates reports from transaction data, per branch

---

## Chart of Accounts (CoA)

- Preset / default CoA is **seeded when the application is installed / initiated**
- Standard accounts: assets, liabilities, equity, revenue, expenses
- Can be customized per branch after seeding
- All transactions must be mapped to a CoA account

---

## Branch-Based Accounting (Franchise Model)

VernonEdu is built as a **franchised business**. This means:
- Every financial transaction is tagged to a **branch**
- Every financial report is calculated **per branch**
- Consolidated reports across branches are available for Director level
- Each branch has its own CoA instance (seeded from preset, customizable)

---

## Commission System

Configured in **Company Settings** (Director access only).

### Commission Configuration

| Recipient | Setting | Options |
|-----------|---------|---------|
| Operation Leader | Percentage + basis | % of batch profit OR % of gross revenue |
| Dept Leader | Percentage + basis | % of batch profit OR % of gross revenue |
| Course Creator | Percentage + basis | % of batch profit OR % of gross revenue |
| Facilitator | Level-based fee per session | Fee per session (max 2 hours per session) |

### Facilitator Levels

Facilitators are assigned a level, each level has a fixed fee per session:
- e.g. Level 1: Rp 200.000/session, Level 2: Rp 350.000/session, etc.
- Max session duration for fee calculation: **2 hours**
- Levels and fees configurable in settings

### Auto-Calculation & Journal Posting

- Commission is **auto-calculated** when batch financials are finalized
- Commission entries are **auto-posted to the accounting journal**
- Mapped to appropriate CoA accounts (expense: commission payable)

---

## Transaction Input

Accounting staff (and Accounting Leader) can input:
- Bank transactions (transfer in/out, fees)
- Cash transactions (income/expense)

Each transaction is categorized, linked to relevant entities (batch, enrollment, etc.), and tagged to a **branch**.

---

## Auto-Invoice Generation

When a student enrolls in a batch, the system automatically generates invoice(s) based on the batch's payment method:

| Payment Method | Invoice Behavior |
|----------------|-----------------|
| `upfront` | Single invoice for full amount, due before class starts |
| `scheduled` | Multiple invoices per installment schedule (e.g. 3 invoices) |
| `monthly` | Monthly invoices based on sessions in that month |
| `batch_lump` | Single invoice to the client company for the entire batch |
| `per_session` | Invoice generated after each attended session |

Invoice status: `draft | sent | paid | overdue | cancelled`

---

## Batch Budgeting

Each course batch includes:
- **Budget plan** — expected line items for spending and earning
- **Actual tracking** — each real spending/earning mapped to a budget line item
- **Variance reporting** — budget vs actual comparison
- **Commission allocation** — budgeted commission costs for all roles

All batch financial data feeds into the accounting reports.

---

## Financial Reports

System auto-generates reports **per branch**, including:
- Income statement (Pendapatan vs Pengeluaran)
- Cash flow
- Balance sheet components
- Per-batch P&L (including commission costs)
- Consolidated report (Director level, cross-branch)

---

## Routes

```
/accounting     → AccountingPage
/settings       → SettingsPage (commission config, CoA management — Director access)
```

## Current Implementation

**Status:** ⚠️ Rich UI with **mock data** — no API connection yet.

Current UI features (all with mock data):
- 6 stat cards: Total Pendapatan, Pengeluaran, Laba Bersih, Kas & Bank, Piutang, Hutang
- Bar chart (Pendapatan vs Pengeluaran, 6 months) via `fl_chart`
- Pie chart (Komposisi Pengeluaran breakdown)
- 3 tabs: Transaksi Terbaru, Anggaran vs Realisasi, Laporan Keuangan
- Period dropdown filter

**No `data/` or `domain/` directories** — only `presentation/pages` + `presentation/widgets`

### Migration Plan (v2)
- Create full clean architecture stack (`data/`, `domain/`, update `presentation/`)
- Seed preset CoA on app init
- Add branch tagging to all transactions and reports
- API endpoints for transactions, invoices, budgets, reports, CoA, commission config
- Replace mock data with real API calls
- Link enrollment → auto-invoice pipeline
- Link batch budgeting → accounting reports
- Commission auto-calculation + journal posting engine

---

## Status

⚠️ Mock data only — needs full backend integration: CoA seeding, branch-based accounting, invoice engine, budgeting system, commission engine, report generation.
