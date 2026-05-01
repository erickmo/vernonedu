# Design: Enrollment Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Student registration into Course Batches; B2C self-enrollment and B2B admin-managed

---

## Overview

Records a student's registration into a Course Batch. Captures format, delivery mode, payer, payment status, completion status. B2C students self-enroll via web; B2B is admin-managed.

---

## Entities

### Enrollment
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| student | Student | |
| course_batch | CourseBatch | Batch-level enrollment |
| format | enum | regular, private, inhouse_training, inschool_program |
| mode | enum | online, offline |
| payer | enum | student, partner |
| partner | Partner | Nullable; B2B only |
| franchisee | Franchisee | Nullable; if branch enrollment |
| price | decimal | Resolved at enrollment time |
| final_price | decimal | After voucher; equals price if no voucher |
| voucher | Voucher | Nullable |
| credit_applied | decimal | Nullable; reduces payment amount, not final_price |
| student_credit | StudentCredit | Nullable; FK to credit used |
| payment_status | enum | pending, partial, paid, overdue |
| completion_status | enum | ongoing, completed, dropped |
| source | enum | b2b, b2c |
| created_at | datetime | |

Web self-enrollment only allows `regular` and `private`. `inhouse_training` and `inschool_program` are admin-created only.

---

## Pricing Resolution

```
B2B, payer=partner OR payer=student:
  price = course_batch.batch_bulk_price
        ?? partnership_agreement.bulk_price
        ?? course_batch.price
  if payer=student:
    voucher and credit apply normally; invoice billed to student

B2C:
  price = course_batch.price
  if voucher:
    final_price = apply_voucher(price, voucher)
    (may go below course.min_price — voucher allows)
  payer = 'student'
```

---

## B2C Web Enrollment Flow

```
Browse batches
  → Select format + mode (only available shown)
  → Register or login (minimal fields)
  → Review + price
  → Choose payment method: gateway | bank transfer
  → Pay → Enrollment confirmed
```

---

## Business Rules

1. Format + mode must match the batch's CourseFormatConfig
2. B2B `payer` from partnership agreement, not student
3. B2B with bulk pricing: price from agreement, not catalog
4. B2C: price = course_batch.price
5. `partner` only set for B2B
6. B2C web: full payment only (gateway or bank transfer)
7. Installment is admin-only — not web-exposed
8. On `enrollment.confirmed`: Payment domain auto-creates Payment + 1 PaymentTerm (full)
9. Certificate issued on `completion_status → completed` (for `issued_on: completion` configs)
10. No duplicate enrollment in same batch — unique `(student, course_batch)` at DB level
11. Web enrollment requires batch `web_registration_open = true`
12. Blocked outside `registration_open_at` to `registration_close_at`
13. Blocked if format's `max_students` reached
14. B2B `payer = student` → voucher and credit apply normally; invoice billed to student
15. `franchisee` set when branch enrollment — enables royalty branch revenue calc

---

## Background Jobs

| — | — | — |

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `enrollment.confirmed` | `{enrollment_id, student_id, course_batch_id, source}` | Notification, Invoice, Payment, Module |
| `enrollment.completed` | `{enrollment_id, student_id, course_batch_id}` | Certificate |
| `enrollment.dropped` | `{enrollment_id, student_id}` | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

---

## Related Domains

- [student](../student/student.md)
- [course](../course/course.md)
- [partner](../partner/partner.md)
- [payment](../payment/payment.md)
- [certificate](../certificate/certificate.md)
- [notification](../notification/notification.md)
- [franchise](../franchise/franchise.md)
