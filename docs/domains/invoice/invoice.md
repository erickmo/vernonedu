# Domain: Invoice

## Overview

Formal billing document linked to an Enrollment and its Payment. Addressable to a Partner (B2B) or Student (B2C). Admin generates invoices and can add custom line items. Invoice number is auto-generated and unique.

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
10. One invoice per enrollment — admin reissues by cancelling and creating a new draft

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `invoice.sent` | `{invoice_id, enrollment_id, billed_to, total_amount}` | Notification |
| `invoice.overdue` | `{invoice_id, enrollment_id, billed_to, due_date}` | Notification |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `payment.confirmed` | Payment | Auto-set `status = paid` on linked Invoice |

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [payment](../payment/payment.md)
- [partner](../partner/partner.md)
- [student](../student/student.md)
