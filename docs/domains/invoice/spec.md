# Design: Invoice Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Formal billing document linked to Enrollment + Payment, addressable to Partner or Student

---

## Overview

Formal billing document linked to Enrollment and Payment. Addressable to Partner (B2B, payer = partner) or Student (B2C, or B2B payer = student). Admin can add custom line items. Invoice number auto-generated.

---

## Entities

### Invoice

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| invoice_number | string | Auto-generated, unique |
| enrollment | Enrollment | |
| payment | Payment | |
| billed_to | enum | `partner`, `student` |
| partner | Partner | Nullable; set if `billed_to = partner` |
| student | Student | Nullable; set if `billed_to = student` |
| status | enum | `draft`, `sent`, `paid`, `overdue`, `cancelled` |
| issued_date | date | |
| due_date | date | Nullable |
| subtotal | decimal | Sum of line items before discount |
| discount_amount | decimal | Default 0 |
| total_amount | decimal | subtotal - discount_amount |
| notes | string | Nullable; printed on invoice |
| created_by | User | |
| created_at | datetime | |

### InvoiceLineItem

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| invoice | Invoice | |
| label | string | e.g., "Tuition Fee", "Admin Fee", "Discount" |
| amount | decimal | Positive = charge, negative = deduction |
| sort_order | integer | Display order |

---

## Business Rules

0. Auto-creation: For B2B enrollments (`payer = partner`), invoice auto-created with `status = draft` on `enrollment.confirmed`. For B2C, manual (admin drafts when needed). Auto-created defaults `billed_to = partner`.
1. `billed_to = partner` requires `partner` set; `student` null
2. `billed_to = student` requires `student` set; `partner` null
3. B2B (`payer = partner`): `billed_to` defaults to `partner`
4. B2C: `billed_to` defaults to `student`
5. Admin can override `billed_to`
6. `total_amount` = sum of InvoiceLineItem amounts (negative = deduction)
7. Line items editable only when `status = draft`
8. `status = paid` auto-set when linked Payment `status = paid`
9. `status = overdue` auto-set when `due_date < today` and `status != paid`
10. One invoice per enrollment — admin reissues by cancelling and creating new draft
11. Unique partial constraint: only one non-cancelled Invoice per enrollment. `UNIQUE (enrollment_id) WHERE status != 'cancelled'`

---

## Background Jobs

- **Overdue check** (daily): any Invoice with `status = sent` and `due_date < today` → `status = overdue` → fire `invoice.overdue`

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `invoice.sent` | `{invoice_id, enrollment_id, billed_to, total_amount}` | Notification |
| `invoice.overdue` | `{invoice_id, enrollment_id, billed_to, due_date}` | Notification |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `enrollment.confirmed` | Enrollment | Auto-create draft Invoice for B2B |
| `payment.confirmed` | Payment | Auto-set `status = paid` on linked Invoice |

---

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [payment](../payment/payment.md)
- [partner](../partner/partner.md)
- [student](../student/student.md)
