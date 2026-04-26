# Design: Franchise Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Franchisee branches, FranchiseAgreement terms, branch revenue, royalty tracking

---

## Overview

VernonEdu operates a franchise model where external investors (franchisees) own branches. VernonEdu retains 100% operational control — curriculum, instructors, scheduling, quality. Franchisees earn from branch revenue minus royalty.

---

## Entities

### Franchisee
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| name | string | Owner / investor |
| branch_name | string | |
| location | string | City / address |
| contact | string | |
| status | enum | active, inactive, terminated |
| created_by | User | Admin |
| created_at | datetime | |

### FranchiseAgreement
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| franchisee | Franchisee | |
| buy_in_fee | decimal | One-time at signing |
| monthly_royalty | decimal | Fixed monthly |
| revenue_royalty_pct | decimal | % of gross branch revenue |
| start_date | date | |
| end_date | date | Nullable |
| status | enum | active, inactive, terminated |

All three financials are individually negotiated per franchisee — no global default.

### BranchOtherRevenue
Non-enrollment branch revenue (events, merch, rental).

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| franchisee | Franchisee | |
| label | string | |
| amount | decimal | |
| revenue_date | date | |
| added_by | User (admin) | |
| created_at | datetime | |

### RoyaltyPaymentRecord
Per-period royalty.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| franchise_agreement | FranchiseAgreement | |
| period | string | YYYY-MM |
| gross_revenue | decimal | Enrollment + other for period |
| monthly_royalty | decimal | From agreement |
| revenue_royalty | decimal | gross_revenue × revenue_royalty_pct |
| total_royalty | decimal | monthly_royalty + revenue_royalty |
| status | enum | unpaid, overdue, paid |
| created_at | datetime | |
| paid_at | datetime | Nullable |
| recorded_by | User | Admin |

---

## Branch Revenue

Gross branch revenue = enrollment fees from branch + BranchOtherRevenue entries.

Calculated from Enrollments where `enrollment.franchisee = this Franchisee`. Admin sets `franchisee` field on enrollments originating from a franchise branch.

---

## Business Rules

1. Franchisee role = investor/location owner only — no operational authority
2. All courses, pricing, instructors, scheduling governed by VernonEdu
3. B2B and B2C rules apply identically at franchise branches
4. Gross revenue = enrollment fees + BranchOtherRevenue
5. Revenue royalty = gross_revenue × revenue_royalty_pct
6. Monthly royalty = flat fee, regardless of revenue
7. Total royalty = monthly + revenue
8. Buy-in fee one-time, non-refundable
9. `revenue_royalty_pct` in 0–100
10. Admin sets `franchisee` field on relevant enrollments

---

## Background Jobs

- **Royalty overdue check** (monthly, 15th): any `RoyaltyPaymentRecord` with `status = unpaid` and period end > 14 days ago → `status = overdue`

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| — | — | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

---

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [profit-split](../profit-split/profit-split.md)
