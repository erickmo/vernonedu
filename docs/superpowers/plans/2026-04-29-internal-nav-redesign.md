# Internal Nav Redesign + Domain Detail Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure internal portal from a 15-item flat nav into domain-grouped tabs with a secondary sub-page bar, add domain overview pages with KPIs, and add entity detail pages for all 13 entities.

**Architecture:** TopNavBar renders 5 domain tabs (Dashboard + 4 domains). A new DomainNavBar renders the active domain's sub-pages as a secondary sticky bar. Clicking any list row navigates to a full-page entity detail view using a shared DetailPageLayout component.

**Tech Stack:** React 18, React Router v6, TanStack Query (SWR), Tailwind CSS, Radix UI, lucide-react, TypeScript. No test framework — use `npm run typecheck` for verification.

---

## File Map

**Modified:**
- `frontend/src/lib/auth/roleNav.ts` — flat NavItem[] → DomainGroup[] data model
- `frontend/src/components/layout/TopNavBar.tsx` — add optional `domainNav` prop
- `frontend/src/components/layout/SubNavContext.tsx` — add `topOffset` prop to SubNavBar
- `frontend/src/portals/internal/InternalPortal.tsx` — wire DomainNavBar
- `frontend/src/components/shared/DataTable.tsx` — add `onRowClick` prop
- `frontend/src/App.tsx` — add 17 new routes
- `frontend/src/portals/internal/pages/Courses.tsx` — add row click
- `frontend/src/portals/internal/pages/Students.tsx` — add row click
- `frontend/src/portals/internal/pages/Enrollments.tsx` — add row click
- `frontend/src/portals/internal/pages/Departments.tsx` — add row click
- `frontend/src/portals/internal/pages/TeamMembers.tsx` — add row click
- `frontend/src/portals/internal/pages/Proposals.tsx` — add row click
- `frontend/src/portals/internal/pages/Partners.tsx` — add row click
- `frontend/src/portals/internal/pages/Franchises.tsx` — add row click
- `frontend/src/portals/internal/pages/Vouchers.tsx` — add row click
- `frontend/src/portals/internal/pages/Payments.tsx` — add row click
- `frontend/src/portals/internal/pages/Notifications.tsx` — add row click

**Created:**
- `frontend/src/components/layout/DomainNavBar.tsx`
- `frontend/src/components/layout/DetailPageLayout.tsx`
- `frontend/src/portals/internal/pages/domains/AcademicOverview.tsx`
- `frontend/src/portals/internal/pages/domains/FinanceOverview.tsx`
- `frontend/src/portals/internal/pages/domains/OperationsOverview.tsx`
- `frontend/src/portals/internal/pages/domains/HROverview.tsx`
- `frontend/src/portals/internal/pages/detail/CourseDetail.tsx`
- `frontend/src/portals/internal/pages/detail/StudentDetail.tsx`
- `frontend/src/portals/internal/pages/detail/EnrollmentDetail.tsx`
- `frontend/src/portals/internal/pages/detail/DepartmentDetail.tsx`
- `frontend/src/portals/internal/pages/detail/TeamMemberDetail.tsx`
- `frontend/src/portals/internal/pages/detail/ProposalDetail.tsx`
- `frontend/src/portals/internal/pages/detail/PartnerDetail.tsx`
- `frontend/src/portals/internal/pages/detail/FranchiseDetail.tsx`
- `frontend/src/portals/internal/pages/detail/VoucherDetail.tsx`
- `frontend/src/portals/internal/pages/detail/PaymentDetail.tsx`
- `frontend/src/portals/internal/pages/detail/BudgetDetail.tsx`
- `frontend/src/portals/internal/pages/detail/ProfitSplitDetail.tsx`
- `frontend/src/portals/internal/pages/detail/NotificationDetail.tsx`

---

## Task 1: DataTable onRowClick

**Files:**
- Modify: `frontend/src/components/shared/DataTable.tsx`

- [ ] **Step 1: Add `onRowClick` prop to DataTable interface**

In `DataTable.tsx`, add to `DataTableProps<T>`:

```ts
interface DataTableProps<T> {
  columns: Column<T>[]
  data: T[]
  loading?: boolean
  pagination?: Pagination
  onPageChange?: (page: number) => void
  rowKey?: (row: T) => string
  onRowClick?: (row: T) => void   // ← add this
}
```

Update the destructure:

```ts
export default function DataTable<T>({
  columns,
  data,
  loading = false,
  pagination,
  onPageChange,
  rowKey,
  onRowClick,           // ← add
}: DataTableProps<T>) {
```

Update the `<tr>` element (around line 88):

```tsx
<tr
  key={rowKey ? rowKey(row) : idx}
  onClick={() => onRowClick?.(row)}
  className={cn(
    'hover:bg-neutral-50 transition-colors',
    onRowClick && 'cursor-pointer',
  )}
>
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/shared/DataTable.tsx
git commit -m "feat(ui): add onRowClick prop to DataTable"
```

---

## Task 2: Nav Data Model

**Files:**
- Modify: `frontend/src/lib/auth/roleNav.ts`

- [ ] **Step 1: Replace the file with domain-group data model**

Replace the entire contents of `frontend/src/lib/auth/roleNav.ts`:

```ts
import type { NavItem } from '@/components/layout/TopNavBar'

export interface DomainSubItem {
  to: string
  label: string
  allowedRoles?: string[]
}

export interface DomainGroup {
  label: string
  to: string
  allowedRoles?: string[]
  items: DomainSubItem[]
}

const INTERNAL_DOMAINS: DomainGroup[] = [
  {
    label: 'Academic',
    to: '/internal/academic',
    items: [
      { to: '/internal/courses', label: 'Courses' },
      { to: '/internal/enrollments', label: 'Enrollments' },
      {
        to: '/internal/proposals',
        label: 'Proposals',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'dept_leader', 'academic_leader', 'course_creator', 'finance', 'facilitator'],
      },
      { to: '/internal/calendar', label: 'Calendar' },
    ],
  },
  {
    label: 'Finance',
    to: '/internal/finance',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'finance', 'course_creator'],
    items: [
      {
        to: '/internal/payments',
        label: 'Payments',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'finance'],
      },
      {
        to: '/internal/budget',
        label: 'Budget',
        allowedRoles: ['course_creator', 'dept_leader', 'vernonedu_admin', 'ceo'],
      },
      {
        to: '/internal/profit-split',
        label: 'Profit Split',
        allowedRoles: ['ceo', 'vernonedu_admin', 'course_creator'],
      },
      {
        to: '/internal/vouchers',
        label: 'Vouchers',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
      },
    ],
  },
  {
    label: 'Operations',
    to: '/internal/operations',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
    items: [
      {
        to: '/internal/franchises',
        label: 'Franchises',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
      },
      {
        to: '/internal/partners',
        label: 'Partners',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
      },
      {
        to: '/internal/notifications',
        label: 'Notifications',
        allowedRoles: ['admin', 'vernonedu_admin'],
      },
    ],
  },
  {
    label: 'HR',
    to: '/internal/hr',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'dept_leader', 'academic_leader'],
    items: [
      {
        to: '/internal/students',
        label: 'Students',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
      },
      {
        to: '/internal/departments',
        label: 'Departments',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'dept_leader', 'academic_leader'],
      },
      {
        to: '/internal/team-members',
        label: 'Team Members',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'dept_leader', 'academic_leader'],
      },
    ],
  },
]

export function getInternalDomains(role: string): DomainGroup[] {
  const normalized = role.toLowerCase()
  return INTERNAL_DOMAINS
    .filter(d => !d.allowedRoles || d.allowedRoles.includes(normalized))
    .map(d => ({
      ...d,
      items: d.items.filter(item => !item.allowedRoles || item.allowedRoles.includes(normalized)),
    }))
}

// Legacy flat nav for student/franchise portals (NavItem shape unchanged)
export function getInternalNavItems(_role: string): NavItem[] {
  return []  // no longer used by InternalPortal
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```

Expected: errors only in `InternalPortal.tsx` (still passing old `navItems` to TopNavBar — fix in Task 5).

- [ ] **Step 3: Commit**

```bash
git add frontend/src/lib/auth/roleNav.ts
git commit -m "refactor(nav): replace flat NavItem[] with DomainGroup[] data model"
```

---

## Task 3: DomainNavBar Component

**Files:**
- Create: `frontend/src/components/layout/DomainNavBar.tsx`

- [ ] **Step 1: Create DomainNavBar**

```tsx
import { NavLink, useLocation } from 'react-router-dom'
import { cn } from '@/lib/utils/cn'
import { getInternalDomains } from '@/lib/auth/roleNav'
import { useAuth } from '@/lib/auth/useAuth'

export default function DomainNavBar() {
  const { user } = useAuth()
  const location = useLocation()
  const domains = getInternalDomains(user?.role ?? '')

  const activeDomain = domains.find(
    d =>
      location.pathname === d.to ||
      d.items.some(item => location.pathname.startsWith(item.to)),
  )

  if (!activeDomain) return null

  return (
    <div className="sticky top-14 z-40 h-10 bg-white border-b border-neutral-100 flex items-center px-6 md:px-8 gap-0.5 overflow-x-auto scrollbar-none">
      {activeDomain.items.map(item => (
        <NavLink
          key={item.to}
          to={item.to}
          className={({ isActive }) =>
            cn(
              'shrink-0 px-3 h-10 text-sm font-medium transition-colors relative whitespace-nowrap flex items-center',
              isActive
                ? 'text-brand-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-brand-600 after:rounded-t-full'
                : 'text-neutral-500 hover:text-neutral-700 hover:bg-neutral-50',
            )
          }
        >
          {item.label}
        </NavLink>
      ))}
    </div>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```

Expected: no new errors from this file.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/layout/DomainNavBar.tsx
git commit -m "feat(nav): add DomainNavBar secondary navigation component"
```

---

## Task 4: TopNavBar + SubNavBar Updates

**Files:**
- Modify: `frontend/src/components/layout/TopNavBar.tsx`
- Modify: `frontend/src/components/layout/SubNavContext.tsx`

- [ ] **Step 1: Add `domainNav` prop to TopNavBar**

In `TopNavBar.tsx`, add to the imports and interfaces:

```ts
import type { DomainGroup } from '@/lib/auth/roleNav'
```

Add to `TopNavBarProps`:

```ts
interface TopNavBarProps {
  mainNav?: NavItem[]         // used by student/franchise portals
  domainNav?: DomainGroup[]   // used by internal portal
  user: { id: string; name: string; role: string; email: string } | null
  unreadCount?: number
  onLogout: () => void
  avatarClass?: string
}
```

Replace the desktop nav section (the `<nav>` element) in the JSX:

```tsx
{/* Main nav — desktop */}
<nav className="hidden md:flex items-center gap-0.5 flex-1">
  {domainNav
    ? domainNav.map(domain => (
        <NavLink
          key={domain.to}
          to={domain.to}
          className={({ isActive }) =>
            cn(
              'relative px-3 py-2 text-sm font-medium rounded-lg transition-colors',
              isActive
                ? 'text-brand-600 after:absolute after:bottom-1 after:left-3 after:right-3 after:h-0.5 after:bg-brand-600 after:rounded-full'
                : 'text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50',
            )
          }
        >
          {domain.label}
        </NavLink>
      ))
    : (mainNav ?? []).map(item => (
        <NavLink
          key={item.to}
          to={item.to}
          end={item.end}
          className={({ isActive }) =>
            cn(
              'relative px-3 py-2 text-sm font-medium rounded-lg transition-colors',
              isActive
                ? 'text-brand-600 after:absolute after:bottom-1 after:left-3 after:right-3 after:h-0.5 after:bg-brand-600 after:rounded-full'
                : 'text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50',
            )
          }
        >
          {item.label}
        </NavLink>
      ))}
</nav>
```

Also replace the mobile nav drawer items in the same way — when `domainNav` provided, render domain labels; otherwise render flat `mainNav` items.

- [ ] **Step 2: Add `topOffset` prop to SubNavBar**

In `SubNavContext.tsx`, update `SubNavBar`:

```tsx
export function SubNavBar({ topOffset = 'top-14' }: { topOffset?: string }) {
  const state = useSubNavState()
  if (!state || state.items.length === 0) return null

  return (
    <div className={cn(
      'sticky z-40 h-11 bg-neutral-50 border-b border-neutral-100 flex items-center px-6 md:px-8 gap-0.5 overflow-x-auto scrollbar-none',
      topOffset,
    )}>
      {state.items.map((item) => (
        <button
          key={item.value}
          onClick={() => state.onChange(item.value)}
          className={cn(
            'shrink-0 px-3 h-11 text-sm font-medium transition-colors relative whitespace-nowrap',
            state.active === item.value
              ? 'text-brand-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-brand-600 after:rounded-t-full'
              : 'text-neutral-500 hover:text-neutral-700 hover:bg-neutral-100/60',
          )}
        >
          {item.label}
        </button>
      ))}
    </div>
  )
}
```

- [ ] **Step 3: Typecheck**

```bash
cd frontend && npm run typecheck
```

- [ ] **Step 4: Commit**

```bash
git add frontend/src/components/layout/TopNavBar.tsx frontend/src/components/layout/SubNavContext.tsx
git commit -m "feat(nav): add domainNav prop to TopNavBar, topOffset prop to SubNavBar"
```

---

## Task 5: InternalPortal Wiring

**Files:**
- Modify: `frontend/src/portals/internal/InternalPortal.tsx`

- [ ] **Step 1: Replace InternalPortal.tsx**

```tsx
import { Outlet, useNavigate, NavLink } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import { useUnreadCount } from '@/lib/api/platform'
import { SubNavProvider, SubNavBar } from '@/components/layout/SubNavContext'
import TopNavBar from '@/components/layout/TopNavBar'
import DomainNavBar from '@/components/layout/DomainNavBar'
import { getInternalDomains } from '@/lib/auth/roleNav'
import { cn } from '@/lib/utils/cn'
import { NavLink as RouterNavLink } from 'react-router-dom'

function InternalLayout() {
  const { user, logout } = useAuth()
  const unread = useUnreadCount()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const domains = getInternalDomains(user?.role ?? '')

  // Prepend Dashboard as a standalone nav item rendered separately
  const domainNavWithDashboard = domains

  return (
    <div className="min-h-screen bg-neutral-50">
      <TopNavBar
        domainNav={domainNavWithDashboard}
        user={user}
        unreadCount={unread}
        onLogout={handleLogout}
        avatarClass="bg-brand-100 text-brand-700"
        dashboardTo="/internal"
      />
      <DomainNavBar />
      <SubNavBar topOffset="top-24" />
      <main className="px-6 md:px-8 lg:px-12 py-6">
        <Outlet />
      </main>
    </div>
  )
}

export default function InternalPortal() {
  return (
    <SubNavProvider>
      <InternalLayout />
    </SubNavProvider>
  )
}
```

- [ ] **Step 2: Add `dashboardTo` prop to TopNavBar**

In `TopNavBar.tsx`, add `dashboardTo?: string` to `TopNavBarProps`. When `domainNav` is provided and `dashboardTo` is set, prepend a Dashboard NavLink before the domain tabs:

```tsx
interface TopNavBarProps {
  mainNav?: NavItem[]
  domainNav?: DomainGroup[]
  dashboardTo?: string    // ← add
  user: ...
  ...
}
```

In the desktop nav:

```tsx
<nav className="hidden md:flex items-center gap-0.5 flex-1">
  {dashboardTo && domainNav && (
    <NavLink
      to={dashboardTo}
      end
      className={({ isActive }) =>
        cn(
          'relative px-3 py-2 text-sm font-medium rounded-lg transition-colors',
          isActive
            ? 'text-brand-600 after:absolute after:bottom-1 after:left-3 after:right-3 after:h-0.5 after:bg-brand-600 after:rounded-full'
            : 'text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50',
        )
      }
    >
      Dashboard
    </NavLink>
  )}
  {domainNav
    ? domainNav.map(domain => ( ... ))
    : (mainNav ?? []).map(item => ( ... ))}
</nav>
```

Do the same in the mobile drawer.

- [ ] **Step 3: Typecheck**

```bash
cd frontend && npm run typecheck
```

Expected: 0 errors.

- [ ] **Step 4: Verify in browser**

Start dev server: `cd frontend && npm run dev`

Open http://localhost:5173. Log in as internal user. Verify:
- Top bar shows: Dashboard | Academic | Finance | Operations | HR
- Clicking Academic → secondary bar shows: Courses | Enrollments | Proposals | Calendar
- Clicking Finance → secondary bar shows: Payments | Budget | Profit Split | Vouchers
- Dashboard click → secondary bar disappears

- [ ] **Step 5: Commit**

```bash
git add frontend/src/portals/internal/InternalPortal.tsx frontend/src/components/layout/TopNavBar.tsx
git commit -m "feat(nav): wire domain nav and DomainNavBar into InternalPortal"
```

---

## Task 6: DetailPageLayout Component

**Files:**
- Create: `frontend/src/components/layout/DetailPageLayout.tsx`

- [ ] **Step 1: Create DetailPageLayout**

```tsx
import { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { ChevronRight } from 'lucide-react'
import { cn } from '@/lib/utils/cn'

export interface BreadcrumbItem {
  label: string
  to?: string
}

export interface DetailTab {
  value: string
  label: string
  badge?: number
}

interface DetailPageLayoutProps {
  breadcrumbs: BreadcrumbItem[]
  icon: ReactNode
  title: string
  subtitle?: string
  status?: ReactNode
  actions?: ReactNode
  tabs: DetailTab[]
  activeTab: string
  onTabChange: (value: string) => void
  children: ReactNode
}

export default function DetailPageLayout({
  breadcrumbs,
  icon,
  title,
  subtitle,
  status,
  actions,
  tabs,
  activeTab,
  onTabChange,
  children,
}: DetailPageLayoutProps) {
  return (
    <div className="-mx-6 md:-mx-8 lg:-mx-12 -mt-6">
      {/* Page header card */}
      <div className="bg-white border-b border-neutral-100 px-6 md:px-8 lg:px-12 pt-4 pb-0">
        {/* Breadcrumb */}
        <nav className="flex items-center gap-1 text-xs text-neutral-400 mb-3">
          {breadcrumbs.map((crumb, idx) => (
            <span key={idx} className="flex items-center gap-1">
              {idx > 0 && <ChevronRight className="w-3 h-3" />}
              {crumb.to ? (
                <Link to={crumb.to} className="hover:text-neutral-600 transition-colors">
                  {crumb.label}
                </Link>
              ) : (
                <span className="text-neutral-600 font-medium">{crumb.label}</span>
              )}
            </span>
          ))}
        </nav>

        {/* Header row */}
        <div className="flex items-start gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl bg-brand-50 border border-brand-100 flex items-center justify-center shrink-0">
            {icon}
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h1 className="text-lg font-bold text-neutral-900 leading-tight">{title}</h1>
              {status}
            </div>
            {subtitle && (
              <p className="text-sm text-neutral-500 mt-0.5">{subtitle}</p>
            )}
          </div>
          {actions && (
            <div className="flex items-center gap-2 shrink-0">{actions}</div>
          )}
        </div>

        {/* Tab strip */}
        <div className="flex gap-0 -mb-px overflow-x-auto scrollbar-none">
          {tabs.map(tab => (
            <button
              key={tab.value}
              onClick={() => onTabChange(tab.value)}
              className={cn(
                'shrink-0 flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors whitespace-nowrap',
                activeTab === tab.value
                  ? 'text-brand-600 border-brand-600'
                  : 'text-neutral-500 border-transparent hover:text-neutral-700 hover:border-neutral-200',
              )}
            >
              {tab.label}
              {tab.badge !== undefined && (
                <span className={cn(
                  'text-xs px-1.5 py-0.5 rounded-full font-medium',
                  activeTab === tab.value ? 'bg-brand-100 text-brand-700' : 'bg-neutral-100 text-neutral-500',
                )}>
                  {tab.badge}
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Tab content */}
      <div className="px-6 md:px-8 lg:px-12 py-6">
        {children}
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/layout/DetailPageLayout.tsx
git commit -m "feat(ui): add DetailPageLayout — shared header/tabs/breadcrumb for detail pages"
```

---

## Task 7: Domain Overview Pages

**Files:**
- Create: `frontend/src/portals/internal/pages/domains/AcademicOverview.tsx`
- Create: `frontend/src/portals/internal/pages/domains/FinanceOverview.tsx`
- Create: `frontend/src/portals/internal/pages/domains/OperationsOverview.tsx`
- Create: `frontend/src/portals/internal/pages/domains/HROverview.tsx`

- [ ] **Step 1: Create AcademicOverview.tsx**

```tsx
import { useNavigate } from 'react-router-dom'
import { BookOpen, Users, FileText, Calendar, GraduationCap } from 'lucide-react'
import { useCourses } from '@/lib/api/catalog'
import { useEnrollments } from '@/lib/api/enrollment'
import { useFacilitatorProposals } from '@/lib/api/identity'
import { useCalendarEvents } from '@/lib/api/businessops'
import PageHeader from '@/components/shared/PageHeader'

const QUICK_ACCESS = [
  { label: 'Courses', to: '/internal/courses', icon: BookOpen, description: 'Manage course catalog' },
  { label: 'Enrollments', to: '/internal/enrollments', icon: Users, description: 'Track student enrollments' },
  { label: 'Proposals', to: '/internal/proposals', icon: FileText, description: 'Review course proposals' },
  { label: 'Calendar', to: '/internal/calendar', icon: Calendar, description: 'Session schedule & events' },
]

export default function AcademicOverview() {
  const navigate = useNavigate()
  const { data: coursesData } = useCourses({ status: 'published' })
  const { data: enrollmentsData } = useEnrollments({})
  const { data: proposalsData } = useFacilitatorProposals({ status: 'pending' })
  const { data: eventsData } = useCalendarEvents()

  const kpis = [
    {
      label: 'Active Courses',
      value: coursesData?.total ?? '—',
      sub: 'published',
      color: 'text-brand-600',
      bg: 'bg-brand-50',
    },
    {
      label: 'Total Enrollments',
      value: enrollmentsData?.total ?? '—',
      sub: 'all time',
      color: 'text-emerald-600',
      bg: 'bg-emerald-50',
    },
    {
      label: 'Open Proposals',
      value: proposalsData?.total ?? '—',
      sub: 'pending review',
      color: 'text-amber-600',
      bg: 'bg-amber-50',
    },
    {
      label: 'Upcoming Sessions',
      value: eventsData?.length ?? '—',
      sub: 'scheduled',
      color: 'text-violet-600',
      bg: 'bg-violet-50',
    },
  ]

  return (
    <div>
      <PageHeader
        title="Academic"
        subtitle="Courses, enrollments, proposals, and academic calendar"
        icon={<GraduationCap className="w-5 h-5 text-brand-600" />}
      />

      {/* KPI row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {kpis.map(kpi => (
          <div key={kpi.label} className={`rounded-xl border border-neutral-100 bg-white p-4`}>
            <p className="text-xs font-medium text-neutral-500 mb-1">{kpi.label}</p>
            <p className={`text-3xl font-bold ${kpi.color}`}>{kpi.value}</p>
            <p className="text-xs text-neutral-400 mt-0.5">{kpi.sub}</p>
          </div>
        ))}
      </div>

      {/* Quick access */}
      <p className="text-xs font-semibold text-neutral-400 uppercase tracking-wider mb-3">Quick Access</p>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {QUICK_ACCESS.map(item => (
          <button
            key={item.to}
            onClick={() => navigate(item.to)}
            className="rounded-xl border border-neutral-100 bg-white p-5 text-left hover:border-brand-200 hover:shadow-sm transition-all group"
          >
            <div className="w-10 h-10 rounded-lg bg-brand-50 flex items-center justify-center mb-3 group-hover:bg-brand-100 transition-colors">
              <item.icon className="w-5 h-5 text-brand-600" />
            </div>
            <p className="text-sm font-semibold text-neutral-800">{item.label}</p>
            <p className="text-xs text-neutral-400 mt-0.5">{item.description}</p>
          </button>
        ))}
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Create FinanceOverview.tsx**

```tsx
import { useNavigate } from 'react-router-dom'
import { CreditCard, PiggyBank, TrendingUp, Tag, DollarSign } from 'lucide-react'
import { useInvoices } from '@/lib/api/finance'
import { useVouchers } from '@/lib/api/businessops'
import PageHeader from '@/components/shared/PageHeader'

const QUICK_ACCESS = [
  { label: 'Payments', to: '/internal/payments', icon: CreditCard, description: 'Payment records & invoices' },
  { label: 'Budget', to: '/internal/budget', icon: PiggyBank, description: 'Budget tracking per batch' },
  { label: 'Profit Split', to: '/internal/profit-split', icon: TrendingUp, description: 'Revenue distribution' },
  { label: 'Vouchers', to: '/internal/vouchers', icon: Tag, description: 'Discount voucher management' },
]

export default function FinanceOverview() {
  const navigate = useNavigate()
  const { data: invoicesData } = useInvoices({})
  const { data: vouchersData } = useVouchers()

  const pendingInvoices = invoicesData?.data?.filter(i => i.status === 'pending')?.length ?? '—'
  const activeVouchers = Array.isArray(vouchersData) ? vouchersData.filter(v => v.is_active).length : '—'

  const kpis = [
    { label: 'Total Invoices', value: invoicesData?.total ?? '—', sub: 'all time', color: 'text-brand-600' },
    { label: 'Pending Payments', value: pendingInvoices, sub: 'awaiting confirmation', color: 'text-amber-600' },
    { label: 'Active Vouchers', value: activeVouchers, sub: 'currently valid', color: 'text-emerald-600' },
    { label: 'Budget Items', value: '—', sub: 'track in batch detail', color: 'text-violet-600' },
  ]

  return (
    <div>
      <PageHeader
        title="Finance"
        subtitle="Payments, budget tracking, profit distribution, and vouchers"
        icon={<DollarSign className="w-5 h-5 text-brand-600" />}
      />

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {kpis.map(kpi => (
          <div key={kpi.label} className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs font-medium text-neutral-500 mb-1">{kpi.label}</p>
            <p className={`text-3xl font-bold ${kpi.color}`}>{kpi.value}</p>
            <p className="text-xs text-neutral-400 mt-0.5">{kpi.sub}</p>
          </div>
        ))}
      </div>

      <p className="text-xs font-semibold text-neutral-400 uppercase tracking-wider mb-3">Quick Access</p>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {QUICK_ACCESS.map(item => (
          <button
            key={item.to}
            onClick={() => navigate(item.to)}
            className="rounded-xl border border-neutral-100 bg-white p-5 text-left hover:border-brand-200 hover:shadow-sm transition-all group"
          >
            <div className="w-10 h-10 rounded-lg bg-brand-50 flex items-center justify-center mb-3 group-hover:bg-brand-100 transition-colors">
              <item.icon className="w-5 h-5 text-brand-600" />
            </div>
            <p className="text-sm font-semibold text-neutral-800">{item.label}</p>
            <p className="text-xs text-neutral-400 mt-0.5">{item.description}</p>
          </button>
        ))}
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Create OperationsOverview.tsx**

```tsx
import { useNavigate } from 'react-router-dom'
import { Building2, Handshake, Bell, Settings } from 'lucide-react'
import { useFranchises } from '@/lib/api/partnerships'
import { usePartners } from '@/lib/api/partnerships'
import { useUnreadCount } from '@/lib/api/platform'
import PageHeader from '@/components/shared/PageHeader'

const QUICK_ACCESS = [
  { label: 'Franchises', to: '/internal/franchises', icon: Building2, description: 'Franchise network management' },
  { label: 'Partners', to: '/internal/partners', icon: Handshake, description: 'Business partner directory' },
  { label: 'Notifications', to: '/internal/notifications', icon: Bell, description: 'Notification templates' },
]

export default function OperationsOverview() {
  const navigate = useNavigate()
  const { data: franchisesData } = useFranchises()
  const { data: partnersData } = usePartners({})
  const unreadCount = useUnreadCount()

  const kpis = [
    { label: 'Active Franchises', value: Array.isArray(franchisesData) ? franchisesData.length : '—', sub: 'franchise locations', color: 'text-brand-600' },
    { label: 'Active Partners', value: partnersData?.total ?? '—', sub: 'business partners', color: 'text-emerald-600' },
    { label: 'Unread Notifications', value: unreadCount ?? 0, sub: 'pending', color: 'text-amber-600' },
  ]

  return (
    <div>
      <PageHeader
        title="Operations"
        subtitle="Franchise network, business partners, and notifications"
        icon={<Settings className="w-5 h-5 text-brand-600" />}
      />

      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        {kpis.map(kpi => (
          <div key={kpi.label} className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs font-medium text-neutral-500 mb-1">{kpi.label}</p>
            <p className={`text-3xl font-bold ${kpi.color}`}>{kpi.value}</p>
            <p className="text-xs text-neutral-400 mt-0.5">{kpi.sub}</p>
          </div>
        ))}
      </div>

      <p className="text-xs font-semibold text-neutral-400 uppercase tracking-wider mb-3">Quick Access</p>
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
        {QUICK_ACCESS.map(item => (
          <button
            key={item.to}
            onClick={() => navigate(item.to)}
            className="rounded-xl border border-neutral-100 bg-white p-5 text-left hover:border-brand-200 hover:shadow-sm transition-all group"
          >
            <div className="w-10 h-10 rounded-lg bg-brand-50 flex items-center justify-center mb-3 group-hover:bg-brand-100 transition-colors">
              <item.icon className="w-5 h-5 text-brand-600" />
            </div>
            <p className="text-sm font-semibold text-neutral-800">{item.label}</p>
            <p className="text-xs text-neutral-400 mt-0.5">{item.description}</p>
          </button>
        ))}
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Create HROverview.tsx**

```tsx
import { useNavigate } from 'react-router-dom'
import { GraduationCap, Building, Users, UsersRound } from 'lucide-react'
import { useStudents } from '@/lib/api/identity'
import { useDepartments } from '@/lib/api/identity'
import { useTeamMembers } from '@/lib/api/identity'
import PageHeader from '@/components/shared/PageHeader'

const QUICK_ACCESS = [
  { label: 'Students', to: '/internal/students', icon: GraduationCap, description: 'Student records & profiles' },
  { label: 'Departments', to: '/internal/departments', icon: Building, description: 'Department structure' },
  { label: 'Team Members', to: '/internal/team-members', icon: Users, description: 'Staff & facilitators' },
]

export default function HROverview() {
  const navigate = useNavigate()
  const { data: studentsData } = useStudents({})
  const { data: departmentsData } = useDepartments()
  const { data: teamData } = useTeamMembers({})

  const kpis = [
    { label: 'Total Students', value: studentsData?.total ?? '—', sub: 'registered', color: 'text-brand-600' },
    { label: 'Departments', value: Array.isArray(departmentsData) ? departmentsData.length : '—', sub: 'active units', color: 'text-emerald-600' },
    { label: 'Team Members', value: teamData?.total ?? '—', sub: 'staff & facilitators', color: 'text-violet-600' },
  ]

  return (
    <div>
      <PageHeader
        title="HR"
        subtitle="Students, departments, and team member management"
        icon={<UsersRound className="w-5 h-5 text-brand-600" />}
      />

      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        {kpis.map(kpi => (
          <div key={kpi.label} className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs font-medium text-neutral-500 mb-1">{kpi.label}</p>
            <p className={`text-3xl font-bold ${kpi.color}`}>{kpi.value}</p>
            <p className="text-xs text-neutral-400 mt-0.5">{kpi.sub}</p>
          </div>
        ))}
      </div>

      <p className="text-xs font-semibold text-neutral-400 uppercase tracking-wider mb-3">Quick Access</p>
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
        {QUICK_ACCESS.map(item => (
          <button
            key={item.to}
            onClick={() => navigate(item.to)}
            className="rounded-xl border border-neutral-100 bg-white p-5 text-left hover:border-brand-200 hover:shadow-sm transition-all group"
          >
            <div className="w-10 h-10 rounded-lg bg-brand-50 flex items-center justify-center mb-3 group-hover:bg-brand-100 transition-colors">
              <item.icon className="w-5 h-5 text-brand-600" />
            </div>
            <p className="text-sm font-semibold text-neutral-800">{item.label}</p>
            <p className="text-xs text-neutral-400 mt-0.5">{item.description}</p>
          </button>
        ))}
      </div>
    </div>
  )
}
```

- [ ] **Step 5: Typecheck**

```bash
cd frontend && npm run typecheck
```

Fix any import errors (missing hooks, wrong paths). The hooks `useFacilitatorProposals`, `useCalendarEvents`, `useFranchises`, `usePartners`, `useStudents`, `useDepartments`, `useTeamMembers`, `useInvoices`, `useVouchers`, `useUnreadCount` all exist — confirm correct import paths from `@/lib/api/*`.

- [ ] **Step 6: Commit**

```bash
git add frontend/src/portals/internal/pages/domains/
git commit -m "feat(internal): add domain overview pages — Academic, Finance, Operations, HR"
```

---

## Task 8: Entity Detail Pages — Academic Domain

**Files:**
- Create: `frontend/src/portals/internal/pages/detail/CourseDetail.tsx`
- Create: `frontend/src/portals/internal/pages/detail/EnrollmentDetail.tsx`
- Create: `frontend/src/portals/internal/pages/detail/ProposalDetail.tsx`

- [ ] **Step 1: Create CourseDetail.tsx**

```tsx
import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { BookOpen, Edit, MoreHorizontal } from 'lucide-react'
import { useCourse } from '@/lib/api/catalog'
import DetailPageLayout from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const TABS = [
  { value: 'overview', label: 'Overview' },
  { value: 'enrollments', label: 'Enrollments' },
  { value: 'proposals', label: 'Proposals' },
  { value: 'budget', label: 'Budget' },
  { value: 'activity', label: 'Activity' },
]

export default function CourseDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: course, isLoading } = useCourse(id!)
  const [activeTab, setActiveTab] = useState('overview')

  if (isLoading) return <LoadingSpinner size="lg" />
  if (!course) return (
    <div className="text-center py-20 text-neutral-400">
      <p>Course not found.</p>
      <button onClick={() => navigate('/internal/courses')} className="mt-2 text-brand-600 text-sm">← Back to Courses</button>
    </div>
  )

  return (
    <DetailPageLayout
      breadcrumbs={[
        { label: 'Academic', to: '/internal/academic' },
        { label: 'Courses', to: '/internal/courses' },
        { label: course.name },
      ]}
      icon={<BookOpen className="w-5 h-5 text-brand-600" />}
      title={course.name}
      subtitle={`${course.code} · ${course.format} · ${course.duration_days} days`}
      status={<StatusBadge status={course.status} />}
      actions={
        <>
          <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors">
            <Edit className="w-3.5 h-3.5" /> Edit
          </button>
          <button className="p-1.5 border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors">
            <MoreHorizontal className="w-4 h-4" />
          </button>
        </>
      }
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Duration</p>
            <p className="text-2xl font-bold text-neutral-800">{course.duration_days}</p>
            <p className="text-xs text-neutral-400">days</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Format</p>
            <p className="text-lg font-bold text-neutral-800 capitalize">{course.format}</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Status</p>
            <p className="text-lg font-bold text-neutral-800 capitalize">{course.status}</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Code</p>
            <p className="text-lg font-bold text-neutral-800">{course.code}</p>
          </div>
          {course.description && (
            <div className="col-span-2 lg:col-span-4 rounded-xl border border-neutral-100 bg-white p-4">
              <p className="text-xs text-neutral-500 mb-2">Description</p>
              <p className="text-sm text-neutral-700 leading-relaxed">{course.description}</p>
            </div>
          )}
        </div>
      )}
      {activeTab !== 'overview' && (
        <div className="py-12 text-center text-neutral-400 text-sm">
          {TABS.find(t => t.value === activeTab)?.label} — coming in next sprint
        </div>
      )}
    </DetailPageLayout>
  )
}
```

- [ ] **Step 2: Create EnrollmentDetail.tsx**

```tsx
import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ClipboardList, Edit } from 'lucide-react'
import { useEnrollment } from '@/lib/api/enrollment'
import DetailPageLayout from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const TABS = [
  { value: 'overview', label: 'Overview' },
  { value: 'payments', label: 'Payments' },
  { value: 'activity', label: 'Activity' },
]

export default function EnrollmentDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: enrollment, isLoading } = useEnrollment(id!)
  const [activeTab, setActiveTab] = useState('overview')

  if (isLoading) return <LoadingSpinner size="lg" />
  if (!enrollment) return (
    <div className="text-center py-20 text-neutral-400">
      <p>Enrollment not found.</p>
      <button onClick={() => navigate('/internal/enrollments')} className="mt-2 text-brand-600 text-sm">← Back to Enrollments</button>
    </div>
  )

  return (
    <DetailPageLayout
      breadcrumbs={[
        { label: 'Academic', to: '/internal/academic' },
        { label: 'Enrollments', to: '/internal/enrollments' },
        { label: `Enrollment #${enrollment.id.slice(0, 8)}` },
      ]}
      icon={<ClipboardList className="w-5 h-5 text-brand-600" />}
      title={`Enrollment #${enrollment.id.slice(0, 8)}`}
      subtitle={`Batch: ${enrollment.batch_id}`}
      status={<StatusBadge status={enrollment.status} />}
      actions={
        <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors">
          <Edit className="w-3.5 h-3.5" /> Edit
        </button>
      }
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Student ID</p>
            <p className="text-sm font-bold text-neutral-800">{enrollment.student_id}</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Batch ID</p>
            <p className="text-sm font-bold text-neutral-800">{enrollment.batch_id}</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Status</p>
            <p className="text-sm font-bold text-neutral-800 capitalize">{enrollment.status}</p>
          </div>
          {enrollment.completed_at && (
            <div className="rounded-xl border border-neutral-100 bg-white p-4">
              <p className="text-xs text-neutral-500 mb-1">Completed At</p>
              <p className="text-sm font-bold text-neutral-800">{new Date(enrollment.completed_at).toLocaleDateString()}</p>
            </div>
          )}
        </div>
      )}
      {activeTab !== 'overview' && (
        <div className="py-12 text-center text-neutral-400 text-sm">
          {TABS.find(t => t.value === activeTab)?.label} — coming in next sprint
        </div>
      )}
    </DetailPageLayout>
  )
}
```

- [ ] **Step 3: Create ProposalDetail.tsx**

Proposals have no `getById` API — use mock data pattern:

```tsx
import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { FileText, Edit } from 'lucide-react'
import DetailPageLayout from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'

const TABS = [
  { value: 'overview', label: 'Overview' },
  { value: 'budget', label: 'Budget' },
  { value: 'activity', label: 'Activity' },
]

// Stub — replace with real hook when backend GET /proposals/:id is ready
function useProposalDetail(id: string) {
  return {
    data: {
      id,
      title: 'Course Proposal',
      status: 'pending',
      proposed_by: '—',
      created_at: new Date().toISOString(),
    },
    isLoading: false,
  }
}

export default function ProposalDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: proposal, isLoading } = useProposalDetail(id!)
  const [activeTab, setActiveTab] = useState('overview')

  if (isLoading) return null

  return (
    <DetailPageLayout
      breadcrumbs={[
        { label: 'Academic', to: '/internal/academic' },
        { label: 'Proposals', to: '/internal/proposals' },
        { label: proposal.title },
      ]}
      icon={<FileText className="w-5 h-5 text-brand-600" />}
      title={proposal.title}
      subtitle={`Submitted ${new Date(proposal.created_at).toLocaleDateString()}`}
      status={<StatusBadge status={proposal.status} />}
      actions={
        <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors">
          <Edit className="w-3.5 h-3.5" /> Review
        </button>
      }
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 gap-4">
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Proposed By</p>
            <p className="text-sm font-bold text-neutral-800">{proposal.proposed_by}</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Status</p>
            <p className="text-sm font-bold text-neutral-800 capitalize">{proposal.status}</p>
          </div>
        </div>
      )}
      {activeTab !== 'overview' && (
        <div className="py-12 text-center text-neutral-400 text-sm">
          {TABS.find(t => t.value === activeTab)?.label} — coming in next sprint
        </div>
      )}
    </DetailPageLayout>
  )
}
```

- [ ] **Step 4: Typecheck**

```bash
cd frontend && npm run typecheck
```

Resolve any type mismatches (e.g. enrollment fields — check `Enrollment` interface in `@/lib/api/enrollment.ts` for exact field names).

- [ ] **Step 5: Commit**

```bash
git add frontend/src/portals/internal/pages/detail/CourseDetail.tsx \
        frontend/src/portals/internal/pages/detail/EnrollmentDetail.tsx \
        frontend/src/portals/internal/pages/detail/ProposalDetail.tsx
git commit -m "feat(internal): add Academic entity detail pages — Course, Enrollment, Proposal"
```

---

## Task 9: Entity Detail Pages — Finance Domain

**Files:**
- Create: `frontend/src/portals/internal/pages/detail/PaymentDetail.tsx`
- Create: `frontend/src/portals/internal/pages/detail/BudgetDetail.tsx`
- Create: `frontend/src/portals/internal/pages/detail/ProfitSplitDetail.tsx`
- Create: `frontend/src/portals/internal/pages/detail/VoucherDetail.tsx`

All 4 use stub hooks (no backend `getById` endpoints). Use this pattern for each:

**PaymentDetail.tsx** — stub for `useInvoice(id)` (use `useInvoice` from `@/lib/api/finance` which takes invoice id):

```tsx
import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { CreditCard } from 'lucide-react'
import { useInvoice } from '@/lib/api/finance'
import DetailPageLayout from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const TABS = [
  { value: 'overview', label: 'Overview' },
  { value: 'activity', label: 'Activity' },
]

export default function PaymentDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: invoice, isLoading } = useInvoice(id!)
  const [activeTab, setActiveTab] = useState('overview')

  if (isLoading) return <LoadingSpinner size="lg" />
  if (!invoice) return (
    <div className="text-center py-20 text-neutral-400">
      <p>Payment not found.</p>
      <button onClick={() => navigate('/internal/payments')} className="mt-2 text-brand-600 text-sm">← Back to Payments</button>
    </div>
  )

  return (
    <DetailPageLayout
      breadcrumbs={[
        { label: 'Finance', to: '/internal/finance' },
        { label: 'Payments', to: '/internal/payments' },
        { label: `Invoice #${invoice.id.slice(0, 8)}` },
      ]}
      icon={<CreditCard className="w-5 h-5 text-brand-600" />}
      title={`Invoice #${invoice.id.slice(0, 8)}`}
      subtitle={`Enrollment: ${invoice.enrollment_id}`}
      status={<StatusBadge status={invoice.status} />}
      actions={null}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Total Amount</p>
            <p className="text-2xl font-bold text-neutral-800">Rp {invoice.total_amount?.toLocaleString('id-ID')}</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Status</p>
            <p className="text-lg font-bold capitalize">{invoice.status}</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Due Date</p>
            <p className="text-sm font-bold">{invoice.due_date ? new Date(invoice.due_date).toLocaleDateString() : '—'}</p>
          </div>
        </div>
      )}
      {activeTab !== 'overview' && (
        <div className="py-12 text-center text-neutral-400 text-sm">Activity — coming in next sprint</div>
      )}
    </DetailPageLayout>
  )
}
```

**BudgetDetail.tsx, ProfitSplitDetail.tsx, VoucherDetail.tsx** — use stub hook pattern (same as ProposalDetail). Each has:
- A local `useXxxDetail(id)` function returning mock data
- `DetailPageLayout` with correct breadcrumbs (Finance domain)
- Overview tab showing mock fields
- Non-overview tabs show "coming in next sprint"

Write BudgetDetail:
```tsx
import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { PiggyBank } from 'lucide-react'
import DetailPageLayout from '@/components/layout/DetailPageLayout'

const TABS = [
  { value: 'overview', label: 'Overview' },
  { value: 'transactions', label: 'Transactions' },
  { value: 'activity', label: 'Activity' },
]

function useBudgetDetail(id: string) {
  return { data: { id, batch_id: id, status: 'active', total_budget: 0, utilized: 0 }, isLoading: false }
}

export default function BudgetDetail() {
  const { id } = useParams<{ id: string }>()
  const { data } = useBudgetDetail(id!)
  const [activeTab, setActiveTab] = useState('overview')

  return (
    <DetailPageLayout
      breadcrumbs={[
        { label: 'Finance', to: '/internal/finance' },
        { label: 'Budget', to: '/internal/budget' },
        { label: `Budget ${id?.slice(0, 8)}` },
      ]}
      icon={<PiggyBank className="w-5 h-5 text-brand-600" />}
      title={`Budget ${id?.slice(0, 8)}`}
      subtitle={`Batch ID: ${data.batch_id}`}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      <div className="py-12 text-center text-neutral-400 text-sm">
        Full budget detail — available when batch ID is provided from Course detail page
      </div>
    </DetailPageLayout>
  )
}
```

Write ProfitSplitDetail and VoucherDetail following the same stub pattern:
- ProfitSplitDetail: breadcrumbs Finance → Profit Split → id, tabs: Overview | Breakdown | Activity
- VoucherDetail: breadcrumbs Finance → Vouchers → id, tabs: Overview | Usage History | Activity

- [ ] **Step 1: Create all 4 Finance detail pages** per the code above.

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```

Check `Invoice` fields — verify `total_amount`, `due_date`, `enrollment_id` exist in the `Invoice` interface in `@/lib/api/finance.ts`. Adjust field names if different.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/pages/detail/PaymentDetail.tsx \
        frontend/src/portals/internal/pages/detail/BudgetDetail.tsx \
        frontend/src/portals/internal/pages/detail/ProfitSplitDetail.tsx \
        frontend/src/portals/internal/pages/detail/VoucherDetail.tsx
git commit -m "feat(internal): add Finance entity detail pages — Payment, Budget, ProfitSplit, Voucher"
```

---

## Task 10: Entity Detail Pages — Operations Domain

**Files:**
- Create: `frontend/src/portals/internal/pages/detail/FranchiseDetail.tsx`
- Create: `frontend/src/portals/internal/pages/detail/PartnerDetail.tsx`
- Create: `frontend/src/portals/internal/pages/detail/NotificationDetail.tsx`

- [ ] **Step 1: Create FranchiseDetail.tsx** — uses `useFranchise(id)` from `@/lib/api/partnerships`:

```tsx
import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Building2, Edit } from 'lucide-react'
import { useFranchise } from '@/lib/api/partnerships'
import DetailPageLayout from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const TABS = [
  { value: 'overview', label: 'Overview' },
  { value: 'enrollments', label: 'Enrollments' },
  { value: 'payments', label: 'Payments' },
  { value: 'team', label: 'Team' },
  { value: 'activity', label: 'Activity' },
]

export default function FranchiseDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: franchise, isLoading } = useFranchise(id!)
  const [activeTab, setActiveTab] = useState('overview')

  if (isLoading) return <LoadingSpinner size="lg" />
  if (!franchise) return (
    <div className="text-center py-20 text-neutral-400">
      <p>Franchise not found.</p>
      <button onClick={() => navigate('/internal/franchises')} className="mt-2 text-brand-600 text-sm">← Back to Franchises</button>
    </div>
  )

  return (
    <DetailPageLayout
      breadcrumbs={[
        { label: 'Operations', to: '/internal/operations' },
        { label: 'Franchises', to: '/internal/franchises' },
        { label: franchise.name },
      ]}
      icon={<Building2 className="w-5 h-5 text-brand-600" />}
      title={franchise.name}
      subtitle={franchise.city ?? ''}
      status={<StatusBadge status={franchise.status} />}
      actions={
        <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors">
          <Edit className="w-3.5 h-3.5" /> Edit
        </button>
      }
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">City</p>
            <p className="text-sm font-bold text-neutral-800">{franchise.city ?? '—'}</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Status</p>
            <p className="text-sm font-bold capitalize">{franchise.status}</p>
          </div>
        </div>
      )}
      {activeTab !== 'overview' && (
        <div className="py-12 text-center text-neutral-400 text-sm">
          {TABS.find(t => t.value === activeTab)?.label} — coming in next sprint
        </div>
      )}
    </DetailPageLayout>
  )
}
```

- [ ] **Step 2: Create PartnerDetail.tsx** — uses `usePartner(id)` from `@/lib/api/partnerships`:

```tsx
import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Handshake, Edit } from 'lucide-react'
import { usePartner } from '@/lib/api/partnerships'
import DetailPageLayout from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const TABS = [
  { value: 'overview', label: 'Overview' },
  { value: 'courses', label: 'Courses' },
  { value: 'revenue', label: 'Revenue' },
  { value: 'activity', label: 'Activity' },
]

export default function PartnerDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: partner, isLoading } = usePartner(id!)
  const [activeTab, setActiveTab] = useState('overview')

  if (isLoading) return <LoadingSpinner size="lg" />
  if (!partner) return (
    <div className="text-center py-20 text-neutral-400">
      <p>Partner not found.</p>
      <button onClick={() => navigate('/internal/partners')} className="mt-2 text-brand-600 text-sm">← Back to Partners</button>
    </div>
  )

  return (
    <DetailPageLayout
      breadcrumbs={[
        { label: 'Operations', to: '/internal/operations' },
        { label: 'Partners', to: '/internal/partners' },
        { label: partner.name },
      ]}
      icon={<Handshake className="w-5 h-5 text-brand-600" />}
      title={partner.name}
      subtitle={partner.contact_email ?? ''}
      status={<StatusBadge status={partner.status} />}
      actions={
        <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors">
          <Edit className="w-3.5 h-3.5" /> Edit
        </button>
      }
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 gap-4">
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Contact Email</p>
            <p className="text-sm font-bold text-neutral-800">{partner.contact_email ?? '—'}</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Status</p>
            <p className="text-sm font-bold capitalize">{partner.status}</p>
          </div>
        </div>
      )}
      {activeTab !== 'overview' && (
        <div className="py-12 text-center text-neutral-400 text-sm">
          {TABS.find(t => t.value === activeTab)?.label} — coming in next sprint
        </div>
      )}
    </DetailPageLayout>
  )
}
```

- [ ] **Step 3: Create NotificationDetail.tsx** — stub hook (no getById):

```tsx
import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { Bell } from 'lucide-react'
import DetailPageLayout from '@/components/layout/DetailPageLayout'

const TABS = [
  { value: 'overview', label: 'Overview' },
  { value: 'send-history', label: 'Send History' },
  { value: 'activity', label: 'Activity' },
]

function useNotificationDetail(id: string) {
  return { data: { id, title: 'Notification Template', type: 'email', status: 'active' }, isLoading: false }
}

export default function NotificationDetail() {
  const { id } = useParams<{ id: string }>()
  const { data } = useNotificationDetail(id!)
  const [activeTab, setActiveTab] = useState('overview')

  return (
    <DetailPageLayout
      breadcrumbs={[
        { label: 'Operations', to: '/internal/operations' },
        { label: 'Notifications', to: '/internal/notifications' },
        { label: data.title },
      ]}
      icon={<Bell className="w-5 h-5 text-brand-600" />}
      title={data.title}
      subtitle={`Type: ${data.type}`}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      <div className="py-12 text-center text-neutral-400 text-sm">
        Notification template detail — stub until GET /notifications/:id backend endpoint is ready
      </div>
    </DetailPageLayout>
  )
}
```

- [ ] **Step 4: Typecheck**

```bash
cd frontend && npm run typecheck
```

Verify `Franchise` fields (`name`, `city`, `status`) and `Partner` fields (`name`, `contact_email`, `status`) against their interfaces in `@/lib/api/partnerships.ts`.

- [ ] **Step 5: Commit**

```bash
git add frontend/src/portals/internal/pages/detail/FranchiseDetail.tsx \
        frontend/src/portals/internal/pages/detail/PartnerDetail.tsx \
        frontend/src/portals/internal/pages/detail/NotificationDetail.tsx
git commit -m "feat(internal): add Operations entity detail pages — Franchise, Partner, Notification"
```

---

## Task 11: Entity Detail Pages — HR Domain

**Files:**
- Create: `frontend/src/portals/internal/pages/detail/StudentDetail.tsx`
- Create: `frontend/src/portals/internal/pages/detail/DepartmentDetail.tsx`
- Create: `frontend/src/portals/internal/pages/detail/TeamMemberDetail.tsx`

- [ ] **Step 1: Create StudentDetail.tsx** — uses `useStudent(id)` from `@/lib/api/identity`:

```tsx
import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { GraduationCap, Edit } from 'lucide-react'
import { useStudent } from '@/lib/api/identity'
import DetailPageLayout from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const TABS = [
  { value: 'overview', label: 'Overview' },
  { value: 'enrollments', label: 'Enrollments' },
  { value: 'certificates', label: 'Certificates' },
  { value: 'payments', label: 'Payments' },
  { value: 'activity', label: 'Activity' },
]

export default function StudentDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: student, isLoading } = useStudent(id!)
  const [activeTab, setActiveTab] = useState('overview')

  if (isLoading) return <LoadingSpinner size="lg" />
  if (!student) return (
    <div className="text-center py-20 text-neutral-400">
      <p>Student not found.</p>
      <button onClick={() => navigate('/internal/students')} className="mt-2 text-brand-600 text-sm">← Back to Students</button>
    </div>
  )

  return (
    <DetailPageLayout
      breadcrumbs={[
        { label: 'HR', to: '/internal/hr' },
        { label: 'Students', to: '/internal/students' },
        { label: student.full_name },
      ]}
      icon={<GraduationCap className="w-5 h-5 text-brand-600" />}
      title={student.full_name}
      subtitle={student.email}
      actions={
        <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors">
          <Edit className="w-3.5 h-3.5" /> Edit
        </button>
      }
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Email</p>
            <p className="text-sm font-bold text-neutral-800">{student.email}</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">Phone</p>
            <p className="text-sm font-bold text-neutral-800">{student.phone ?? '—'}</p>
          </div>
          <div className="rounded-xl border border-neutral-100 bg-white p-4">
            <p className="text-xs text-neutral-500 mb-1">City</p>
            <p className="text-sm font-bold text-neutral-800">{student.city ?? '—'}</p>
          </div>
        </div>
      )}
      {activeTab !== 'overview' && (
        <div className="py-12 text-center text-neutral-400 text-sm">
          {TABS.find(t => t.value === activeTab)?.label} — coming in next sprint
        </div>
      )}
    </DetailPageLayout>
  )
}
```

- [ ] **Step 2: Create DepartmentDetail.tsx** — stub hook (no `useDepartment(id)`):

```tsx
import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { Building, Edit } from 'lucide-react'
import DetailPageLayout from '@/components/layout/DetailPageLayout'

const TABS = [
  { value: 'overview', label: 'Overview' },
  { value: 'team-members', label: 'Team Members' },
  { value: 'courses', label: 'Courses' },
  { value: 'budget', label: 'Budget' },
  { value: 'activity', label: 'Activity' },
]

function useDepartmentDetail(id: string) {
  return { data: { id, name: 'Department', code: id.slice(0, 6).toUpperCase(), status: 'active' }, isLoading: false }
}

export default function DepartmentDetail() {
  const { id } = useParams<{ id: string }>()
  const { data } = useDepartmentDetail(id!)
  const [activeTab, setActiveTab] = useState('overview')

  return (
    <DetailPageLayout
      breadcrumbs={[
        { label: 'HR', to: '/internal/hr' },
        { label: 'Departments', to: '/internal/departments' },
        { label: data.name },
      ]}
      icon={<Building className="w-5 h-5 text-brand-600" />}
      title={data.name}
      subtitle={`Code: ${data.code}`}
      actions={
        <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors">
          <Edit className="w-3.5 h-3.5" /> Edit
        </button>
      }
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      <div className="py-12 text-center text-neutral-400 text-sm">
        Department detail — stub until GET /departments/:id backend endpoint is ready
      </div>
    </DetailPageLayout>
  )
}
```

- [ ] **Step 3: Create TeamMemberDetail.tsx** — stub hook (no `useTeamMember(id)`):

```tsx
import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { Users, Edit } from 'lucide-react'
import DetailPageLayout from '@/components/layout/DetailPageLayout'

const TABS = [
  { value: 'overview', label: 'Overview' },
  { value: 'enrollments', label: 'Enrollments as Facilitator' },
  { value: 'activity', label: 'Activity' },
]

function useTeamMemberDetail(id: string) {
  return { data: { id, full_name: 'Team Member', role: '—', email: '—' }, isLoading: false }
}

export default function TeamMemberDetail() {
  const { id } = useParams<{ id: string }>()
  const { data } = useTeamMemberDetail(id!)
  const [activeTab, setActiveTab] = useState('overview')

  return (
    <DetailPageLayout
      breadcrumbs={[
        { label: 'HR', to: '/internal/hr' },
        { label: 'Team Members', to: '/internal/team-members' },
        { label: data.full_name },
      ]}
      icon={<Users className="w-5 h-5 text-brand-600" />}
      title={data.full_name}
      subtitle={data.email}
      actions={
        <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors">
          <Edit className="w-3.5 h-3.5" /> Edit
        </button>
      }
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      <div className="py-12 text-center text-neutral-400 text-sm">
        Team member detail — stub until GET /team-members/:id backend endpoint is ready
      </div>
    </DetailPageLayout>
  )
}
```

- [ ] **Step 4: Typecheck**

```bash
cd frontend && npm run typecheck
```

Verify `Student` fields (`full_name`, `email`, `phone`, `city`) in `@/lib/api/identity.ts`.

- [ ] **Step 5: Commit**

```bash
git add frontend/src/portals/internal/pages/detail/StudentDetail.tsx \
        frontend/src/portals/internal/pages/detail/DepartmentDetail.tsx \
        frontend/src/portals/internal/pages/detail/TeamMemberDetail.tsx
git commit -m "feat(internal): add HR entity detail pages — Student, Department, TeamMember"
```

---

## Task 12: List Pages — Add Row Click Navigation

**Files:** All 10 list pages with DataTable usage.

For each page: import `useNavigate`, pass `onRowClick` to DataTable.

- [ ] **Step 1: Update Courses.tsx**

Add to imports: `import { useNavigate } from 'react-router-dom'`

Inside the component: `const navigate = useNavigate()`

On the `<DataTable>` element, add:
```tsx
onRowClick={(row: Course) => navigate(`/internal/courses/${row.id}`)}
```

- [ ] **Step 2: Update Students.tsx** — `onRowClick={(row) => navigate(\`/internal/students/${row.id}\`)}`

- [ ] **Step 3: Update Enrollments.tsx** — `onRowClick={(row) => navigate(\`/internal/enrollments/${row.id}\`)}`

- [ ] **Step 4: Update Departments.tsx** — `onRowClick={(row) => navigate(\`/internal/departments/${row.id}\`)}`

- [ ] **Step 5: Update TeamMembers.tsx** — `onRowClick={(row) => navigate(\`/internal/team-members/${row.id}\`)}`

- [ ] **Step 6: Update Proposals.tsx** — `onRowClick={(row) => navigate(\`/internal/proposals/${row.id}\`)}`

- [ ] **Step 7: Update Partners.tsx** — `onRowClick={(row) => navigate(\`/internal/partners/${row.id}\`)}`

- [ ] **Step 8: Update Franchises.tsx** — `onRowClick={(row) => navigate(\`/internal/franchises/${row.id}\`)}`

- [ ] **Step 9: Update Vouchers.tsx** — `onRowClick={(row) => navigate(\`/internal/vouchers/${row.id}\`)}`

- [ ] **Step 10: Update Payments.tsx** — Payments uses invoice list. Find the DataTable and add:
```tsx
onRowClick={(row) => navigate(`/internal/payments/${row.id}`)}
```

- [ ] **Step 11: Update Notifications.tsx** — `onRowClick={(row) => navigate(\`/internal/notifications/${row.id}\`)}`

- [ ] **Step 12: Typecheck**

```bash
cd frontend && npm run typecheck
```

- [ ] **Step 13: Commit**

```bash
git add frontend/src/portals/internal/pages/
git commit -m "feat(internal): add row click navigation to all list pages → detail pages"
```

---

## Task 13: App.tsx Routes + Final Verification

**Files:**
- Modify: `frontend/src/App.tsx`

- [ ] **Step 1: Add all imports to App.tsx**

```tsx
// Domain overviews
import AcademicOverview from '@/portals/internal/pages/domains/AcademicOverview'
import FinanceOverview from '@/portals/internal/pages/domains/FinanceOverview'
import OperationsOverview from '@/portals/internal/pages/domains/OperationsOverview'
import HROverview from '@/portals/internal/pages/domains/HROverview'
// Detail pages
import CourseDetail from '@/portals/internal/pages/detail/CourseDetail'
import StudentDetail from '@/portals/internal/pages/detail/StudentDetail'
import EnrollmentDetail from '@/portals/internal/pages/detail/EnrollmentDetail'
import DepartmentDetail from '@/portals/internal/pages/detail/DepartmentDetail'
import TeamMemberDetail from '@/portals/internal/pages/detail/TeamMemberDetail'
import ProposalDetail from '@/portals/internal/pages/detail/ProposalDetail'
import PartnerDetail from '@/portals/internal/pages/detail/PartnerDetail'
import FranchiseDetail from '@/portals/internal/pages/detail/FranchiseDetail'
import VoucherDetail from '@/portals/internal/pages/detail/VoucherDetail'
import PaymentDetail from '@/portals/internal/pages/detail/PaymentDetail'
import BudgetDetail from '@/portals/internal/pages/detail/BudgetDetail'
import ProfitSplitDetail from '@/portals/internal/pages/detail/ProfitSplitDetail'
import NotificationDetail from '@/portals/internal/pages/detail/NotificationDetail'
```

- [ ] **Step 2: Add routes inside the internal portal `<Route path="/internal">` block**

```tsx
{/* Domain overviews */}
<Route path="academic" element={<AcademicOverview />} />
<Route path="finance" element={<FinanceOverview />} />
<Route path="operations" element={<OperationsOverview />} />
<Route path="hr" element={<HROverview />} />
{/* Entity detail pages */}
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

- [ ] **Step 3: Typecheck**

```bash
cd frontend && npm run typecheck
```

Expected: 0 errors.

- [ ] **Step 4: Final browser verification**

```bash
cd frontend && npm run dev
```

Check each flow:
1. Log in as `vernonedu_admin` — all 4 domain tabs visible
2. Click **Academic** → overview page with KPI cards + quick access grid
3. Click **Courses** in secondary bar → courses list
4. Click any course row → `/internal/courses/:id` with Overview/Enrollments/Proposals/Budget/Activity tabs
5. Click back breadcrumb → returns to Courses list
6. Click **Finance** → Finance overview
7. Click **HR** → HR overview, click row in Students → student detail
8. Click **Operations** → Operations overview, click row in Franchises → franchise detail
9. Log in as `finance` role — Finance domain visible, Operations/HR hidden (role-filtered)
10. Dashboard link → secondary bar disappears

- [ ] **Step 5: Final commit**

```bash
git add frontend/src/App.tsx
git commit -m "feat(internal): wire 17 new routes — domain overviews + entity detail pages"
```

---

## Self-Review

**Spec coverage check:**
- ✅ Domain tabs (Academic, Finance, Operations, HR) in top bar — Task 2, 3, 4, 5
- ✅ Dashboard standalone — Task 5 (dashboardTo prop)
- ✅ Secondary bar with domain sub-pages — Task 3
- ✅ Role filtering on domain tabs + sub-page items — Task 2 (DomainGroup allowedRoles)
- ✅ Domain overview pages with KPI + quick access — Task 7
- ✅ Entity detail pages for all 13 entities — Tasks 8–11
- ✅ Full page + tabs layout — Task 6 (DetailPageLayout)
- ✅ Breadcrumb navigation — Task 6 (included in DetailPageLayout)
- ✅ List → detail navigation — Task 12 (onRowClick)
- ✅ Routes wired — Task 13
- ✅ SubNavBar sticky offset updated for 3-level nav — Task 4 (topOffset prop) + Task 5

**Placeholder scan:** No TBDs. Stub hooks clearly marked with comment about which backend endpoint is needed.

**Type consistency:**
- `DomainGroup` defined in Task 2, used in Tasks 3, 4, 5
- `DetailPageLayout` props defined in Task 6, used consistently in Tasks 8–11
- `onRowClick` prop added in Task 1, used in Task 12
- `topOffset` prop added in Task 4, passed in Task 5
