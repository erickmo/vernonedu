# Design Spec: Student Enrollment & Payment (Web, B2C)

**Date:** 2026-04-25
**Status:** Approved

---

## Scope

B2C student self-enrollment via web for course batches, with full payment (gateway or bank transfer). Admin-only installment (cicilan) management. Certificate issuance with QR validator. Student certificate tracking dashboard.

Out of scope: B2B enrollment via web, student-initiated cicilan.

---

## Enrollment Flow

```
[Browse Course Batches]
        │
        ▼
[Select Format + Mode]  ← only options enabled on the course shown
        │
        ▼
[Register / Login]  ← minimal: name, email, phone, password
        │
        ▼
[Review Enrollment + Price]
        │
        └── [Choose: Gateway | Bank Transfer] → [Pay] → Enrolled (status: pending → paid)
```

### Registration
- Minimal fields at registration: name, email, phone, password
- Extended profile (address, ID number, etc.) required only before certificate download

---

## Payment Flow

### Student-facing (full payment only)
- **Gateway:** auto-confirmed via webhook → enrollment marked paid
- **Bank Transfer:** student uploads proof → admin confirms → enrollment marked paid

### Admin-only: Installment (Cicilan)
- Admin converts enrollment to installment from backoffice
- Admin sets N payment terms manually (due date + amount per term)
- Student notified per term due date
- Student pays each term via gateway or bank transfer
- Student never sees cicilan option during self-enrollment

### Payment States
| State | Meaning |
|---|---|
| pending | No payment yet |
| partial | Some terms paid (installment) |
| paid | Fully paid |
| overdue | Term past due date, unpaid |

---

## Payment Data Model

```
Enrollment
  └── Payment
        ├── payment_type: full | installment
        ├── total_amount
        ├── paid_amount (sum of confirmed transactions)
        ├── status: pending | partial | paid | overdue
        └── Payment Terms (1 for full, N for installment)
              ├── term_number
              ├── due_date
              ├── amount
              ├── status: unpaid | paid | overdue
              └── Payment Transactions
                    ├── method: gateway | bank_transfer
                    ├── amount
                    ├── status: pending | confirmed | failed
                    ├── gateway_ref (nullable)
                    ├── proof_url (nullable)
                    └── confirmed_by (nullable, admin)
```

---

## Certificate Domain

### Certificate Config (on Course)
Each course defines 1+ certificate configs:
- type: `vernonedu_competence` | `vernonedu_participation` | `partner`
- partner_name (nullable): e.g., "BNSP", "CompTIA"
- issued_on: `completion` | `manual`

### Student Certificate (issued per student per enrollment)
- Unique certificate number
- QR code → `vernonedu.id/cert/verify/{certificate_number}`
- Status: `pending` | `issued` | `revoked`
- Student tracks all certificates in dashboard

### Public Validator Page
- Accessible via QR code, no login required
- Shows: student name, course name, certificate type, issued date, status

### Certificate Download Gate
Before student can download certificate:
- Extended profile must be complete (address, ID number, etc.)

---

## Todo / Implementation Checklist

### Backend
- [ ] Student registration endpoint (minimal fields)
- [ ] Student profile completion endpoint (extended fields)
- [ ] Course batch listing API (with format/mode availability)
- [ ] Enrollment creation endpoint (B2C, validates format+mode flags)
- [ ] Payment creation (full payment, 1 term auto-created)
- [ ] Payment gateway integration (Midtrans/Xendit) + webhook handler
- [ ] Bank transfer proof upload endpoint
- [ ] Admin: confirm bank transfer endpoint
- [ ] Admin: convert enrollment to installment endpoint
- [ ] Admin: create payment terms manually
- [ ] Student payment term notification (email/WhatsApp)
- [ ] Certificate config CRUD (on course)
- [ ] Student certificate issuance (manual + auto on completion)
- [ ] QR code generation per certificate
- [ ] Public certificate validator endpoint
- [ ] Student certificate dashboard API

### Frontend (Student Web)
- [ ] Course batch browse/search page
- [ ] Batch detail page (format/mode selector)
- [ ] Simple registration form
- [ ] Login page
- [ ] Enrollment review + price page
- [ ] Payment method selector (gateway / bank transfer)
- [ ] Gateway redirect + callback page
- [ ] Bank transfer: upload proof page
- [ ] Enrollment confirmation page
- [ ] Student dashboard: enrollment history
- [ ] Student dashboard: payment status + terms
- [ ] Student dashboard: certificate list + download
- [ ] Public certificate validator page

### Admin Backoffice
- [ ] Enrollment list + detail view
- [ ] Bank transfer confirmation UI
- [ ] Convert enrollment to installment UI
- [ ] Create/edit payment terms UI
- [ ] Certificate issuance UI (manual)
- [ ] Certificate revoke UI
- [ ] Course certificate config UI

### Domain Docs
- [ ] Create payment domain (payment.md)
- [ ] Create certificate domain (certificate.md)
- [ ] Update enrollment domain
- [ ] Update student domain (registration + profile gate)
- [ ] Update course domain (certificate config)
