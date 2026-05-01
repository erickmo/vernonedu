# Design: Payment Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** All enrollment payment activity; full payment, admin installments, refunds, student credit

---

## Overview

Manages all payment activity for enrollments. Supports full payment and admin-managed installment (cicilan). Two payment methods: gateway (Midtrans/Xendit) and manual bank transfer. Student-facing: full payment only. Installment is admin-only.

---

## Entities

### Payment
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| enrollment | Enrollment | One payment per enrollment |
| payment_type | enum | full, installment |
| total_amount | decimal | Total to be paid; equals enrollment.final_price |
| paid_amount | decimal | Sum of confirmed transactions |
| status | enum | pending, partial, paid, overdue |

### PaymentTerm
One term for full. N terms for installment.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| payment | Payment | |
| term_number | integer | 1, 2, 3... |
| due_date | date | |
| amount | decimal | |
| status | enum | unpaid, paid, overdue |

### PaymentTransaction
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| payment_term | PaymentTerm | |
| method | enum | gateway, bank_transfer |
| amount | decimal | |
| status | enum | pending, confirmed, failed, cancelled |
| gateway_ref | string | Nullable; gateway tx ID |
| proof_url | string | Nullable; bank transfer proof |
| confirmed_by | User | Nullable; admin who confirmed |
| confirmed_at | datetime | Nullable |
| created_at | datetime | |

### Refund
Triggered when enrollment dropped. Admin selects type case-by-case.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| enrollment | Enrollment | |
| payment | Payment | |
| refund_type | enum | full, partial, no_refund, credit |
| refund_amount | decimal | Nullable; full/partial |
| credit_amount | decimal | Nullable; for credit type |
| reason | string | |
| processed_by | User | Admin |
| processed_at | datetime | |
| status | enum | pending, completed |

### StudentCredit
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| student | Student | |
| amount | decimal | Initial credit |
| source_refund | Refund | |
| used_amount | decimal | Default 0 |
| remaining_amount | decimal | amount - used_amount |
| expires_at | date | Nullable |
| created_at | datetime | |

---

## Payment Status Flow

```
Enrollment created
  → Payment created (status: pending, 1 term auto-created for full)

Gateway:
  → Transaction (pending) → webhook → confirmed
  → Term → paid; paid_amount updated
  → All terms paid → Payment → paid

Bank transfer:
  → Transaction (pending) → student uploads proof → admin confirms

Admin convert to installment:
  → payment_type → installment
  → Admin creates N PaymentTerms manually
  → Notify per due_date
```

---

## Payment States

| State | Meaning |
|---|---|
| pending | No confirmed payment yet |
| partial | At least one term paid, not all |
| paid | All terms fully paid |
| overdue | One or more terms past due_date and unpaid |

---

## Refund Types

| Type | Description |
|---|---|
| full | Entire paid_amount returned |
| partial | Custom admin-set amount |
| no_refund | None |
| credit | Convert to StudentCredit for future enrollment |

---

## Business Rules

1. Full payment = 1 term auto-created at enrollment
2. Installment terms admin-only; not student-visible during enrollment
3. Bank transfer requires admin confirmation
4. Gateway confirmed via webhook
5. `paid_amount` = sum of confirmed transactions
6. Term `overdue` check: daily; `due_date < today` AND `status = unpaid`
7. Term-due notification fires `payment.term.due`
8. Refund type chosen by admin per dropped enrollment — no auto rule
9. Credit balance applied before other payment methods at next enrollment
10. PaymentTerms sum = `total_amount`
11. `total_amount` = enrollment.final_price
12. Webhook idempotent — duplicate for confirmed tx silently ignored
13. Gateway tx pending > 24h → cancelled; student can retry
14. Webhook arriving for tx of dropped enrollment → rejected; tx → cancelled
15. Voucher applied first (changes price → final_price on Enrollment). StudentCredit applied against outstanding payment — does not change final_price
16. Credit on installment reduces first term, then subsequent in order, until exhausted
17. Convert-to-installment after credit applied: credit remains as originally allocated to first term(s)

---

## Background Jobs

- **Term overdue check** (daily): PaymentTerm with `due_date < today` AND `status = unpaid` → `status = overdue` → fire `payment.term.overdue`
- **Transaction timeout** (daily): PaymentTransaction `status = pending` AND `created_at < 24h ago` → `status = cancelled`

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `payment.confirmed` | `{payment_id, enrollment_id, amount}` | Notification, Invoice, Profit-split |
| `payment.term.due` | `{payment_term_id, enrollment_id, due_date, amount}` | Notification, Calendar |
| `payment.term.overdue` | `{payment_term_id, enrollment_id, due_date}` | Notification |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `enrollment.confirmed` | Enrollment | Auto-create Payment + 1 PaymentTerm (full payment) |

---

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [student](../student/student.md)
- [notification](../notification/notification.md)
- [calendar](../calendar/calendar.md)
