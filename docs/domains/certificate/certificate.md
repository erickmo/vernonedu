# Domain: Certificate

## Overview

Manages certificates issued to students upon course completion. Supports VernonEdu-issued certificates and third-party partner certificates. Each certificate has a unique number and QR code for public validation.

## Entities

### Certificate Type
System-level registry of all certificate types. Managed by VernonEdu admin. Validity is defined here, not per course.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| name | string | e.g., "BNSP", "CompTIA", "Certificate of Competence" |
| category | enum | vernonedu_competence, vernonedu_participation, partner |
| validity_months | integer | Nullable; null = no expiry |
| is_active | boolean | Admin can deactivate |
| created_by | User | VernonEdu admin |

### Certificate Config (on Course)
Links a course to one or more Certificate Types it can issue.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| course | Course | Parent course |
| certificate_type | Certificate Type | Which type this course issues |
| issued_on | enum | completion, manual |

### Student Certificate
Issued per student per enrollment per certificate config.

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| enrollment | Enrollment | |
| certificate_type | Certificate Type | Denormalized from config for quick access |
| certificate_config | Certificate Config | Which config this was issued from |
| certificate_number | string | Unique, human-readable (e.g., VE-2026-00123) |
| issued_at | datetime | |
| status | enum | pending, issued, revoked |
| qr_code_url | string | Points to public validator page |
| expires_at | date | Nullable; set from config.validity_months at issuance |
| revoked_at | datetime | Nullable |
| revoked_by | User | Nullable; admin |
| reissued_from | Student Certificate | Nullable; set if this is a reissue of a revoked cert |

## Issuance Flow

```
Course completion (or manual trigger by admin)
  → Student Certificate created (status: pending)
  → Certificate number generated (unique)
  → QR code generated → URL: /cert/verify/{certificate_number}
  → Status → issued
  → Student notified → can download from dashboard
```

## Certificate Download Gate

Before student can download certificate:
- Extended profile must be complete: address, ID number (KTP/passport), and any other required fields
- If profile incomplete → redirect to profile completion page

## Public Validator Page

- URL: `vernonedu.id/cert/verify/{certificate_number}`
- No login required
- Displays: student name, course name, certificate type, partner name (if any), issued date, status (valid/revoked)
- Accessible via QR code scan

## Student Dashboard

Student can view all their certificates:
- Certificate name + type
- Issue date
- Status (pending/issued/revoked)
- Download button (gated by profile completion)
- QR code display

## Business Rules

1. Each course can issue 1+ certificate types (configured per course)
2. Student receives one Student Certificate per Certificate Config per enrollment
3. Certificate number is unique across all certificates
4. QR code links to public validator — always reflects current status (revoked/expired shows as invalid)
5. Revoke and reissue require approval — see approval flow below
6. `issued_on: completion` → auto-issued when enrollment marked complete
7. `issued_on: manual` → admin triggers issuance
8. Download requires profile completion — enrollment/payment completion not sufficient alone
9. `expires_at` = `issued_at` + `certificate_type.validity_months`; null if validity_months not set
10. Expired certificates (`expires_at < today`) show as invalid on the public validator. `expired` is a **derived state** computed at query time from `expires_at` — it is NOT a persisted status value on `StudentCertificate`. The `status` field only stores `pending`, `issued`, or `revoked`.
12. Retroactive change of `completion_status` from `completed` to `dropped` does NOT auto-revoke issued certificates. A manual revoke via `CertificateActionRequest` is required.
13. `certificate_number` is unique across all certificates. Format: `VE-{YYYY}-{NNNNN}` (5-digit sequence per year, zero-padded). Generated from a per-year sequence table with a unique DB index on `certificate_number`. Concurrent issuance is protected by sequence atomicity.
11. System flags certificates expiring within 30 days for CRM follow-up (renewal opportunity)

## Revoke / Reissue Approval Flow

Both revoke and reissue are admin-initiated but require approval (governed by RBAC — see auth domain).

### Certificate Action Request
| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| student_certificate | Student Certificate | |
| action | enum | revoke, reissue |
| reason | string | Required |
| requested_by | User | Admin who initiated |
| approved_by | User | Nullable; Must have role `academic_leader` or `ceo` (enforced by RBAC — see Auth domain) |
| status | enum | pending, approved, rejected |
| created_at | datetime | |
| resolved_at | datetime | Nullable |

### Reissue Flow
```
Admin requests reissue
  → Approval pending
  → Approver approves
  → Original cert status → revoked
  → New Student Certificate created (reissued_from = original)
  → New cert number generated
  → New QR code generated
```

### Revoke Flow
```
Admin requests revoke
  → Approval pending
  → Approver approves
  → Certificate status → revoked
  → QR validator shows: invalid/revoked
```

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Known Listeners |
|-------|---------|-----------------|
| `certificate.issued` | `{certificate_id, student_id, enrollment_id, certificate_number}` | Notification |

### Listens (I react to these)
| Event | Source | My action |
|-------|--------|-----------|
| `enrollment.completed` | Enrollment | Auto-issue certificates where `issued_on = completion` |

## Related Domains

- [course](../course/course.md)
- [enrollment](../enrollment/enrollment.md)
- [student](../student/student.md)
- [notification](../notification/notification.md)
