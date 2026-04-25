# Domain: Institution

## Overview

Schools and universities that partner with VernonEdu under the B2B model. Each institution has a partnership agreement that governs pricing, payer, and which programs are offered.

## Entities

### Institution
| Field | Type | Notes |
|---|---|---|
| name | string | School or university name |
| type | enum | school, university |
| contact_person | string | PIC at institution |
| email | string | |
| phone | string | |

### Partnership Agreement
| Field | Type | Notes |
|---|---|---|
| institution | Institution | |
| payment_model | enum | per_visit, per_course, per_student |
| payer | enum | institution, student | Who pays VernonEdu |
| bulk_price | decimal | Nullable; overrides standard pricing for all batches in this agreement |
| start_date | date | |
| end_date | date | Nullable (open-ended) |
| status | enum | active, inactive, expired |

## Payment Models

| Model | Description |
|---|---|
| per_visit | Institution pays per session/visit delivered |
| per_course | Fixed fee per course regardless of student count |
| per_student | Fee × number of enrolled students |

### Partnership Agreement Batch (junction)
Specific batches included in the agreement. Many-to-many between agreement and course batches.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| partnership_agreement | Partnership Agreement | |
| course_batch | Course Batch | Specific batch covered |
| batch_bulk_price | decimal | Nullable; overrides agreement-level bulk_price for this batch only |

## Business Rules

1. One institution can have one active partnership agreement
2. Payer (institution or student) is set at agreement level — overrides B2C default
3. Bulk price resolution: `batch_bulk_price` → `agreement.bulk_price` → `course_batch.price`
4. Only course batches listed in the agreement are accessible to institution's students
5. B2B enrollment validates that the course batch is in the institution's agreement

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [student](../student/student.md)
