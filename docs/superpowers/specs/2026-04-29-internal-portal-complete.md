# Internal Portal Complete — Spec
**Date**: 2026-04-29
**Scope**: Fix 403, add all missing internal pages, role-aware navigation

---

## Problem

1. **403 for non-CEO roles** — `App.tsx` allowedRoles for `/internal` only includes `admin`, `ceo`, `manager`, `staff`, `facilitator`. Roles `finance`, `academic_leader`, `dept_leader`, `course_creator`, `vernonedu_admin` are not listed → 403 after login.
2. **Missing pages** — backend has full APIs for departments, team members, proposals, budget, profit split, calendar, vouchers, partners, franchises, notification templates — none have frontend pages.
3. **Static nav** — all internal roles see same nav items regardless of what they can access.

---

## Roles (from backend model.go)

| Role | Value |
|------|-------|
| CEO | `ceo` |
| Finance | `finance` |
| Academic Leader | `academic_leader` |
| Dept Leader | `dept_leader` |
| Course Creator | `course_creator` |
| VernonEdu Admin | `vernonedu_admin` |
| Admin | `admin` |
| Facilitator | `facilitator` |
| Student | `student` |
| Franchisee | `franchisee` |

---

## Solution: 3 Waves, Wave 2 Parallel

### Wave 1 — Foundation (single agent)

**File: `frontend/src/App.tsx:70`**
Replace allowedRoles:
```ts
allowedRoles={['ceo','admin','vernonedu_admin','finance','academic_leader','dept_leader','course_creator','facilitator']}
```

**File: `frontend/src/lib/auth/roleNav.ts`** (new)
- Export `getInternalNavItems(role: string): NavItem[]`
- Each nav item has `allowedRoles?: string[]`; if undefined = all roles see it
- Returns filtered list based on role

No other changes in Wave 1.

---

### Wave 2 — Missing Pages (5 parallel subagents)

Each subagent creates page components + API hooks only.
**None touch `App.tsx` or `InternalPortal.tsx`** — that is Wave 3.

All pages use existing design system: `bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]` card pattern, Plus Jakarta Sans font, brand-600 primary color.

#### Subagent 1 — People & Org

**Roles:** `ceo`, `admin`, `vernonedu_admin`, `dept_leader`, `academic_leader`

Pages:
- `src/portals/internal/pages/Departments.tsx`
  - List departments: `GET /api/v1/departments`
  - Create department: `POST /api/v1/departments` (service has `CreateDepartment`)
  - Table: Name, Leader, Status, Created
  - Dialog: Create form (name, leader_id)

- `src/portals/internal/pages/TeamMembers.tsx`
  - List team members: `GET /api/v1/team-members`
  - Create team member: `POST /api/v1/team-members`
  - Deactivate user: `DELETE /api/v1/users/{id}`
  - Fee tiers tab: `GET /api/v1/fee-tiers`, `POST /api/v1/fee-tiers` (vernonedu_admin only)
  - Table: Name, Role, Department, Employment Status, Facilitator badge

- `src/portals/internal/pages/Proposals.tsx`
  - List proposals: `GET /api/v1/facilitator-proposals/{id}` (per-user view)
  - Create proposal: `POST /api/v1/facilitator-proposals`
  - Dept review: `POST /api/v1/facilitator-proposals/{id}/dept-review` (dept_leader only)
  - Academic review: `POST /api/v1/facilitator-proposals/{id}/academic-review` (academic_leader only)

API hooks file: `src/lib/api/people.ts`

#### Subagent 2 — Academic Ops

**Roles:** `course_creator`, `dept_leader`, `vernonedu_admin`

Pages:
- `src/portals/internal/pages/Budget.tsx`
  - Sub-tabs: Templates | Batch Items | Realizations
  - Templates: `GET/POST /api/v1/courses/{course_id}/budget-templates`
  - Batch Items: `GET/POST /api/v1/batches/{batch_id}/budget-items`
  - Realizations: `GET/POST /api/v1/budget-items/{item_id}/realizations`

- `src/portals/internal/pages/ProfitSplit.tsx`
  - Global settings: `GET/PUT /api/v1/profit-split/settings`
  - Course overrides: `POST /api/v1/profit-split/overrides`, `GET /api/v1/profit-split/overrides/{courseID}`
  - Extra revenue: `POST /api/v1/profit-split/extra-revenue` + approve/reject
  - Period bonuses: `GET /api/v1/profit-split/period-bonuses/{period}`

API hooks file: `src/lib/api/academic.ts`

#### Subagent 3 — Business Ops

**Roles:** `ceo`, `admin`, `vernonedu_admin`

Pages:
- `src/portals/internal/pages/Partners.tsx`
  - List partners: `GET /api/v1/partners`
  - Create partner: `POST /api/v1/partners`
  - Agreements: `POST /api/v1/agreements`, `POST /api/v1/agreements/{id}/activate`

- `src/portals/internal/pages/Vouchers.tsx`
  - List vouchers: `GET /api/v1/vouchers`
  - Create voucher: `POST /api/v1/vouchers`
  - Get voucher: `GET /api/v1/vouchers/{id}`

- `src/portals/internal/pages/Calendar.tsx`
  - List events: `GET /api/v1/calendar`
  - Create event: `POST /api/v1/calendar`
  - Update/Delete event: `PUT/DELETE /api/v1/calendar/{id}`
  - Attendees: `GET/POST /api/v1/calendar/{id}/attendees`

API hooks file: `src/lib/api/businessops.ts`

#### Subagent 4 — Franchise Ops

**Roles:** `ceo`, `admin`, `vernonedu_admin`

Pages:
- `src/portals/internal/pages/Franchises.tsx`
  - List franchisees: `GET /api/v1/franchisees`
  - Create franchisee: `POST /api/v1/franchisees`
  - Agreements: `POST /api/v1/franchise-agreements`, `GET /api/v1/franchise-agreements/{franchiseeID}`
  - Royalty records: `GET /api/v1/royalty-records/{franchiseeID}/all`, `POST /api/v1/royalty-records`
  - Mark paid: `POST /api/v1/royalty-records/{id}/mark-paid`
  - Sub-tabs: Franchisees | Royalty | Agreements

API hooks: extend existing `src/lib/api/franchise.ts`

#### Subagent 5 — Platform Admin + UX Polish

**Roles:** `admin`, `vernonedu_admin`

Pages:
- `src/portals/internal/pages/Notifications.tsx`
  - List templates: `GET /api/v1/notification-templates`
  - Create/Update/Delete: `POST/PUT/DELETE /api/v1/notification-templates`

UX polish (existing pages):
- `Students.tsx` — add role badge column, improve empty state
- `Enrollments.tsx` — improve status badge colors
- `Payments.tsx` — improve amount formatting with DM Mono font
- `Courses.tsx` — improve batch count display

API hooks file: `src/lib/api/platform-admin.ts`

---

### Wave 3 — Wiring (single agent, after Wave 2 complete)

**`App.tsx`** — add all new routes under `/internal`:
```
departments, team-members, proposals
budget, profit-split
partners, vouchers, calendar
franchises, notifications
```

**`InternalPortal.tsx`** — replace static `NAV_ITEMS` with `getInternalNavItems(user.role)`:

| Nav Item | Label | Path | Allowed Roles |
|---|---|---|---|
| Dashboard | Dashboard | /internal | all |
| Enrollments | Enrollments | /internal/enrollments | all |
| Payments | Payments | /internal/payments | ceo, admin, vernonedu_admin, finance |
| Courses | Courses | /internal/courses | all |
| Students | Students | /internal/students | ceo, admin, vernonedu_admin |
| Departments | Departments | /internal/departments | ceo, admin, vernonedu_admin, dept_leader, academic_leader |
| Team Members | Team Members | /internal/team-members | ceo, admin, vernonedu_admin, dept_leader, academic_leader |
| Proposals | Proposals | /internal/proposals | all except student/franchisee |
| Budget | Budget | /internal/budget | course_creator, dept_leader, vernonedu_admin |
| Profit Split | Profit Split | /internal/profit-split | ceo, vernonedu_admin, course_creator |
| Partners | Partners | /internal/partners | ceo, admin, vernonedu_admin |
| Vouchers | Vouchers | /internal/vouchers | ceo, admin, vernonedu_admin |
| Calendar | Calendar | /internal/calendar | all |
| Franchises | Franchises | /internal/franchises | ceo, admin, vernonedu_admin |
| Notifications | Notifications | /internal/notifications | admin, vernonedu_admin |

---

## API Hooks Convention

All new hooks follow existing pattern in `src/lib/api/`:
- Use `useSWR` for reads
- Use `fetch` + `mutate` for writes
- Auth token from `useAuth().token`

---

## File Map Summary

| Wave | File | Action |
|------|------|--------|
| 1 | `src/App.tsx` | Fix allowedRoles |
| 1 | `src/lib/auth/roleNav.ts` | New — role-filtered nav util |
| 2-SA1 | `src/portals/internal/pages/Departments.tsx` | New |
| 2-SA1 | `src/portals/internal/pages/TeamMembers.tsx` | New |
| 2-SA1 | `src/portals/internal/pages/Proposals.tsx` | New |
| 2-SA1 | `src/lib/api/people.ts` | New |
| 2-SA2 | `src/portals/internal/pages/Budget.tsx` | New |
| 2-SA2 | `src/portals/internal/pages/ProfitSplit.tsx` | New |
| 2-SA2 | `src/lib/api/academic.ts` | New |
| 2-SA3 | `src/portals/internal/pages/Partners.tsx` | New |
| 2-SA3 | `src/portals/internal/pages/Vouchers.tsx` | New |
| 2-SA3 | `src/portals/internal/pages/Calendar.tsx` | New |
| 2-SA3 | `src/lib/api/businessops.ts` | New |
| 2-SA4 | `src/portals/internal/pages/Franchises.tsx` | New |
| 2-SA4 | `src/lib/api/franchise.ts` | Extend |
| 2-SA5 | `src/portals/internal/pages/Notifications.tsx` | New |
| 2-SA5 | `src/portals/internal/pages/Students.tsx` | Polish |
| 2-SA5 | `src/portals/internal/pages/Enrollments.tsx` | Polish |
| 2-SA5 | `src/portals/internal/pages/Payments.tsx` | Polish |
| 2-SA5 | `src/portals/internal/pages/Courses.tsx` | Polish |
| 2-SA5 | `src/lib/api/platform-admin.ts` | New |
| 3 | `src/App.tsx` | Add new routes |
| 3 | `src/portals/internal/InternalPortal.tsx` | Role-aware nav |

---

## Success Criteria

- All internal roles can log in without 403
- Each role sees only their relevant nav items
- All 10 new pages load and display API data
- No TypeScript errors
- Existing pages (Student portal, Franchise portal) unaffected
