# Domain: Student

## Overview

Individuals who enroll in VernonEdu courses. Can come through B2B (via partner partnership) or B2C (direct registration via web). B2C students self-register with minimal fields; extended profile required before certificate download.

## Entities

### Student
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| name | string | Required at registration |
| email | string | Required at registration |
| phone | string | Required at registration |
| password | string | Hashed; required at registration |
| source | enum | b2b, b2c |
| partner | Partner | Nullable; set if student came via B2B partnership |

### Student Profile (extended)
Required before certificate download. Collected separately after registration.

| Field | Type | Notes |
|---|---|---|
| student | Student | One-to-one |
| date_of_birth | date | |
| gender | enum | male, female |
| id_type | enum | ktp, passport, sim |
| id_number | string | KTP / passport / SIM number |
| address | string | Full address |
| city | string | |
| province | string | |
| postal_code | string | |
| profile_complete | boolean | True when all required fields filled |
| created_at | datetime | |
| updated_at | datetime | Nullable; set on any profile field update |

## Registration

B2C students register via web with minimal fields only:
- Name, email, phone, password

Extended profile collected later — prompted when student attempts to download a certificate.

## Business Rules

1. B2B students are associated with a partner — payment may be handled by partner
2. B2C students register via web and pay directly
3. A student from a B2B partner can also independently enroll in B2C courses
4. Extended profile (`profile_complete = true`) required before any certificate download
5. Student can track all enrollments and certificates from their dashboard
6. `student.profile_completed` fires when `profile_complete` transitions from `false` to `true`. Intended for CRM/analytics hooks — no current internal listeners.
7. Student registration creates both a `Student` record and an `Auth` user account simultaneously. The Auth domain fires `auth.user.created` on account creation.

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `student.profile_completed` | `{student_id}` | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [course](../course/course.md)
- [partner](../partner/partner.md)
- [certificate](../certificate/certificate.md)
- [payment](../payment/payment.md)
