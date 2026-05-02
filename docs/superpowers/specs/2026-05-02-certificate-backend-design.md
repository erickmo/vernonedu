# Certificate Backend — Design Spec (2026-05-02)

## Context

A certificate domain already exists in the API (migration `048_create_certificates.sql`, domain `internal/domain/certificate/`, commands `issue_certificate`, `revoke_certificate`, queries `get_certificate`, `list_certificates`, `verify_certificate`, HTTP handler `certificate_handler.go`, FX wired in `cmd/api/main.go`).

The existing implementation provides:
- Entity: `Certificate{ID, TemplateID, StudentID, BatchID, CourseID, Type, CertificateCode, QRCodeURL, Status, RevokedAt, RevocationReason, IssuedAt}`
- Format: `VE-{P|C}-{YEAR}-{8-RAND}` (random, not sequence)
- Routes: `POST /certificates`, `GET /certificates`, `GET /certificates/{id}`, `POST /certificates/{id}/revoke`, `GET /certificates/verify/{code}` (public)
- Events: `CertificateIssuedEvent`, `CertificateRevokedEvent`
- An `approval` domain exists with `TypeRevokeCertificate` already defined

## Goal of this iteration

Add the missing endpoints from the PRD without rewriting working code:

1. `POST /api/v1/certificates/participant` — sugar wrapper that forces `type=participant`
2. `POST /api/v1/certificates/competency` — sugar wrapper that forces `type=competency`, requires `test_passed=true`
3. `GET /api/v1/students/{id}/certificates` — list certs by student
4. `GET /api/v1/batches/{id}/certificates` — list certs by batch
5. `GET /api/v1/public/certificates/verify/{code}` — public alias under `/public/` namespace
6. PII-safe response on the public verify path (only name, course, batch, issued_at, status)

## Non-goals (deferred)

- Migration changes (existing schema satisfies functional needs; cert_number sequence redesign is a follow-up because it would invalidate existing rows)
- Approval-chain wiring for revoke (the `approval` domain already has `TypeRevokeCertificate`; integrating requires user-id from auth context which is out-of-scope for this slice — current revoke is direct write, the chain wiring is tracked as TODO)
- Separate `qr_token` column distinct from `certificate_code` (current code already serves as the verification token; UUIDv4 split is a follow-up migration)

## API contracts

### POST /api/v1/certificates/participant
```json
Request:  { "templateId": "uuid", "studentId": "uuid", "batchId": "uuid", "courseId": "uuid", "verificationBaseUrl": "https://..." }
Response: 201 { "message": "certificate issued successfully" }
```

### POST /api/v1/certificates/competency
```json
Request:  { "templateId": "uuid", "studentId": "uuid", "batchId": "uuid?", "courseId": "uuid", "testPassed": true, "verificationBaseUrl": "https://..." }
Response: 201 { "message": "certificate issued successfully" }
Errors:   400 if testPassed != true
```

### GET /api/v1/students/{id}/certificates
Returns: ListResult identical shape to `GET /certificates?student_id={id}`

### GET /api/v1/batches/{id}/certificates
Returns: ListResult identical shape to `GET /certificates?batch_id={id}`

### GET /api/v1/public/certificates/verify/{code}
Public, no auth. PII-safe: returns only `{certificate_code, type, issued_at, status, is_valid, is_revoked}` — no student/batch/course UUIDs leaked beyond what's needed for human-readable display. (Detailed enriched payload with student name + course title requires a join; out-of-scope for this slice. Current response uses existing `VerifyResult` minus IDs.)

## Constraints

- SOLID: thin handlers, no business logic
- ≤40 LOC per func, ≤300 LOC per file
- DI via FX
- No magic strings — constants
- New code only; do not modify existing handlers' behavior
