# Domain: Enrollment

## Overview

Records a student's registration into a Course Batch. Captures format, delivery mode, payer, payment status, and completion status. B2C students self-enroll via web; B2B enrollments are admin-managed.

## Entities

### Enrollment
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| student | Student | |
| course_batch | Course Batch | Enrollment is at batch level |
| format | enum | regular, private, inhouse_training, inschool_program — web self-enrollment only allows regular and private; inhouse_training and inschool_program are admin-created only |
| mode | enum | online, offline |
| payer | enum | student, partner |
| partner | Partner | Nullable; set for B2B enrollments |
| franchisee | Franchisee | Nullable; set when enrollment originates from a franchise branch |
| price | decimal | Resolved at enrollment time |
| final_price | decimal | Actual amount charged after voucher; equals price if no voucher |
| voucher | Voucher | Nullable; applied at enrollment time |
| credit_applied | decimal | Nullable; amount of student credit applied — reduces payment amount, does not change final_price |
| student_credit | StudentCredit | Nullable; FK to the StudentCredit record used (see Payment domain) |
| payment_status | enum | pending, partial, paid, overdue |
| completion_status | enum | ongoing, completed, dropped |
| source | enum | b2b, b2c |
| created_at | datetime | |

## Business Rules

1. Enrollment only allowed if course batch's course supports chosen `format`
2. Enrollment only allowed if course batch's course supports chosen `mode`
3. For B2B: `payer` determined by partnership agreement, not student choice
4. For B2B with bulk pricing: price comes from partnership agreement, not standard catalog
5. For B2C: price = course_batch.price (see Course Batch entity)
6. `partner` field only set for B2B enrollments
7. B2C self-enrollment via web — student pays full payment (gateway or bank transfer)
8. Installment (cicilan) is admin-only — not exposed to student during enrollment
9. On `enrollment.confirmed`, one Payment with one Payment Term is auto-created (full payment) — triggered by the Payment domain listening to this event
10. Certificate issuance triggered when `completion_status` → `completed` (for `issued_on: completion` configs)
11. A student cannot enroll in the same course batch more than once (duplicate enrollment blocked)
12. Enrollment via web only allowed when batch `web_registration_open = true`
13. Enrollment blocked outside `registration_open_at` to `registration_close_at` window if set
14. Enrollment blocked if format's `max_students` reached for this batch
15. Unique constraint on `(student, course_batch)` — duplicate enrollment in the same batch is blocked at the database level
16. For B2B enrollments where `payer = student`, voucher and student credit apply normally — same rules as B2C. Invoice is billed to the student, not the partner.
17. `franchisee` field is set when the enrollment originates from a franchise branch, enabling gross branch revenue calculation for royalty reporting (see Franchise domain)

## Pricing Resolution

```
if B2B and payer = partner:
  price = course_batch.batch_bulk_price (if set on batch)
  else = partnership_agreement.bulk_price (if set on agreement)
  else = course_batch.price
  payer = 'partner'
if B2B and payer = student:
  price = course_batch.batch_bulk_price (if set on batch)
  else = partnership_agreement.bulk_price (if set on agreement)
  else = course_batch.price
  payer = 'student'
  voucher and credit apply normally (same as B2C)
  invoice billed to student
else (B2C):
  price = course_batch.price
  if voucher applied:
    final_price = apply_voucher(price, voucher)
    (final_price may go below course.min_price — voucher explicitly allows this)
  payer = 'student'
```

## B2C Web Enrollment Flow

```
Student browses course batches
  → Selects format + mode (only available options shown)
  → Registers or logs in (minimal fields)
  → Reviews enrollment + price
  → Chooses payment method: gateway | bank transfer
  → Pays → Enrollment confirmed
```

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `enrollment.confirmed` | `{enrollment_id, student_id, course_batch_id, source}` | Notification, Invoice |
| `enrollment.completed` | `{enrollment_id, student_id, course_batch_id}` | Certificate |
| `enrollment.dropped` | `{enrollment_id, student_id}` | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

## Related Domains

- [student](../student/student.md)
- [course](../course/course.md)
- [partner](../partner/partner.md)
- [payment](../payment/payment.md)
- [certificate](../certificate/certificate.md)
- [notification](../notification/notification.md)
- [franchise](../franchise/franchise.md)
