# Design: Student Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Student profile + extended profile required for certificate download

---

## Overview

Individuals who enroll in VernonEdu courses. B2B (via partner) or B2C (direct web registration). B2C self-registers with minimal fields; extended profile required before certificate download.

---

## Entities

### Student
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| name | string | Required at registration |
| email | string | Required |
| phone | string | Required |
| password | string | Hashed |
| source | enum | b2b, b2c |
| partner | Partner | Nullable; if B2B |

### StudentProfile (extended)
Required before certificate download. Collected after registration.

| Field | Type | Notes |
|---|---|---|
| student | Student | One-to-one |
| date_of_birth | date | |
| gender | enum | male, female |
| id_type | enum | ktp, passport, sim |
| id_number | string | |
| address | string | |
| city | string | |
| province | string | |
| postal_code | string | |
| profile_complete | boolean | True when all required filled |
| created_at | datetime | |
| updated_at | datetime | Nullable |

---

## Registration

B2C minimal fields: name, email, phone, password. Extended profile prompted on certificate download attempt.

---

## Business Rules

1. B2B students associated with a partner; payment may be partner-handled
2. B2C registers via web and pays directly
3. B2B partner student can also independently enroll in B2C courses
4. `profile_complete = true` required before any certificate download
5. Student dashboard shows enrollments + certificates
6. `student.profile_completed` fires when `profile_complete: false → true`. CRM/analytics hook — no current internal listeners
7. Student registration creates both Student record and Auth user simultaneously; Auth fires `auth.user.created`

---

## Background Jobs

| — | — | — |

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `student.profile_completed` | `{student_id}` | — |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| — | — | — |

---

## Related Domains

- [enrollment](../enrollment/enrollment.md)
- [course](../course/course.md)
- [partner](../partner/partner.md)
- [certificate](../certificate/certificate.md)
- [payment](../payment/payment.md)
