# Design: Invoice Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** New Invoice domain — formal billing document addressable to Partner or Student

---

## Overview

Formal billing document linked to Enrollment and Payment. Addressable to Partner (B2B, payer = partner) or Student (B2C). Admin can add custom line items. Invoice number is auto-generated.

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
| notes | string | Nullable; admin notes printed on invoice |
| created_by | User | |
| created_at | datetime | |

### InvoiceLineItem

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| invoice | Invoice | |
| label | string | e.g. "Tuition Fee", "Admin Fee", "Discount" |
| amount | decimal | Positive = charge, negative = deduction |
| sort_order | integer | Display order |

---

## Business Rules

1. `billed_to = partner` requires `partner` field set; `student` field null
2. `billed_to = student` requires `student` field set; `partner` field null
3. For B2B enrollments (`payer = partner`): `billed_to` defaults to `partner`
4. For B2C enrollments: `billed_to` defaults to `student`
5. Admin can override `billed_to` — default is not enforced
6. `total_amount` = sum of all InvoiceLineItem amounts (negative items = deductions)
7. Line items editable only when `status = draft`
8. `status = paid` auto-set when linked Payment `status = paid`
9. `status = overdue` auto-set when `due_date < today` and `status != paid`
10. One invoice per enrollment — admin can reissue by cancelling and creating new draft

---

## Related Domains

- [enrollment](../domains/enrollment/enrollment.md)
- [payment](../domains/payment/payment.md)
- [partner](../domains/partner/partner.md)
- [student](../domains/student/student.md)
