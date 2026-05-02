# Plan — Certificate Backend Endpoints (2026-05-02)

Branch: `feat/certificate-backend`

## Tasks

1. **Spec docs** (DONE): write spec + plan under `docs/superpowers/`.

2. **HTTP handler additions** (`api/internal/delivery/http/certificate_handler.go`):
   - Add `IssueParticipant(w, r)` — decodes body, sets type to `participant`, dispatches existing `IssueCertificateCommand`.
   - Add `IssueCompetency(w, r)` — same as above but type `competency`; requires `testPassed == true` else 400.
   - Add `ListByStudent(w, r)` — extracts `{id}` path param, dispatches `ListCertificatesQuery{StudentID: id}`.
   - Add `ListByBatch(w, r)` — extracts `{id}` path param, dispatches `ListCertificatesQuery{BatchID: id}`.
   - Add `VerifyPublic(w, r)` — wraps existing `Verify` but strips PII (omits student/batch/course IDs from response).
   - Update `RegisterCertificateRoutes` to add the four new authenticated routes.
   - Update `RegisterCertificatePublicRoutes` to add `/api/v1/public/certificates/verify/{code}`.
   - Constants: `certTypeParticipant = "participant"`, `certTypeCompetency = "competency"`.

3. **Tests** (`certificate_handler_test.go` or domain test additions):
   - Reuse domain tests already covering NewCertificate / Revoke / AlreadyRevoked.
   - Add unit test on the strip-PII transform helper.
   - Add unit test asserting competency requires testPassed.

4. **Build & test**: `cd api && go build ./... && go test ./...` — fix all failures.

5. **Commit + push + PR**.

## Risk / Notes

- Existing `RegisterCertificateRoutes` uses chi router directly; the new `/students/{id}/certificates` and `/batches/{id}/certificates` paths overlap with existing student/batch handlers' routing groups. Solution: register them at top-level (matches existing pattern in handler file). Chi handles path collisions only if same exact pattern.
- Public verify alias path is added without removing the legacy `/api/v1/certificates/verify/{code}` to preserve backward compat.
