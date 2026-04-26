# Domain: Franchise

## Overview

VernonEdu operates a franchise model where external investors (franchisees) own branches. VernonEdu retains **100% operational management** — curriculum, instructors, scheduling, and quality are fully controlled by VernonEdu.

## Entities

### Franchisee
| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | string | Owner / investor name or entity |
| branch_name | string | Name of the franchise branch |
| location | string | City / address |
| contact | string | |
| status | enum | active, inactive, terminated |
| created_by | User | Admin who created the record |
| created_at | datetime | |

### Franchise Agreement
| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| franchisee | Franchisee | |
| buy_in_fee | decimal | One-time fee paid at signing |
| monthly_royalty | decimal | Fixed amount paid monthly to VernonEdu |
| revenue_royalty_pct | decimal | % of gross branch revenue paid to VernonEdu |
| start_date | date | |
| end_date | date | Nullable |
| status | enum | active, inactive, terminated |

All three financial components (buy-in, monthly, revenue %) are **individually negotiated per franchisee** — no global default.

## Branch Revenue

Gross branch revenue = enrollment fees from branch + other branch revenue entries.

### Branch Other Revenue
Admin can add non-enrollment revenue for a branch (e.g., event fees, merchandise, space rental).

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| franchisee | Franchisee | Which branch |
| label | string | e.g., "Event fee", "Space rental" |
| amount | decimal | |
| revenue_date | date | |
| added_by | User (role: admin) | |
| created_at | datetime | |

### Royalty Payment Record
Tracks whether royalty has been paid each period.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| franchise_agreement | Franchise Agreement | |
| period | string | e.g., "2026-04" (YYYY-MM) |
| gross_revenue | decimal | Enrollment + other revenue for the period |
| monthly_royalty | decimal | Fixed amount from agreement |
| revenue_royalty | decimal | gross_revenue × revenue_royalty_pct |
| total_royalty | decimal | monthly_royalty + revenue_royalty |
| status | enum | unpaid, overdue, paid — overdue: past the royalty due date; set by background job |
| created_at | datetime | |
| paid_at | datetime | Nullable |
| recorded_by | User | Admin |

## Business Rules

1. Franchisee role is **investor / location owner only** — no operational authority
2. All courses, pricing, instructors, and scheduling at franchise branch governed by VernonEdu
3. B2B and B2C rules apply identically at franchise branches
4. Gross branch revenue = enrollment fees from that branch + Branch Other Revenue entries
5. Revenue royalty = gross_revenue × revenue_royalty_pct (from agreement)
6. Monthly royalty = flat fee from agreement, regardless of revenue
7. Total royalty per period = monthly_royalty + revenue_royalty
8. Buy-in fee is one-time at agreement signing — non-refundable
9. `revenue_royalty_pct` must be between 0–100
10. Franchise gross branch revenue is calculated from Enrollment records where `enrollment.franchisee = this Franchisee`. The `franchisee` field on Enrollment is set at enrollment creation time for franchise branch enrollments.
11. Admin must set the `franchisee` field on enrollments originating from a franchise branch. Future automation (e.g., branch-linked course batches) may set this automatically.

## Background Jobs
- **Royalty overdue check** (monthly, on the 15th): any `RoyaltyPaymentRecord` with `status = unpaid` and whose period end date is > 14 days ago → set `status = overdue`

## Revenue Reporting Requirement

Per period (monthly):
- Admin calculates gross revenue (enrollment + other)
- System computes royalty breakdown
- Royalty Payment Record created → franchisee pays → admin marks paid

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| — | — | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [profit-split](../profit-split/profit-split.md)
