# Frontend Catch-up — Accounting + Certificate + Curriculum Approval

**Date:** 2026-05-03
**Scope:** S3 (Full)
**Apps touched:** `app-dashboard` (Flutter Web), `app-website` (Flutter Web)

---

## Goal

Wire three recently-shipped backends into the frontend so staff and public users can actually use them:

1. **Accounting** — bank/cash transactions, COA tree, invoices, financial analysis
2. **Certificate** — issue (participant/competency), per-student/batch lists, template editor with A4 preview, public PII-safe verification
3. **Curriculum version approval** — approve action + pending queue (dept_leader)

All three executed in one spec, sequential delivery. Each backend = its own iteration.

---

## Context

Backend shipped (last 3 PRs):
- `feat(accounting): add COA tree + bank/cash transactions backend` (e02f7d97)
- `feat(curriculum): add course version approval workflow`
- `feat(certificate): add participant/competency issue + per-student/batch list + public PII-safe verify`

Frontend skeletons already exist:
- `app-dashboard/lib/features/accounting/` — entities, models, repo, cubit, basic pages (transaction list/form, COA list, journal). Missing: bank accounts, COA tree, invoice detail, analysis dashboard, balance.
- `app-dashboard/lib/features/certificate/` — entities, models, repo, cubit, basic page. Missing: dedicated participant/competency issue forms, student/batch list tabs, template editor with A4 preview.
- `app-dashboard/lib/features/course_version/` — version page + module page. Missing: approve action, pending approval queue.
- `app-website/lib/features/sertifikat/sertifikat_page.dart` — existing public verify page. Needs swap to PII-safe public alias endpoint.

---

## Endpoint Inventory (target wiring)

### Accounting
- `GET /api/v1/accounting/coa/tree` — hierarchical COA
- `GET/POST /api/v1/accounting/bank-accounts`
- `GET/PUT/DELETE /api/v1/accounting/bank-accounts/{id}`
- `PUT/DELETE /api/v1/accounting/transactions/{id}`
- `GET /api/v1/accounting/balance` (per account)
- `GET /api/v1/finance/invoices/{id}` — detail
- `PUT /api/v1/finance/invoices/{id}/pay|cancel|send`
- `GET /api/v1/finance/invoices/stats`
- `GET /api/v1/finance/analysis/{ratios|revenue|costs|batch-profit|cash-forecast|alerts|suggestions}`

### Certificate
- `POST /api/v1/certificates/participant`
- `POST /api/v1/certificates/competency`
- `GET /api/v1/students/{id}/certificates`
- `GET /api/v1/batches/{id}/certificates`
- `POST /api/v1/certificates/{id}/revoke`
- `POST/GET/PUT /api/v1/certificate-templates`
- `GET /api/v1/public/certificates/verify/{code}` — PII-safe alias

### Curriculum Approval
- `POST /api/v1/curriculum/versions/{versionID}/approve` — dept_leader only

---

## Architecture

Stack untouched: Flutter + BLoC/Cubit + clean architecture (data/domain/presentation), `Dio` client, `dartz` `Either<Failure, T>`, `get_it` DI. Follow patterns from existing course_version + accounting features.

**Layer rules (no exception):**
- Datasource: HTTP only, returns models.
- Repository impl: maps model → entity, wraps in `Either`, handles errors.
- Usecase: 1 file = 1 action. No business logic in cubit.
- Cubit: dispatches usecase, emits state. <40 lines per method.
- Page: presentation only, <300 lines.

**Role-gated UI:** Use existing `AuthContext`/`UserRole` guard. Curriculum approve button visible only to `dept_leader`. Analysis dashboard visible to `accounting_leader`/`accounting_staff`/`director`.

---

## Iteration 1 — Accounting Frontend

### New files (app-dashboard)

**Domain entities:**
- `bank_account_entity.dart` — id, branchId, name, bankName, accountNumber, openingBalance, isActive
- `coa_tree_node_entity.dart` — code, name, type, balance, children[]
- `account_balance_entity.dart` — accountCode, balance, asOf
- `invoice_detail_entity.dart` — extends invoice + line items, paid/cancel/send timestamps
- `invoice_stats_entity.dart` — totals by status
- `financial_ratios_entity.dart`, `revenue_analysis_entity.dart`, `cost_analysis_entity.dart`, `batch_profit_entity.dart`, `cash_forecast_entity.dart`, `alert_entity.dart`, `suggestion_entity.dart`

**Models:** matching JSON serializers per entity.

**Usecases:** one per endpoint above (12 total).

**Cubits:**
- `bank_account_cubit.dart` (list/create/update/delete)
- `coa_tree_cubit.dart` (load tree)
- `invoice_detail_cubit.dart` (load/pay/cancel/send)
- `analysis_cubit.dart` (load all 7 analysis endpoints in parallel)

**Pages:**
- `bank_accounts_page.dart` — list + create/edit dialog + soft-delete
- `coa_tree_page.dart` — collapsible tree, balance inline
- `invoice_detail_page.dart` — header + line items + actions (pay/cancel/send buttons, role-gated)
- `analysis_dashboard_page.dart` — grid of cards (ratios, revenue, costs, batch-profit, cash-forecast) + alerts/suggestions feed
- Update `transaction_page.dart` — add edit + delete row actions
- Update `accounting_page.dart` — add tabs/sub-routes for new pages

**Routes (go_router):**
- `/admin/accounting/bank-accounts`
- `/admin/accounting/coa-tree`
- `/admin/accounting/invoices/:id`
- `/admin/accounting/analysis`

### Acceptance
- Create bank account, list it, edit name, soft-delete
- Open COA tree, expand parent, see child balances
- Open invoice detail, mark paid → status changes
- Open analysis dashboard, see all 7 cards populated
- Edit + delete a transaction from list

---

## Iteration 2 — Certificate Frontend

### New files (app-dashboard)

**Domain entities:** `certificate_entity` (extend if needed for issued_at, qr_url, code, type, status).

**Usecases:**
- `issue_participant_certificate_usecase.dart`
- `issue_competency_certificate_usecase.dart`
- `list_certificates_by_student_usecase.dart`
- `list_certificates_by_batch_usecase.dart`
- `update_certificate_template_usecase.dart`

**Cubits:**
- `certificate_issue_cubit.dart` — switch participant/competency mode
- `student_certificates_cubit.dart`
- `batch_certificates_cubit.dart`
- `certificate_template_cubit.dart`

**Pages:**
- `issue_participant_page.dart` — select batch → multi-select students → bulk issue
- `issue_competency_page.dart` — select student + course + test result → issue (open to non-enrolled, criteria check inline)
- `student_certificates_tab.dart` — embedded inside student detail page
- `batch_certificates_tab.dart` — embedded inside batch detail page
- `certificate_template_editor_page.dart` — A4 preview live-rendered via Flutter `AspectRatio(1/√2)` with `CustomPaint` overlay; fields: title, body text, signature blocks, logo upload, font family/size, QR position
- `certificate_revoke_dialog.dart` — reason input, approval chain note (dept_leader → education_leader → director)

**Routes:**
- `/admin/certificates/issue/participant`
- `/admin/certificates/issue/competency`
- `/admin/certificate-templates`
- `/admin/certificate-templates/:id/edit`
- Embed tabs on existing `/admin/students/:id` and `/admin/batches/:id`

### A4 preview spec
- 595×842 logical px (A4 @ 72dpi) scaled to fit container, `BoxFit.contain`
- Background: white + optional uploaded image
- Fields rendered as positioned `Text` widgets via percentage offsets stored in template config
- Live-update on field change (no save needed for preview)
- Export preview as PNG via `RepaintBoundary` (optional, nice-to-have)

### Acceptance
- Issue participant cert for batch (10 students bulk) → 10 certs created
- Issue competency cert for non-enrolled student passing criteria
- View student detail → see all their certs (participant + competency)
- View batch detail → see all certs issued for that batch
- Open template editor, change title font, see A4 preview update live
- Revoke a cert with reason → status flips revoked

---

## Iteration 3 — Public Verify (app-website)

### Updates
- Update `app-website/lib/core/services/public_certificate_service.dart` to call `/api/v1/public/certificates/verify/{code}` (PII-safe alias) instead of admin endpoint.
- Update `app-website/lib/features/sertifikat/sertifikat_page.dart`:
  - Input: certificate code (with QR scan optional via `mobile_scanner` if package available, else paste only)
  - Output card: student first name + last initial, course name, batch dates, issuer, valid/revoked badge, QR
  - Hide: full name, email, phone, address (PII)
  - Print/share button (browser native)
- Add `public_certificate_verification_entity.dart` (PII-safe shape).

### Acceptance
- Open `/sertifikat?code=XXX` (or paste code) → verification card renders
- Revoked cert shows red banner with revocation date + reason (if non-PII)
- Invalid code shows clean error state
- No PII fields in network response (verified via DevTools)

---

## Iteration 4 — Curriculum Approval

### Files (app-dashboard)

**Usecase:** `approve_course_version_usecase.dart` — POST `/api/v1/curriculum/versions/{id}/approve`

**Cubit additions:**
- Add `approveVersion(versionId, decision, reason)` to existing `course_version_cubit.dart`
- New `pending_approvals_cubit.dart` — list versions in `pending_approval` status

**Pages:**
- Add "Setujui" button on `course_version_page.dart` detail view, role-gated to `dept_leader`, only visible when status = `pending_approval`. Reuse existing `ApprovalWizard` component (3-step modal: review → decision → confirm). Wizard already shipped per recent PR.
- New `pending_approvals_page.dart` — list of all versions awaiting dept_leader approval, click row → opens version detail with wizard primed.

**Routes:**
- `/admin/curriculum/approvals` — pending queue (dept_leader sidebar entry)

### Acceptance
- Dept leader sees pending queue with 1+ items
- Click row → version detail opens
- Click approve → wizard runs → on confirm, version status flips to `approved`
- Non-dept-leader users do not see button or queue route

---

## Cross-cutting

**Testing:**
- Cubit: state transitions (initial → loading → loaded/error) — unit
- Usecase: success + failure path — unit
- Page: golden test for analysis dashboard + A4 preview + verify card — widget
- Target: ≥80% line coverage for new code, 100% for usecases

**Error handling:**
- Use existing `Failure` types (`ServerFailure`, `NetworkFailure`, `ValidationFailure`)
- Show `SnackBar` for transient errors, full-page error state for load failures

**Design uniformity:**
- Reuse `AppColors`, `AppDimensions`, `AppStrings` (per CLAUDE.md rule 6)
- Match existing accounting/certificate page style (cards, padding, headers)

**Routing:**
- All admin routes role-gated via existing layout guard
- Sidebar: add new entries under existing Accounting / Certificate / Curriculum sections

**Out of scope:**
- Mobile apps (app-mentors, app-student) — separate spec
- WhatsApp/Email cert delivery channels
- Backend changes (all endpoints already shipped)
- Notification Center integration (spec covers UI only, notifications come via existing channel)

---

## Delivery Order

1. Iteration 1 (Accounting) — biggest, most users
2. Iteration 2 (Certificate dashboard)
3. Iteration 3 (Public verify website)
4. Iteration 4 (Curriculum approval) — smallest, plug into existing wizard

Each iteration = own branch, own PR, own merge. No big-bang.

---

## Risks

- **A4 preview accuracy:** Flutter rendering ≠ print. Mitigate by showing pixel ruler + warning "preview only — print final via PDF export" (PDF export deferred).
- **Bulk participant issue:** N students × DB writes. Backend already handles batch endpoint? If not, frontend issues N parallel requests with throttle of 5. Verify backend behavior before iter 2.
- **Public verify caching:** Browser may cache 404s. Set `Cache-Control: no-store` headers on backend (already?). Verify in iter 3.
- **Role gating drift:** Centralize role check in `AuthContext.hasRole(role)` helper — no inline string checks.
