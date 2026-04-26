# Domain: PartnershipAgreement

## Overview

Tracks formal agreements between VernonEdu and a Partner. One Partner can have multiple agreements over time (e.g. annual renewal cycles). Owns expiry tracking, uploaded documents, and B2B payment terms previously embedded in the Institution domain.

## Entities

### PartnershipAgreement

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| partner | Partner | |
| title | string | e.g. "MOU 2025–2026" |
| status | enum | `draft`, `active`, `expired`, `terminated` |
| start_date | date | |
| end_date | date | Nullable; null = open-ended agreement |
| payment_model | enum | Nullable; `per_visit`, `per_course`, `per_student` — B2B only |
| payer | enum | Nullable; `institution`, `student` — B2B only |
| bulk_price | decimal | Nullable; B2B bulk override price for all covered batches |
| signed_at | date | Nullable |
| terminated_at | date | Nullable |
| termination_reason | string | Nullable |
| created_by | User | |
| created_at | datetime | |

### PartnerDocument

Uploaded documents associated with an agreement (MOU, proposals, etc.).

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| agreement | PartnershipAgreement | |
| type | enum | `mou`, `proposal` |
| title | string | |
| file_url | string | |
| uploaded_by | User | |
| uploaded_at | datetime | |

## Payment Models

| Model | Description |
|---|---|
| per_visit | Partner pays per session/visit delivered |
| per_course | Fixed fee per course regardless of student count |
| per_student | Fee × number of enrolled students |

## Business Rules

1. One Partner can have multiple PartnershipAgreements — only one can be `active` at a time
2. `status = expired` auto-set when `end_date < today` and current status was `active`
3. `status = terminated` requires `termination_reason`
4. B2B enrollment resolves `payment_model`, `payer`, `bulk_price` from the partner's `active` agreement
5. Agreement with `status = draft` cannot be referenced by B2B enrollment
6. `end_date = null` = open-ended; never auto-expires
7. Documents can be uploaded at any agreement status
8. Bulk price resolution per enrollment: `batch_bulk_price` (if set on batch) → `agreement.bulk_price` → `course_batch.price`

## Related Domains

- [partner](../partner/partner.md)
- [enrollment](../enrollment/enrollment.md)
- [calendar](../calendar/calendar.md)
