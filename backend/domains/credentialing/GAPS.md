# Credentialing Domain — GAPS vs Spec

Audit performed against:
- `docs/domains/certificate/spec.md`
- `backend/migrations/000005_init_credentialing.up.sql`
- `backend/sqlc/credentialing.sql`
- `backend/domains/credentialing/{model,service,repository,handler,events,module}.go`

Legend: `MISSING` | `INCOMPLETE` | `PRESENT`

---

## 1. Entities / Types (model.go)

- [x] CertificateType — PRESENT (model.go:47)
- [ ] CertificateType.badge_image_url — MISSING (model.go:47-56; not in migration:19-28 either)
- [x] CertificateConfig — PRESENT (model.go:58)
- [ ] CertificateConfig.criteria_json — MISSING (model.go:58-65; not in migration:31-39)
- [x] StudentCertificate (Certificate) — PRESENT (model.go:67)
- [x] CertificateActionRequest — PRESENT (model.go:84)
- [ ] CertificateActionRequest.reviewed_by / reviewed_at — INCOMPLETE — uses `approved_by` + `resolved_at` instead of spec naming `reviewed_by`/`reviewed_at` (model.go:90,94; migration:71,75)
- [ ] CertificateActionRequest.note — MISSING (spec calls for `note`; only `reason` exists at model.go:88)
- [ ] CertificateNumberSequence (per-year counter table) — MISSING — migration uses 3 hardcoded sequences `cert_number_seq_2025/2026/2027` (migration:7-9) instead of a `certificate_number_sequences(year PK, last_value)` table

---

## 2. Service Methods (service.go)

- [ ] IssueCertificate — INCOMPLETE — exists (service.go:27) but NOT transactional, does NOT increment per-year sequence; cert number derived from `uuid` slice (service.go:131-133) instead of `VE-{YYYY}-{NNNNN}` zero-padded format
- [x] VerifyCertificate — PRESENT (service.go:62); correctly derives expired from expires_at (service.go:70)
- [x] RequestAction — PRESENT (service.go:82)
- [x] ApproveActionRequest — PRESENT (service.go:108)
- [ ] RejectActionRequest — MISSING (service.go has no Reject method)
- [ ] ReissueCertificate — MISSING — Approve(reissue) only revokes original (service.go:124-127); does not transactionally issue new cert nor link `reissued_from`
- [ ] DownloadCertificate — MISSING — no method; spec rule 8 "download gated by student_profile.profile_complete"
- [ ] FlagExpiringCertificates (worker) — MISSING — no daily job for `expires_at < today + 30 days` (spec Background Jobs)
- [ ] CRUD CertificateType — INCOMPLETE — only Create + GetByID + ListActive exist (service.go has no wrappers; only repo); missing Update, Deactivate
- [ ] CRUD CertificateConfig — INCOMPLETE — only Create + ListByCourse via repo; no service methods, no Update/Delete
- [ ] Auto-issue on enrollment.completed — INCOMPLETE — subscription is a no-op (events.go:18-20)

---

## 3. Repository Methods (repository.go)

- [x] CreateCertificateType (repository.go:43)
- [x] GetCertificateTypeByID (repository.go:57)
- [x] ListActiveCertificateTypes (repository.go:74)
- [ ] UpdateCertificateType — MISSING
- [ ] DeactivateCertificateType — MISSING
- [x] CreateCertificateConfig (repository.go:95)
- [x] GetCertificateConfigByCourse (repository.go:109)
- [ ] UpdateCertificateConfig — MISSING
- [ ] DeleteCertificateConfig — MISSING
- [x] CreateCertificate (repository.go:130)
- [x] GetCertificateByID (repository.go:146)
- [x] GetCertificateByNumber (repository.go:166)
- [x] UpdateCertificateStatus (repository.go:186)
- [x] ListCertificatesByEnrollment (repository.go:198)
- [ ] CreateCertificateTx (transactional issue with seq increment) — MISSING
- [ ] NextCertificateNumber(year) — MISSING — no helper to read/increment per-year sequence
- [ ] ListExpiringCertificates(window) — MISSING — needed by FlagExpiringCertificates worker
- [ ] UpdateCertificateRevoke (set revoked_at, revoked_by) — MISSING — current UpdateCertificateStatus does not set revoked_at/revoked_by (repository.go:186-196)
- [ ] UpdateCertificateReissuedFrom — MISSING
- [x] CreateActionRequest (repository.go:224)
- [x] GetActionRequestByID (repository.go:240)
- [x] UpdateActionRequestStatus (repository.go:258)
- [ ] ListPendingActionRequests — MISSING in repo (sqlc has it at credentialing.sql:23 but no Go binding)

---

## 4. Handler Routes (handler.go / module.go)

- [x] GET /api/v1/certificates/verify/{number} (module.go:25)
- [x] GET /api/v1/enrollments/{enrollmentID}/certificates (module.go:30)
- [x] POST /api/v1/certificates/{id}/actions (module.go:31)
- [x] POST /api/v1/certificate-actions/{id}/approve (module.go:32)
- [ ] POST /api/v1/certificate-actions/{id}/reject — MISSING (no RejectActionRequest handler)
- [ ] GET /api/v1/certificates/{id}/download — MISSING (DownloadCertificate gated by profile_complete)
- [ ] CRUD /api/v1/certificate-types (POST/GET/PUT/DELETE) — MISSING
- [ ] CRUD /api/v1/courses/{courseID}/certificate-configs — MISSING
- [ ] GET /api/v1/students/{studentID}/certificates — MISSING (student dashboard lists own certs; spec rule 13)
- [ ] GET /api/v1/certificate-actions?status=pending — MISSING (admin queue)
- [ ] POST /api/v1/certificates/issue (manual trigger for `issued_on=manual`) — MISSING

---

## 5. Events (events.go)

- [x] Subscribes events.EnrollmentCompleted (events.go:18) — INCOMPLETE — handler is a no-op; does not call IssueCertificate
- [x] CertificateIssuedPayload defined (events.go:11)
- [ ] CertificateIssued payload missing fields — INCOMPLETE — spec requires `{certificate_id, student_id, enrollment_id, certificate_number}`; current payload only has `certificate_id, enrollment_id` (events.go:11-14)
- [ ] Publish on auto-issue path — MISSING (subscription no-op never publishes)

---

## 6. Migration Coverage (000005_init_credentialing.up.sql)

- [x] Schema + enums (migration:5-17)
- [x] certificate_types table (migration:19-28)
- [ ] certificate_types.badge_image_url — MISSING column
- [x] certificate_configs table + UNIQUE(course_id, certificate_type_id) (migration:31-41)
- [ ] certificate_configs.criteria_json — MISSING column
- [x] student_certificates table (migration:43-58)
- [x] student_certificates.certificate_number UNIQUE (migration:48)
- [ ] student_certificates UNIQUE (enrollment_id, certificate_config_id) — MISSING — spec rule 2 requires "one StudentCertificate per CertificateConfig per enrollment"
- [x] indexes on enrollment, number, status, expires_at (migration:60-63)
- [x] certificate_action_requests table (migration:65-79)
- [ ] certificate_number_sequences(year PK, last_value) table — MISSING — uses 3 hardcoded `cert_number_seq_YYYY` PostgreSQL sequences (migration:7-9) which do not extend past 2027 and are not queryable as a table

---

## 7. sqlc (credentialing.sql)

- [x] GetCertificateByNumber, ListCertificatesByEnrollment, CreateCertificate, UpdateCertificateStatus, ListActiveCertificateTypes, GetCertificateConfigsByCourse, ListPendingActionRequests
- [ ] No queries for: certificate_types CRUD, certificate_configs CRUD, action_request approve/reject, expiring-cert scan, per-year sequence increment, reissue chaining

---

## Summary of biggest gaps

1. Per-year sequence is hardcoded enumerated sequences, not a `certificate_number_sequences` table; cert number generator uses UUID slice instead of `VE-{YYYY}-{NNNNN}`.
2. No transactional IssueCertificate (sequence increment + insert in same Tx).
3. No ReissueCertificate (revoke old + new cert with `reissued_from`).
4. No RejectActionRequest path.
5. enrollment.completed subscription is a no-op — auto-issue never happens.
6. No DownloadCertificate gated by profile completion.
7. No FlagExpiringCertificates worker.
8. Missing UNIQUE(enrollment_id, certificate_config_id) on student_certificates.
9. Missing fields: badge_image_url, criteria_json, note (spec); model uses `approved_by`/`resolved_at` while spec uses `reviewed_by`/`reviewed_at`.
10. CertificateIssued event payload missing student_id and certificate_number.
11. No CRUD endpoints/handlers for CertificateType and CertificateConfig.
12. No student-facing list endpoint, no admin pending-actions queue.
