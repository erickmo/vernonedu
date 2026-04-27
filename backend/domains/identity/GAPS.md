# Identity Domain — Gap Audit vs Spec

**Date:** 2026-04-27
**Scope:** Audits `backend/domains/identity` package against `docs/domains/auth/spec.md`, `docs/domains/student/spec.md`, `docs/domains/team-member/spec.md`. Drives Tasks 2-10. Removed at Task 11.

---

## 1. Entities / Types

### Auth
- [x] `User` — PRESENT (`model.go:55`)
- [x] `UserRole` enum — PRESENT (`model.go:10-22`); all 9 spec roles present
- [ ] `Role` (RBAC role entity / permission matrix table) — MISSING. Spec lists permission matrix per domain; no Role table or `permissions` mapping in code or migration. Currently role is just an enum on User; no policy/permission lookup model.

### Student
- [x] `Student` — PRESENT (`model.go:66`)
- [x] `StudentProfile` — PRESENT (`model.go:78`)
- [ ] Student model `Password` column — note: spec lists password on Student; in code password lives on `User.PasswordHash` only (acceptable since registration creates both). Document but no change needed.
- [ ] Student `Partner` association — PARTIAL. `PartnerID *uuid.UUID` exists (`model.go:73`) but no FK to partner schema and no resolution helper. (Cross-domain — partnerships domain.)

### TeamMember
- [x] `TeamMember` — PRESENT (`model.go:104`)
- [x] `FacilitatorProfile` — PRESENT (`model.go:118`)
- [x] `FacilitatorProposal` — PRESENT (`model.go:138`)
- [x] `FeeTier` — PRESENT (`model.go:127`)
- [x] `EmploymentStatus`, `ProposalStatus`, `FeeBasis` enums — PRESENT (`model.go:31-53`)

### Department (referenced but not in plan inventory)
- [x] `Department` — PRESENT (`model.go:94`) — out-of-scope for identity per spec note (Department lives in own domain), but currently part of identity migration. Flag for possible relocation, but do NOT change this plan.

---

## 2. Service Methods

### Auth
- [x] `Register` — PRESENT (`service.go:37`). Concern: does not differentiate between student vs team-member registration paths; team-member creation not chained.
- [x] `Login` — PRESENT (`service.go:83`). Returns user only; JWT generated in handler. OK.
- [ ] `GetCurrentUser` — PARTIAL. `GetUser(id)` exists (`service.go:101`); handler `GetMe` (`handler.go:95`) reads user-context. Rename/expose `GetCurrentUser(ctx)` to read from context for clarity (optional).
- [ ] `Logout` — MISSING. No service or handler. Stateless JWT — needs token blacklist or no-op + client discard. Spec implies endpoint exists.

### Student
- [ ] `UpdateStudentProfile` — MISSING. No service method, no repo method, no SQL. Must compute `profile_complete = true` when all required fields (date_of_birth, gender, id_type, id_number, address, city, province, postal_code) are set. Also fires `student.profile_completed` on `false → true` transition.
- [ ] `GetStudentProfile` — MISSING.
- [ ] `CreateStudentProfile` — MISSING (or fold into Update upsert).

### TeamMember
- [x] `CreateTeamMember` — PRESENT (`service.go:138`)
- [x] `UpdateTeamMemberStatus` — PRESENT (`service.go:153`)
- [ ] `DeactivateTeamMember` — MISSING as distinct method. Spec says VernonEdu Admin can deactivate. Currently only `DeactivateUser` (`service.go:106`) which acts on User row. Need TeamMember-level deactivate that also flips `employment_status='inactive'` and fires both `team_member.status_changed` and `auth.user.deactivated`.

### Facilitator Proposal
- [x] `ProposeFacilitator` — PRESENT (`service.go:178`)
- [ ] `ApproveProposalDeptLeader` — PARTIAL. Combined into generic `ReviewProposal(reviewer, status, note)` (`service.go:197`). Spec wants explicit step-1 method with sequential guard (cannot bypass).
- [ ] `ApproveProposalAcademicLeader` — PARTIAL. Same `ReviewProposal`. MISSING guard: must reject if `dept_leader_status != approved`.
- [ ] `RejectProposal` — PARTIAL. Folded into `ReviewProposal`. Need explicit method + clear `stage` payload for `facilitator.rejected` event.
- [ ] Sequential-order rule (Academic Leader cannot review until Dept Leader approves) — MISSING. Current `ReviewProposal` allows either reviewer at any time.
- [ ] `dept_leader_reviewed_at` / `academic_leader_reviewed_at` — NOT SET in service. `ReviewProposal` updates status/note but never stamps the reviewed_at timestamps.
- [ ] BatchCostLineItem auto-create on `facilitator.approved` — out-of-domain (finance) but event payload must be sufficient.

### FeeTier
- [ ] `CreateFeeTier` — MISSING. No service, repo, SQL.
- [ ] `ListFeeTiers` (active-only filter) — MISSING. No service, repo, SQL.
- [ ] `DeactivateFeeTier` — MISSING (implicit via `is_active` flag).

---

## 3. Repository Methods / sqlc Queries

### Present in `repository.go`
- [x] User: Create, GetByID, GetByEmail, Update, Deactivate
- [x] Student: Create, GetByID, GetByUserID, List
- [x] TeamMember: Create, GetByID, UpdateStatus
- [x] Department: Create, GetByID, List
- [x] FacilitatorProposal: Create, GetByID, Update

### Required but MISSING (repository.go + interface)
- [ ] `GetStudentProfileByStudentID`
- [ ] `UpsertStudentProfile` (create or update with profile_complete recompute)
- [ ] `UpdateTeamMember` (full update, not just status)
- [ ] `ListTeamMembers` (filterable by role, department, is_facilitator, employment_status)
- [ ] `CreateFacilitatorProfile`
- [ ] `GetFacilitatorProfileByTeamMemberID`
- [ ] `UpdateFacilitatorProfile`
- [ ] `CreateFeeTier`
- [ ] `ListFeeTiers(activeOnly bool)`
- [ ] `GetFeeTierByID`
- [ ] `UpdateFeeTier` / `DeactivateFeeTier`
- [ ] `ListProposalsByCourse`
- [ ] `ListProposalsByFacilitator`
- [ ] `ListPendingProposals` (by reviewer stage)

### sqlc queries (`backend/sqlc/identity.sql`) — currently only 9 queries
- [x] GetUserByEmail, GetUserByID, CreateUser, DeactivateUser
- [x] GetStudentByUserID, CreateStudent, ListStudents
- [x] GetTeamMemberByID, ListActiveFacilitatorsByDepartment
- [ ] All MISSING repo queries above need sqlc counterparts. Note: current `repository.go` uses raw `pgxpool` SQL strings (not sqlc-generated). Plan must decide: extend sqlc OR continue raw. Flag for Task 2.

---

## 4. Handler Routes

### Mounted (`module.go:21`)
- [x] `POST /api/v1/auth/register`
- [x] `POST /api/v1/auth/login`
- [x] `GET  /api/v1/auth/me` (JWT)
- [x] `GET  /api/v1/students` (JWT)
- [x] `GET  /api/v1/students/{id}` (JWT)
- [x] `DELETE /api/v1/users/{id}` (JWT) — used as user deactivate
- [x] `GET  /api/v1/departments` (JWT)

### Required by spec — NOT MOUNTED
- [ ] `POST /api/v1/auth/logout`
- [ ] `PUT  /api/v1/students/{id}/profile` (UpdateStudentProfile)
- [ ] `GET  /api/v1/students/{id}/profile`
- [ ] `POST /api/v1/team-members` (CreateTeamMember)
- [ ] `GET  /api/v1/team-members`
- [ ] `GET  /api/v1/team-members/{id}`
- [ ] `PATCH /api/v1/team-members/{id}/status` (Update status)
- [ ] `DELETE /api/v1/team-members/{id}` (Deactivate)
- [ ] `POST /api/v1/team-members/{id}/facilitator-profile`
- [ ] `POST /api/v1/facilitator-proposals` (Propose)
- [ ] `POST /api/v1/facilitator-proposals/{id}/dept-leader-approve`
- [ ] `POST /api/v1/facilitator-proposals/{id}/academic-leader-approve`
- [ ] `POST /api/v1/facilitator-proposals/{id}/reject`
- [ ] `GET  /api/v1/facilitator-proposals` (with filters)
- [ ] `POST /api/v1/fee-tiers`
- [ ] `GET  /api/v1/fee-tiers` (?active=true)
- [ ] `PATCH /api/v1/fee-tiers/{id}`

### RBAC enforcement
- [ ] No middleware enforces role checks per route — spec rule #1 says all routes RBAC-protected. Current routes only check JWT presence. MISSING: role-guard middleware.

---

## 5. Events

### Currently emitted (`events.go` + `service.go`)
- [x] `auth.user.created` — `UserCreatedPayload{user_id, email, role}` ✓ matches spec
- [x] `auth.user.deactivated` — `UserDeactivatedPayload{user_id}` ✓
- [x] `team_member.created` — `TeamMemberCreatedPayload{team_member_id, user_id}` — PARTIAL: spec wants `{team_member_id, role}`, currently emits `user_id` not `role`
- [x] `team_member.status_changed` — `TeamMemberStatusChangedPayload{team_member_id, status}` — PARTIAL: spec wants `{team_member_id, old_status, new_status}`; currently single `status`
- [x] `facilitator.proposed` — emits `FacilitatorProposedPayload{proposal_id, course_id, facilitator_id}` — PARTIAL: spec wants `{facilitator_id, course_id, proposed_by}`; missing `proposed_by`
- [x] `facilitator.approved` — reuses same payload — PARTIAL: spec wants `{facilitator_id, course_id, approved_by}`; missing `approved_by`
- [x] `facilitator.rejected` — reuses same payload — PARTIAL: spec wants `{facilitator_id, course_id, rejected_by, stage}`; missing `rejected_by` and `stage`

### Required by spec — MISSING entirely
- [ ] `student.profile_completed` — `{student_id}` — fires when `profile_complete: false → true`. No emitter, no payload type.

### Listens (consumed events)
- [x] None required by spec. `RegisterSubscriptions` (`events.go:40`) is empty no-op. OK.

---

## Summary of gap categories (drives Tasks 2-10)

1. **Models/migrations:** mostly complete; minor — student_profile fields nullable, OK.
2. **Service layer:** missing student profile flow, fee tier CRUD, explicit proposal step methods, sequential approval guard, reviewed_at stamping, team-member deactivate.
3. **Repository:** ~12 methods missing; sqlc currently underused (raw SQL pattern dominates).
4. **Handler/routes:** ~15 routes missing; no RBAC role-guard middleware.
5. **Events:** all 5 team-member/facilitator payloads need shape fixes; `student.profile_completed` missing entirely.
6. **Cross-cutting:** RBAC enforcement layer (middleware + role policy lookup) not implemented.
