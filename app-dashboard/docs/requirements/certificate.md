# Domain: Certificate

> Certificate of Participant (auto), Certificate of Competency (test-based), template management, QR verification, and revocation.

---

## Certificate Types

| Type | Trigger | Recipient |
|------|---------|-----------|
| Certificate of Participant | Automatically issued upon course batch completion | All students who complete the batch |
| Certificate of Competency | Issued when student passes a competency test | Students who pass; test is open to non-enrolled candidates who meet criteria |

### Competency Test Eligibility
Anyone can enroll for the competency test **without joining a course batch**, provided they match the eligibility criteria set per course.

---

## Certificate Template System

- Admin/staff can create and manage certificate templates in **Settings**
- Template format: **A4**
- System auto-generates certificates from template when trigger conditions are met
- Each generated certificate contains a **QR code** → links to online verification page

---

## Online Verification (app-website)

- Public verification page on `app-website`
- Domain for verification URL is **configurable in settings**
- Scan QR or enter certificate code → shows certificate details
- If certificate is valid: displays full certificate info
- If certificate is revoked: displays certificate with watermark **"SERTIFIKAT DICABUT"**

---

## Certificate Revocation

Revocation is an approval workflow:

| Step | Actor | Action |
|------|-------|--------|
| 1 | Dept Leader | Proposes revocation with **mandatory reason** |
| 2 | Education Leader | Reviews and approves |
| 3 | Director | Final approval |

Once revoked:
- Certificate status changes to `revoked`
- Online verification page shows watermark **"SERTIFIKAT DICABUT"**
- Revocation reason is recorded in the system

---

## Routes

```
/certificates     → CertificatePage
/settings         → SettingsPage (certificate template management)
```

## Current Implementation

**Status:** ⚠️ Functional but **violates cubit pattern**
- Uses `ApiClient.dio` directly (bypasses cubit pattern)
- Uses `FutureBuilder` + `Future.wait` to load data
- Certificate issuance is local state only (no API write yet)
- Empty `data/` and `domain/` directory structures exist

### Migration Plan (v2)
- `CertificateRepository` → `IssueCertificateUseCase`, `GetCertificatesUseCase`, `RevokeCertificateUseCase`
- `CertificateCubit` with proper state management
- API: `POST /certificates`, `GET /certificates`, `POST /certificates/:id/revoke`
- Template CRUD in settings
- QR generation + verification endpoint for app-website

---

## Status

⚠️ Needs full rebuild: cubit migration, template system, QR generation, revocation workflow, competency test system.
