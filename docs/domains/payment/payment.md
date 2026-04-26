# Domain: Payment

## Overview

Manages all payment activity for enrollments. Supports full payment and admin-managed installment (cicilan). Two payment methods: payment gateway (Midtrans/Xendit) and manual bank transfer.

Student-facing: full payment only. Installment is admin-only.

## Entities

### Payment
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| enrollment | Enrollment | One payment per enrollment |
| payment_type | enum | full, installment |
| total_amount | decimal | Total to be paid |
| paid_amount | decimal | Sum of all confirmed transactions |
| status | enum | pending, partial, paid, overdue |

### Payment Term
One term for full payment. N terms for installment (created by admin).

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| payment | Payment | |
| term_number | integer | 1, 2, 3... |
| due_date | date | |
| amount | decimal | Amount due for this term |
| status | enum | unpaid, paid, overdue |

### Payment Transaction
One or more transactions per term (e.g., student retries after failure).

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| payment_term | Payment Term | |
| method | enum | gateway, bank_transfer |
| amount | decimal | |
| status | enum | pending, confirmed, failed |
| gateway_ref | string | Nullable; gateway transaction ID |
| proof_url | string | Nullable; bank transfer proof upload URL |
| confirmed_by | User | Nullable; admin who confirmed bank transfer |
| confirmed_at | datetime | Nullable |
| created_at | datetime | |

## Payment Status Flow

```
Enrollment created
  → Payment created (status: pending, 1 term auto-created for full payment)

Student pays via gateway:
  → Transaction created (pending)
  → Webhook received → Transaction confirmed
  → Term status → paid
  → Payment paid_amount updated
  → If all terms paid → Payment status → paid

Student pays via bank transfer:
  → Transaction created (pending)
  → Student uploads proof → proof_url set
  → Admin confirms → Transaction confirmed
  → Term + Payment updated same as above

Admin converts to installment:
  → payment_type → installment
  → Admin creates N Payment Terms manually
  → Student notified per term due date
```

## Payment States

| State | Meaning |
|---|---|
| pending | No confirmed payment yet |
| partial | At least one term paid, not all |
| paid | All terms fully paid |
| overdue | One or more terms past due_date and unpaid |

## Refund Handling

Triggered when enrollment is dropped. Admin selects one of these options case by case:

### Refund Entity
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| enrollment | Enrollment | |
| payment | Payment | |
| refund_type | enum | full, partial, no_refund, credit |
| refund_amount | decimal | Nullable; set for full/partial |
| credit_amount | decimal | Nullable; set for credit type |
| reason | string | Admin notes |
| processed_by | User | Admin who processed |
| processed_at | datetime | |
| status | enum | pending, completed |

### Refund Types
| Type | Description |
|---|---|
| full | Entire paid_amount returned to student |
| partial | Custom amount returned (admin sets amount) |
| no_refund | No money returned |
| credit | Amount converted to student credit for future enrollment |

### Student Credit
If refund_type = `credit`, a Credit record is created for the student:

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| student | Student | |
| amount | decimal | Usable credit balance |
| source_refund | Refund | Which refund created this credit |
| used_amount | decimal | Default 0 |
| remaining_amount | decimal | amount - used_amount |
| expires_at | date | Nullable |
| created_at | datetime | |

Credit can be applied at next enrollment to reduce payment amount.

## Business Rules

1. Full payment = 1 term auto-created at enrollment
2. Installment terms are created by admin only — student has no visibility during enrollment
3. Bank transfer requires admin confirmation before transaction is marked confirmed
4. Gateway transactions confirmed via webhook — no manual step
5. `paid_amount` = sum of all confirmed transaction amounts
6. `overdue` check: run daily — any term with `due_date < today` and `status = unpaid`
7. Student notified on each term due date — triggers `payment.term.due` via Notification domain
8. Refund type is chosen by admin per dropped enrollment — no automatic rule
9. Credit balance applied before other payment methods at next enrollment
10. Payment Terms sum must equal `total_amount`
11. `total_amount` must equal enrollment `final_price`

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `payment.confirmed` | `{payment_id, enrollment_id, amount}` | Notification, Invoice |
| `payment.term.due` | `{payment_term_id, enrollment_id, due_date, amount}` | Notification, Calendar |
| `payment.term.overdue` | `{payment_term_id, enrollment_id, due_date}` | Notification |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `enrollment.confirmed` | Enrollment | Auto-create Payment + 1 PaymentTerm (full payment) |

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [student](../student/student.md)
- [notification](../notification/notification.md)
- [calendar](../calendar/calendar.md)
