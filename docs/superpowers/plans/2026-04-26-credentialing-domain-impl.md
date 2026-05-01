# Credentialing Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Bring `backend/domains/credentialing` to full alignment with `docs/domains/certificate/spec.md`.

**Architecture:** Single `credentialing` package owns CertificateType, CertificateConfig, StudentCertificate, CertificateActionRequest. Per-year sequence table for unique `VE-{YYYY}-{NNNNN}` numbers. Listens `enrollment.completed`. Emits `certificate.issued`.

**Tech Stack:** Go 1.22, chi, pgx, sqlc, fx.

---

## Source-of-truth

- `docs/domains/certificate/spec.md`
- `backend/migrations/000005_init_credentialing.up.sql`
- `backend/sqlc/credentialing.sql`

## File Structure

| File | Responsibility |
|---|---|
| `backend/domains/credentialing/model.go` | CertCategory, CertStatus, CertAction enums + DTOs |
| `backend/domains/credentialing/repository.go` | CRUD + per-year sequence increment |
| `backend/domains/credentialing/service.go` | Issue, Verify, RequestAction, ApproveAction, Reissue, Revoke |
| `backend/domains/credentialing/handler.go` | HTTP including public verify endpoint |
| `backend/domains/credentialing/events.go` | Listeners + publishers |
| `backend/domains/credentialing/module.go` | fx wiring |

---

## Task 1: Audit gaps

- [ ] List existing types/methods. Write `GAPS.md`. Commit.

---

## Task 2: Per-year certificate-number sequence

**Files:**
- Create migration: `backend/migrations/000009_cert_number_seq.up.sql` (if missing)
- Modify: `repository.go`
- Create: `repository_certnum_test.go`

- [ ] **Step 1: Migration**

```sql
CREATE TABLE IF NOT EXISTS certificate_number_sequences (
  year INTEGER PRIMARY KEY,
  last_value INTEGER NOT NULL DEFAULT 0
);
```

Down:

```sql
DROP TABLE certificate_number_sequences;
```

- [ ] **Step 2: Failing test**

```go
func TestNextCertificateNumber_PerYearAndZeroPadded(t *testing.T) {
	// In a tx, call NextCertificateNumber(ctx, 2026) three times
	// Expect: VE-2026-00001, VE-2026-00002, VE-2026-00003
	// Then call NextCertificateNumber(ctx, 2027) → VE-2027-00001
}

func TestNextCertificateNumber_ConcurrentSafe(t *testing.T) {
	// 10 goroutines fetch numbers; expect 10 distinct values, no gaps below max
}
```

- [ ] **Step 3: FAIL**

- [ ] **Step 4: Implement** with `INSERT ... ON CONFLICT (year) DO UPDATE SET last_value = last_value + 1 RETURNING last_value`:

```sql
-- name: NextCertificateNumber :one
INSERT INTO certificate_number_sequences (year, last_value) VALUES ($1, 1)
ON CONFLICT (year) DO UPDATE SET last_value = certificate_number_sequences.last_value + 1
RETURNING last_value;
```

```go
func (r *Repo) NextCertificateNumber(ctx context.Context, year int) (string, error) {
	v, err := r.q.NextCertificateNumber(ctx, year)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("VE-%d-%05d", year, v), nil
}
```

- [ ] **Step 5: PASS**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(credentialing): per-year certificate number sequence"
```

---

## Task 3: IssueCertificate

**Files:**
- Modify: `service.go`
- Create: `service_issue_test.go`

- [ ] **Step 1: Failing tests**

- IssueCertificate creates StudentCertificate(status=issued)
- certificate_number unique (DB-enforced)
- expires_at = issued_at + cert_type.validity_months; null if validity null
- Fires `certificate.issued`
- qr_code_url points to `/cert/verify/{number}`
- One StudentCertificate per (enrollment, certificate_config) — duplicate rejected

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement IssueCertificate** within repo transaction:
  1. Take next sequence number
  2. INSERT student_certificate with derived expires_at
  3. Publish event

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(credentialing): issue certificate with unique number and event"
```

---

## Task 4: Listener for enrollment.completed

**Files:**
- Modify: `events.go`
- Create: `events_test.go`

- [ ] **Step 1: Failing test**

```go
func TestOnEnrollmentCompleted_AutoIssuesCompletionConfigs(t *testing.T) {
	// Course with 2 CertificateConfigs: one issued_on=completion, one issued_on=manual
	// Fire enrollment.completed
	// Expect: 1 StudentCertificate created (only the completion one)
}
```

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** listener — only issue configs where `issued_on=completion`.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(credentialing): auto-issue on enrollment.completed"
```

---

## Task 5: Public verify endpoint

**Files:**
- Modify: `handler.go` (likely already has VerifyCertificate)
- Create: `handler_verify_test.go`

- [ ] **Step 1: Failing tests**

- GET `/cert/verify/{number}` no auth required
- Response includes student name, course name, certificate type, partner name (if any), issued_at, status
- expires_at < today → response shows status="expired" (derived, not persisted)
- revoked → status="revoked"
- Unknown number → 404

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** — VerifyCertificate query joins enrollment → student → course → cert_type. Apply `expired` derivation in service.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(credentialing): public verify with derived expired status"
```

---

## Task 6: Revoke / Reissue approval flow

**Files:**
- Modify: `service.go` (likely has stubs)
- Create: `service_action_test.go`

- [ ] **Step 1: Failing tests**

- RequestAction(revoke) by admin → CertificateActionRequest(status=pending)
- ApproveActionRequest(revoke) by academic_leader/ceo → cert.status=revoked, sets revoked_at, revoked_by
- ApproveActionRequest(revoke) by admin → 403 (handler-layer, but service trusts caller)
- ApproveActionRequest(reissue) → original cert revoked + new cert issued with new number, reissued_from set
- Reject → request status=rejected; cert unchanged

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** — single transaction for reissue (revoke old + issue new).

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(credentialing): revoke/reissue approval flow"
```

---

## Task 7: Download gate (profile completion)

**Files:**
- Modify: `service.go`, `handler.go`
- Create: `handler_download_test.go`

- [ ] **Step 1: Failing tests**

- GET `/students/me/certificates/{id}/download` returns 403 if `profile_complete=false`
- 200 with PDF stream if `profile_complete=true`

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** — service queries `student_profile.profile_complete`. PDF generation can be a stub returning a placeholder for now (note in comment).

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(credentialing): download gated by profile completion"
```

---

## Task 8: Expiry-flag worker (CRM follow-up)

**Files:**
- Modify: `service.go`, `cmd/worker/main.go`

- [ ] **Step 1: Failing test**

- FlagExpiringCertificates(30) returns count of certs `expires_at` between today and today+30 days, status=issued

(For now, "flag" = log/return list. Future integration with CRM is out of scope.)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(credentialing): expiring-certificate flag worker"
```

---

## Task 9: CertificateType + CertificateConfig CRUD

**Files:**
- Modify: `service.go`, `handler.go`

- [ ] **Step 1: Failing tests**

- CreateCertificateType (vernonedu_admin only)
- DeactivateCertificateType — existing certs unaffected
- AddCertificateConfig to course — links cert_type
- ListCertificateConfigs by course

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(credentialing): certificate type and config CRUD"
```

---

## Task 10: Wire HTTP routes

**Files:**
- Modify: `handler.go`, `module.go`

- [ ] **Step 1: Mount routes**

```
GET    /cert/verify/{number}                        [public]
GET    /enrollments/{id}/certificates               [admin, student(own)]
GET    /students/me/certificates                    [student]
GET    /students/me/certificates/{id}/download      [student(own), profile_complete]
POST   /certificates/{id}/actions                   [admin]  # request revoke/reissue
POST   /certificate-actions/{id}/approve            [academic_leader, ceo]
POST   /certificate-actions/{id}/reject             [academic_leader, ceo]
POST   /certificate-types                           [vernonedu_admin]
POST   /courses/{id}/certificate-configs            [course_creator(own), admin]
```

- [ ] **Step 2: Implement handlers**

- [ ] **Step 3: Smoke test**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(credentialing): mount HTTP routes"
```

---

## Task 11: Verify + lint

- [ ] `cd backend && go test -race ./domains/credentialing/...`
- [ ] `cd backend && golangci-lint run ./domains/credentialing/...`
- [ ] Remove `GAPS.md`. Commit.

---

## Verification

1. Create CertificateType with validity_months=12; CertificateConfig issued_on=completion
2. Trigger enrollment.completed → expect StudentCertificate issued, number `VE-2026-00001`, expires_at one year out, `certificate.issued` event fired
3. GET `/cert/verify/VE-2026-00001` → 200 with full data
4. Request revoke → approve as academic_leader → expect status=revoked, validator now shows revoked
5. Request reissue → approve → expect old revoked, new cert with new number
6. Time-travel expires_at to past → validator shows "expired" (derived)
