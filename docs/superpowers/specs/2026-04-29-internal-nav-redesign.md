# Internal Portal Nav Redesign + Domain Detail Pages

**Date:** 2026-04-29
**Status:** Approved

## Overview

Restructure internal portal navigation from a flat 15-item top bar into domain-grouped tabs with a secondary sub-page bar, add domain overview pages with KPIs, and add entity detail pages for all 13 entities.

---

## 1. Navigation Architecture

### Top Bar (level 1)

5 items replacing the current 15-item flat nav:

```
[Logo]  Dashboard | Academic | Finance | Operations | HR  [Bell] [Avatar]
```

`roleNav.ts` changes from `NavItem[]` to `DomainGroup[]`:

```ts
interface DomainGroup {
  label: string
  to: string           // overview page route
  allowedRoles?: string[]
  items: RoleNavItem[] // sub-pages
}
```

`TopNavBar` receives `domainNav: DomainGroup[]`. Active domain detection via `useMatch` on each group's `to` prefix.

### Secondary Bar — DomainNavBar (level 2)

New component `DomainNavBar.tsx`. Rendered by `InternalPortal` between top bar and main content. Router-based `NavLink`s (not button tabs) — URL changes on click.

Sticky at `top-14` (below top bar). Hidden when on Dashboard route.

Sub-pages per domain:

| Domain | Sub-pages |
|---|---|
| Academic | Courses, Enrollments, Proposals, Calendar |
| Finance | Payments, Budget, Profit Split, Vouchers |
| Operations | Franchises, Partners, Notifications |
| HR | Students, Departments, Team Members |

Role filtering applies per sub-page item — same `allowedRoles` rules as current nav.

### Page Tab Strip — SubNavBar (level 3)

Existing `SubNavContext` / `SubNavBar` unchanged. Used by individual pages for within-page filters (e.g. "All | Active | Archived"). Sticky offset increases to account for both bars above it.

---

## 2. Domain Overview Pages

4 new pages, one per domain. Navigated to when user clicks a domain tab in top bar.

Routes: `/internal/academic`, `/internal/finance`, `/internal/operations`, `/internal/hr`

### Layout per overview page

```
[Domain icon + title + description]
[KPI row: 4 metric cards]
[Quick Access grid: card per sub-page]
[Recent Activity: 5 most recent items across sub-domain]
```

### KPIs

| Domain | KPIs |
|---|---|
| Academic | Active courses, Total enrollments, Open proposals, Upcoming sessions this week |
| Finance | Monthly revenue, Pending payments count, Active vouchers, Budget utilization % |
| Operations | Active franchises, Active partners, Unread notifications |
| HR | Total students, Departments count, Total team members |

KPI data sourced from existing API hooks. No new backend endpoints required for overview pages.

### Role filtering on overview pages

Quick Access cards and KPIs for sub-pages the current role cannot access are hidden. Role check uses same `allowedRoles` config from `roleNav.ts`.

---

## 3. Entity Detail Pages

Full-page detail route for every entity. Pattern: `/internal/{entity}/{id}`.

### Standard layout

```
[Breadcrumb: Domain > List > Entity Name]
[Header: entity icon + name + status badge + action buttons (Edit, Actions▾)]
[Tab strip: Overview | [related tabs] | Activity]
[Tab content]
```

Header and tab strip extracted into reusable `DetailPageLayout.tsx` component.

### Tabs per entity

| Entity | Route | Tabs |
|---|---|---|
| Course | `/internal/courses/:id` | Overview, Enrollments, Proposals, Budget, Activity |
| Student | `/internal/students/:id` | Overview, Enrollments, Certificates, Payments, Activity |
| Enrollment | `/internal/enrollments/:id` | Overview, Payments, Activity |
| Department | `/internal/departments/:id` | Overview, Team Members, Courses, Budget, Activity |
| Team Member | `/internal/team-members/:id` | Overview, Enrollments (as facilitator), Activity |
| Proposal | `/internal/proposals/:id` | Overview, Budget, Activity |
| Partner | `/internal/partners/:id` | Overview, Courses, Revenue, Activity |
| Franchise | `/internal/franchises/:id` | Overview, Enrollments, Payments, Team, Activity |
| Voucher | `/internal/vouchers/:id` | Overview, Usage History, Activity |
| Payment | `/internal/payments/:id` | Overview, Activity |
| Budget | `/internal/budget/:id` | Overview, Transactions, Activity |
| Profit Split | `/internal/profit-split/:id` | Overview, Breakdown, Activity |
| Notification | `/internal/notifications/:id` | Overview, Send History, Activity |

### Navigation to detail

Clicking a row in any list page calls `navigate('/internal/{entity}/{id}')`. Breadcrumb back button returns to list.

### Data strategy

Detail pages use mock/placeholder data in this sprint. Backend `GET /api/{entity}/{id}` endpoints scoped to a future sprint. Hooks stubbed with `useEntityDetail(id)` returning mock shape — easy swap when backend is ready.

---

## 4. File Map

### New files

```
frontend/src/portals/internal/pages/domains/
  AcademicOverview.tsx
  FinanceOverview.tsx
  OperationsOverview.tsx
  HROverview.tsx

frontend/src/portals/internal/pages/detail/
  CourseDetail.tsx
  StudentDetail.tsx
  EnrollmentDetail.tsx
  DepartmentDetail.tsx
  TeamMemberDetail.tsx
  ProposalDetail.tsx
  PartnerDetail.tsx
  FranchiseDetail.tsx
  VoucherDetail.tsx
  PaymentDetail.tsx
  BudgetDetail.tsx
  ProfitSplitDetail.tsx
  NotificationDetail.tsx

frontend/src/components/layout/
  DomainNavBar.tsx
  DetailPageLayout.tsx
```

### Modified files

```
frontend/src/lib/auth/roleNav.ts
frontend/src/components/layout/TopNavBar.tsx
frontend/src/portals/internal/InternalPortal.tsx
frontend/src/App.tsx
```

### Unchanged

- `SubNavContext.tsx` / `SubNavBar.tsx`
- All existing list pages
- Student portal, Franchise portal
- Backend

---

## 5. New Routes (App.tsx)

```tsx
// Domain overviews
<Route path="academic" element={<AcademicOverview />} />
<Route path="finance" element={<FinanceOverview />} />
<Route path="operations" element={<OperationsOverview />} />
<Route path="hr" element={<HROverview />} />

// Entity detail pages
<Route path="courses/:id" element={<CourseDetail />} />
<Route path="students/:id" element={<StudentDetail />} />
<Route path="enrollments/:id" element={<EnrollmentDetail />} />
<Route path="departments/:id" element={<DepartmentDetail />} />
<Route path="team-members/:id" element={<TeamMemberDetail />} />
<Route path="proposals/:id" element={<ProposalDetail />} />
<Route path="partners/:id" element={<PartnerDetail />} />
<Route path="franchises/:id" element={<FranchiseDetail />} />
<Route path="vouchers/:id" element={<VoucherDetail />} />
<Route path="payments/:id" element={<PaymentDetail />} />
<Route path="budget/:id" element={<BudgetDetail />} />
<Route path="profit-split/:id" element={<ProfitSplitDetail />} />
<Route path="notifications/:id" element={<NotificationDetail />} />
```

Total new routes: 17
