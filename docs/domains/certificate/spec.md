# Design: Certificate Domain

**Date:** 2026-04-26
**Status:** Approved
**Scope:** Certificate issuance, public validation, and revoke/reissue approval

---

## Overview

Manages certificates issued to students upon course completion. Supports VernonEdu-issued and third-party partner certificates. Each certificate has a unique number and QR code for public validation.

---

## Entities

### CertificateType
System registry of all certificate types. Validity defined here, not per course.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| name | string | e.g., "BNSP", "CompTIA" |
| category | enum | vernonedu_competence, vernonedu_participation, partner |
| validity_months | integer | Nullable; null = no expiry |
| is_active | boolean | |
| created_by | User | vernonedu_admin |

### CertificateConfig (on Course)
Links course to one or more CertificateTypes.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | |
| certificate_type | CertificateType | |
| issued_on | enum | completion, manual |

### StudentCertificate
Issued per student per enrollment per config.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| enrollment | Enrollment | |
| certificate_type | CertificateType | Denormalized from config |
| certificate_config | CertificateConfig | |
| certificate_number | string | Unique (e.g., VE-2026-00123) |
| issued_at | datetime | |
| status | enum | pending, issued, revoked |
| qr_code_url | string | |
| expires_at | date | Nullable; from config.validity_months |
| revoked_at | datetime | Nullable |
| revoked_by | User | Nullable |
| reissued_from | StudentCertificate | Nullable |

### CertificateActionRequest
Both revoke and reissue are admin-initiated, approval-gated.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| student_certificate | StudentCertificate | |
| action | enum | revoke, reissue |
| reason | string | Required |
| requested_by | User | |
| approved_by | User | Nullable; role academic_leader or ceo |
| status | enum | pending, approved, rejected |
| created_at | datetime | |
| resolved_at | datetime | Nullable |

---

## Issuance Flow

```
Course completion (or manual trigger)
  → StudentCertificate created (status: pending)
  → Certificate number generated (unique, VE-{YYYY}-{NNNNN})
  → QR code generated → /cert/verify/{certificate_number}
  → Status → issued
  → Student notified
```

## Reissue Flow

```
Admin requests reissue → Approval pending → Approved
  → Original cert status → revoked
  → New StudentCertificate created (reissued_from = original)
  → New cert number + QR
```

## Revoke Flow

```
Admin requests revoke → Approval pending → Approved
  → Status → revoked → QR validator shows: invalid/revoked
```

---

## Business Rules

1. Each course can issue 1+ certificate types
2. One StudentCertificate per CertificateConfig per enrollment
3. Certificate number unique across all certificates; format VE-{YYYY}-{NNNNN}, per-year sequence with unique DB index
4. QR validator always reflects current status
5. Revoke and reissue require approval (academic_leader or ceo)
6. `issued_on: completion` → auto-issued on enrollment.completed
7. `issued_on: manual` → admin triggers
8. Download requires profile completion
9. `expires_at = issued_at + certificate_type.validity_months`; null if no validity
10. Expired certificates show as invalid on validator. `expired` is **derived** from `expires_at`, NOT a persisted status. `status` only stores `pending`/`issued`/`revoked`
11. Retroactive `completion_status` change `completed → dropped` does NOT auto-revoke; manual revoke required
12. Public validator at `vernonedu.id/cert/verify/{certificate_number}` — no login
13. Student dashboard lists all own certs; download gated by profile completion

---

## Background Jobs

The following time-based transitions require a scheduled background job:
- **Expiry-flag check** (daily): flag certificates with `expires_at < today + 30 days` for CRM follow-up (renewal opportunity)

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `certificate.issued` | `{certificate_id, student_id, enrollment_id, certificate_number}` | Notification |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `enrollment.completed` | Enrollment | Auto-issue certificates where `issued_on = completion` |

---

## Related Domains

- [course](../course/course.md)
- [enrollment](../enrollment/enrollment.md)
- [student](../student/student.md)
- [notification](../notification/notification.md)
