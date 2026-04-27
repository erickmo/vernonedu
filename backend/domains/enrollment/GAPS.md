# Enrollment Domain — Gap Audit vs Spec

Source-of-truth: `docs/domains/enrollment/spec.md`, `docs/domains/voucher/spec.md`,
`backend/migrations/000003_init_enrollment.up.sql`, `backend/sqlc/enrollment.sql`.

Status legend: PRESENT / PARTIAL / MISSING. File:line where applicable.

---

## 1. Entities / Types

- [x] Enrollment struct — PRESENT (model.go:51-70)
- [x] Voucher struct — PRESENT (model.go:72-88)
- [x] VoucherUsage struct — PRESENT (model.go:90-98)
- [x] EnrollmentFormat enum (regular/private/inhouse_training/inschool_program) — PRESENT (model.go:10-17)
- [x] EnrollmentMode enum (online/offline) — PRESENT (model.go:19-24)
- [x] PaymentStatus enum (pending/partial/paid/overdue) — PRESENT (model.go:26-33)
- [x] CompletionStatus enum (ongoing/completed/dropped) — PRESENT (model.go:35-41)
- [x] DiscountType enum (fixed_amount/percentage/fixed_final_price) — PRESENT (model.go:43-49)
- [ ] PayerType enum constants (PayerStudent / PayerPartner) — MISSING; spec defines payer enum but `Enrollment.Payer` is plain `string` (model.go:57). Need typed enum.
- [ ] EnrollmentSource enum constants (SourceB2B / SourceB2C) — MISSING; `Enrollment.Source` is plain `string` (model.go:67). Need typed enum.

## 2. Service Methods

- [x] Enroll — PARTIAL (service.go:41-111)
  - Missing pricing resolution (no batch lookup; Price is taken from input/handler — should be resolved server-side via catalog)
  - Missing partnership-agreement bulk-price logic for B2B
  - Missing payer derivation from agreement (B2B partner vs B2B student)
  - Missing batch.web_registration_open / registration_open_at-close_at validation
  - Missing CourseFormatConfig (format+mode) match validation
  - Missing max_students cap check via CountEnrollmentsByBatch
  - Missing voucher eligibility filters: assigned_to / course / course_batch scoping; valid_from check; one-voucher-per-enrollment is implicit but no explicit guard
  - Missing credit application path
  - Missing event payload mapping to canonical `events.EnrollmentConfirmedPayload` (uses local struct — see Section 5)
  - Voucher consumption is not atomic with FOR UPDATE (race window)
- [ ] ApplyCredit — MISSING; spec: B2C/B2B `credit_applied` reduces payment amount (not final_price). No method, no finance.StudentCredit linkage.
- [x] CompleteEnrollment — PRESENT (service.go:114-124); but force-sets payment_status=paid which is incorrect (spec rule 9: certificate only on completed; payment is independent).
- [x] DropEnrollment — PRESENT (service.go:127-145)
- [ ] ConsumeVoucher (atomic, FOR UPDATE) — MISSING; current `IncrementVoucherUsage` is a non-atomic UPDATE; no row lock; max_uses race possible.
- [ ] CreateVoucher (admin) — MISSING in service (only repo.CreateVoucher exists, not exposed via service)
- [ ] AssignVoucher (admin) — MISSING
- [ ] ValidateVoucherCode (student-facing dry-run preview) — MISSING; needed for B2C checkout UX before commit.
- [ ] GetEnrollment — PRESENT (service.go:148-150)
- [ ] ListByStudent — PRESENT (service.go:153-155)
- [ ] ListByBatch — MISSING in service (repo has it, not exposed)

## 3. Repository Methods

- [x] CreateEnrollment — PRESENT (repository.go:39-55)
- [x] GetEnrollmentByID — PRESENT (repository.go:57-78)
- [x] GetEnrollmentByStudentAndBatch — PRESENT (repository.go:80-101)
- [x] UpdateEnrollmentStatus — PRESENT (repository.go:103-113)
- [x] ListEnrollmentsByStudent — PRESENT (repository.go:115-142)
- [x] ListEnrollmentsByBatch — PRESENT (repository.go:144-171)
- [x] GetVoucherByCode — PRESENT (repository.go:173-192)
- [x] CreateVoucher — PRESENT (repository.go:194-210)
- [x] CreateVoucherUsage — PRESENT (repository.go:224-237)
- [x] IncrementVoucherUsage — PRESENT but NON-ATOMIC (repository.go:212-222) — must be replaced or wrapped
- [ ] ConsumeVoucherTx (atomic: BEGIN; SELECT ... FOR UPDATE; check max_uses; UPDATE used_count; INSERT voucher_usages; COMMIT) — MISSING. Must run inside a single tx with row lock to honor voucher spec rule 6 + rule 12 (UNIQUE(enrollment_id) on voucher_usages already enforces idempotency at DB level; race protection still needed at app level for max_uses).
- [ ] GetVoucherByID (for admin lookup / assignment) — MISSING
- [ ] ListVouchersAssignedTo(studentID) (student dashboard) — MISSING (voucher spec rule 11)
- [ ] AssignVoucher(voucherID, studentID) — MISSING
- [ ] UpdateEnrollmentCreditApplied — MISSING
- [ ] sqlc mismatch — `backend/sqlc/enrollment.sql` only covers 6 queries; not used by hand-written repo. Either keep hand-written (current state) or align — flag for decision but not blocker.

## 4. Handler Routes

- [x] POST /api/v1/enrollments — PRESENT (handler.go:24, module.go:27)
- [x] GET /api/v1/enrollments/{id} — PRESENT (handler.go:82, module.go:28)
- [x] POST /api/v1/enrollments/{id}/drop — PRESENT (handler.go:99, module.go:29)
- [x] POST /api/v1/enrollments/{id}/complete — PRESENT (handler.go:114, module.go:30)
- [x] GET /api/v1/students/{studentID}/enrollments — PRESENT (handler.go:129, module.go:31)
- [ ] GET /api/v1/batches/{batchID}/enrollments — MISSING
- [ ] POST /api/v1/vouchers (admin create) — MISSING
- [ ] POST /api/v1/vouchers/{id}/assign (admin assign-to-student) — MISSING
- [ ] POST /api/v1/vouchers/validate (student dry-run validate code at checkout) — MISSING
- [ ] GET /api/v1/students/{studentID}/vouchers (assigned vouchers — spec rule 11) — MISSING
- [ ] CreateEnrollment handler accepts `Price` from client request (handler.go:37, 56) — SECURITY GAP. Price must be resolved server-side from catalog/agreement, not client-supplied.

## 5. Events

- [x] enrollment.confirmed event publish — PRESENT (service.go:105-108)
- [x] enrollment.completed event publish — PRESENT (service.go:119-122)
- [x] enrollment.dropped event publish — PRESENT (service.go:140-143)
- [ ] **Payload shape mismatch** — service.go:107 publishes local `enrollment.EnrollmentConfirmedPayload` (events.go:10-15) which has fields `EnrollmentID/StudentID/BatchID`. Canonical `events.EnrollmentConfirmedPayload` (internal/events/payloads.go:14-19) requires `EnrollmentID/StudentID/BatchID/CourseTitle`. Listeners (notification, finance, etc.) type-assert against the canonical struct and will silently drop. MUST switch to canonical type and populate `CourseTitle` via catalog.GetBatch → course title.
- [ ] Listen `enrollment.confirmed` to mark voucher used — MISSING (voucher spec lines 109-112). events.go:28-32 only stubs `PaymentConfirmed` no-op. Need a subscriber that, on own confirmed event with voucher_id != nil, invokes ConsumeVoucher. (Currently consumption is inline in Enroll — spec model says listen-and-consume; pick one and document.)
- [ ] No payload struct enrichment for completed/dropped events vs canonical (canonical does not yet define them; either add to internal/events/payloads.go or keep local — flag for plan decision).

## 6. Cross-Domain Dependencies (interfaces needed by Service)

- [ ] CatalogReader interface — MISSING. Needs:
  - GetBatch(batchID) — PRESENT in catalog (service.go:285), needs interface extraction
  - GetFormatConfig(courseID, format) — PARTIAL; catalog has ListFormatConfigsByCourse (repo) but no scoped lookup. May need new `GetFormatConfig(courseID, format)` or service helper.
  - CountEnrollmentsByBatch(batchID) — PRESENT in catalog repo (used internally); needs to be reachable from enrollment via interface (note: enrollment counts live in enrollment schema, but catalog already uses this — must clarify ownership; likely enrollment should expose its own count and inject INTO catalog, not reverse).
- [ ] PartnershipsReader interface — MISSING. Needs:
  - GetActiveAgreement(partnerID, courseID?) returning Payer + BulkPrice — MISSING entirely in partnerships service (no GetActiveAgreement, no Payer field in agreement model surfaced). Must be added in partnerships domain first OR exposed via interface here.
- [ ] FinanceReader interface — MISSING. Needs:
  - GetStudentCredit(studentCreditID) — MISSING; finance has no StudentCredit type/repo at all. Out of scope for this plan? Flag.
- [ ] All three must be injected into `enrollment.NewService` (currently only `repo, bus, log`).

## 7. Migration / Schema

- [x] enrollment.vouchers table — PRESENT (migration:27-50)
- [x] enrollment.enrollments table — PRESENT (migration:52-77)
- [x] enrollment.voucher_usages table — PRESENT (migration:79-88)
- [x] voucher_usages.enrollment_id UNIQUE — PRESENT (migration:82) — satisfies voucher spec rule 12
- [x] vouchers.used_count column with default 0 — PRESENT (migration:38)
- [x] chk_voucher_used_max constraint — PRESENT (migration:43)
- [x] chk_voucher_pct_range (0..100) — PRESENT (migration:44-46)
- [x] enrollments unique (student_id, course_batch_id) — PRESENT (migration:71)
- [x] Enums: enrollment_format, enrollment_mode, payer_type, payment_status, completion_status, enrollment_source, discount_type — ALL PRESENT (migration:7-15)
- [ ] No FK from enrollments.partner_id → partnerships.partners — soft link only (migration:59). Confirm intentional (cross-schema decoupling). Flag.
- [ ] No FK from enrollments.franchisee_id → partnerships.franchisees — soft link (migration:60). Same flag.
- [ ] No FK from enrollments.student_credit_id → finance.* — soft link (migration:65). Acceptable given finance.StudentCredit may not exist yet.
- [ ] No partial index on `enrollments(voucher_id) WHERE voucher_id IS NOT NULL` — minor perf gap.

---

## Summary of Top Gaps Driving Tasks 2-8

1. Pricing resolution + cross-domain readers (catalog/partnerships/finance) — biggest functional gap.
2. Atomic ConsumeVoucher with FOR UPDATE — correctness/race gap.
3. Canonical event payload (CourseTitle) — listener compatibility gap.
4. Admin voucher CRUD + assign + validate-code endpoints — feature gap.
5. Server-side price resolution (handler must NOT accept client price) — security gap.
6. Typed Payer/Source enum constants — code-quality gap.
7. Listener for own enrollment.confirmed → mark voucher used (per voucher spec) — design alignment.
