# Design: Cross-Domain Updates + Reporting Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Profit split basis, B2B admin flow, partner split calculation, new Reporting domain

---

## Overview

Four changes in this spec:

1. **Profit Split** — basis changed from `payment.paid_amount` to `enrollment.final_price`
2. **B2B Admin Flow** — admin-managed enrollment; dual-track payment (Invoice for billing, Payment for reconciliation)
3. **Partner Split** — calculated at `batch.closed`, not at `enrollment.confirmed`
4. **Reporting Domain** — new read-model layer for financial, facilitator fee, and operational reports

---

## 1. Profit Split — Basis Update

**Change:** Profit split calculated from `enrollment.final_price`, not `payment.paid_amount`.

**Updated formula (profit-split domain):**

```
Batch Revenue = SUM(enrollment.final_price
                   WHERE course_batch = this
                   AND completion_status != 'dropped')
              + SUM(extra_revenue.amount WHERE approval_status = 'approved')

Batch Costs   = SUM(batch_cost_line_item.amount WHERE is_removed = false)

Net Profit    = Batch Revenue - Batch Costs
```

Unpaid enrollments are included in revenue — dropped enrollments are excluded.

**Domain docs to update:**
- `docs/domains/profit-split/profit-split.md` — Business Rule #8: clarify final_price basis

---

## 2. B2B Admin Flow

### Enrollment
All B2B enrollments are admin-created. Web self-enrollment is not available for B2B regardless of payer.

### Payment Flow — `payer = partner`
*(e.g., school pays for their students' tuition)*

```
Admin creates B2B enrollment (payer = partner)
  → enrollment.confirmed fires
  → Invoice auto-created (draft), billed_to = partner
  → Payment + 1 PaymentTerm auto-created (full amount)

Admin reviews and sends invoice to partner
  → Invoice status → sent

Partner pays externally (bank transfer)
  → Admin records PaymentTransaction (method: bank_transfer)
  → Admin confirms transaction
  → PaymentTerm status → paid
  → Payment status → paid
  → Invoice status → paid (via payment.confirmed event)
```

### Payment Flow — `payer = student` (B2B)
*(e.g., company training — individual employees pay)*

```
Admin creates B2B enrollment (payer = student)
  → enrollment.confirmed fires
  → Invoice auto-created (draft), billed_to = student
  → Payment + 1 PaymentTerm auto-created

Student pays via gateway OR bank transfer
  → Same flow as B2C payment
```

### Business Rules

1. B2B enrollment creation is admin-only — no web self-enrollment regardless of payer
2. `payer = partner` → PaymentTransaction method must be `bank_transfer`; admin confirms
3. `payer = student` (B2B) → gateway or bank transfer allowed, same as B2C
4. Invoice and Payment are both created on `enrollment.confirmed` — existing behavior unchanged
5. Invoice tracks billing document; Payment tracks actual transaction for reconciliation

**Domain docs to update:**
- `docs/domains/enrollment/enrollment.md` — add rule: B2B enrollment is admin-only
- `docs/domains/payment/payment.md` — add rule: B2B payer=partner → bank_transfer only
- `docs/domains/invoice/invoice.md` — no change needed (auto-creation already documented)

---

## 3. Partner Split — Calculation at Batch Close

**Change:** Remove auto-creation of `partner_split` BatchCostLineItem at `enrollment.confirmed`. Calculate at `batch.closed` instead.

### Calculation

One `BatchCostLineItem` created per PartnershipAgreement per batch when batch closes:

```
per_student:
  amount = agreement.bulk_price × COUNT(enrollments
             WHERE course_batch = this
             AND partner = agreement.partner
             AND completion_status != 'dropped')

per_course:
  amount = agreement.bulk_price  (flat fee)

per_visit:
  amount = agreement.bulk_price × COUNT(classes WHERE course_batch = this)
```

Fields set on the created item:
- `reference_type = partner_split`
- `reference_id = PartnershipAgreement.id`
- `cost_type = fixed`
- `is_removed = false`
- `amount` = calculated above

### Business Rules

1. Partner split BatchCostLineItem is created at `batch.closed`, not at `enrollment.confirmed`
2. One item per PartnershipAgreement per batch — if multiple partners enrolled, one item per partner
3. If no B2B enrollments from a partner in this batch, no item created for that agreement
4. Once created at batch close, the item follows normal BatchCostLineItem rules (overridable by admin)
5. Partner split amount is frozen at batch close time — subsequent enrollment status changes (e.g., student dropped post-close) do not retroactively change the partner split amount

**Domain docs to update:**
- `docs/domains/profit-split/profit-split.md` — Business Rule #11: change trigger from enrollment.confirmed to batch.closed; update formula
- `docs/domains/partnership-agreement/partnership-agreement.md` — note partner split timing

---

## 4. Reporting Domain (New)

Read-model layer. Pure consumer — no business logic, no events fired. Consumes events from other domains to build and maintain snapshots.

### Persisted Snapshots

#### FinancialPeriodReport
Aggregated financial summary per period. Admin triggers calculation after profit split is finalized.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| period | string | YYYY-MM |
| total_gross_revenue | decimal | SUM(enrollment.final_price) non-dropped |
| total_extra_revenue | decimal | SUM(approved extra revenue entries) |
| total_costs | decimal | SUM(batch cost line items) |
| total_net_profit | decimal | total_gross_revenue + total_extra_revenue - total_costs |
| vernonedu_amount | decimal | total_net_profit × vernonedu_pct |
| course_creator_amount | decimal | total_net_profit × course_creator_pct |
| dept_leader_amount | decimal | total_net_profit × dept_leader_pct |
| batch_count | integer | Number of batches closed in this period |
| enrollment_count | integer | Total non-dropped enrollments in period |
| status | enum | `draft`, `finalized` |
| calculated_at | datetime | |
| calculated_by | User | Admin who triggered calculation |

---

#### FacilitatorFeeReport
Per facilitator per period. Calculated same time as FinancialPeriodReport.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| period | string | YYYY-MM |
| facilitator | TeamMember | |
| total_fee | decimal | SUM(BatchCostLineItem.amount WHERE reference_type = facilitator_fee AND reference_id IN (FacilitatorProposal.id WHERE facilitator = this TeamMember)) |
| batch_count | integer | Number of batches this facilitator appeared in |
| class_count | integer | Total classes taught by this facilitator in period |
| calculated_at | datetime | |

---

### On-Demand Queries
No persistence. Real-time aggregation from existing domain tables.

| Report | Data Source | Notes |
|---|---|---|
| PaymentStatus | Payment + Invoice | Outstanding amount, overdue terms per student or partner |
| AttendanceSummary | AttendanceRecord | Per batch: per student attendance %, present/absent/excused breakdown |
| EnrollmentStats | Enrollment | Per batch: total enrolled, format breakdown, completion rate, dropout rate |
| FranchiseBranchRevenue | RoyaltyPaymentRecord + Enrollment | Per franchisee per period: gross revenue, royalty breakdown |

---

### Access Control

| Role | Access Scope |
|---|---|
| CEO, Finance, Admin | All reports, all data |
| Dept Leader | FinancialPeriodReport filtered to own dept; AttendanceSummary + EnrollmentStats for own dept's batches |
| Course Creator | FacilitatorFeeReport for own courses; AttendanceSummary + EnrollmentStats for own courses |
| Franchisee | FranchiseBranchRevenue — own branch only |

---

### Cross-Domain Events

#### Triggers (I fire these)
None — read-model domain does not fire events.

#### Listens (I react to these)
| Event | Source | Action |
|---|---|---|
| `profit_split.calculated` | Profit Split | Populate/update FinancialPeriodReport + FacilitatorFeeReport for that batch's period |

---

### Business Rules

1. Reporting domain is read-only — it never modifies data in other domains
2. `FinancialPeriodReport` status `finalized` is set by admin — once finalized, recalculation is blocked unless admin explicitly resets to `draft`
3. `FacilitatorFeeReport` is always recalculated together with `FinancialPeriodReport` for the same period
4. On-demand queries always reflect current state — no caching
5. Access control filters data by role scope — Dept Leader and Course Creator never see data outside their scope
6. Franchisee access is strictly read-only and scoped to their own branch

---

## Related Domains

- [profit-split](../../domains/profit-split/profit-split.md)
- [enrollment](../../domains/enrollment/enrollment.md)
- [payment](../../domains/payment/payment.md)
- [invoice](../../domains/invoice/invoice.md)
- [partnership-agreement](../../domains/partnership-agreement/partnership-agreement.md)
- [team-member](../../domains/team-member/team-member.md)
- [franchise](../../domains/franchise/franchise.md)
- [attendance](./2026-04-26-attendance-design.md)
