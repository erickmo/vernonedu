# Frontend Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign all three portals (Internal, Student, Franchise) to use a unified double-nav layout (TopNav1 + SubNav2) with card/flat page styling — all three portals responsive, modern, consistent.

**Architecture:** Shared layout primitives (`TopNavBar`, `SubNavContext`/`SubNavBar`) consumed by per-portal layout files. Pages inject sub-nav tabs via `useSubNav` hook. No API or routing changes.

**Tech Stack:** React 18, TypeScript, TailwindCSS 3, Radix UI, Lucide React, React Router 6, `clsx`/`tailwind-merge` via `cn`.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `index.html` | Add Plus Jakarta Sans + DM Mono Google Fonts |
| Modify | `tailwind.config.ts` | Update fontFamily.sans |
| Modify | `src/index.css` | Add `--nav-height` / `--subnav-height` CSS vars |
| Create | `src/components/layout/SubNavContext.tsx` | Context, `SubNavProvider`, `useSubNav`, `useSubNavState`, `SubNavBar` |
| Create | `src/components/layout/TopNavBar.tsx` | Nav1 — logo + main nav + notification + avatar |
| Modify | `src/portals/internal/InternalPortal.tsx` | Replace sidebar with TopNavBar + SubNavBar |
| Modify | `src/portals/student/StudentPortal.tsx` | Replace nav with TopNavBar + SubNavBar |
| Modify | `src/portals/franchise/FranchisePortal.tsx` | Replace sidebar with TopNavBar |
| Modify | `src/portals/internal/pages/Dashboard.tsx` | Improved KPI cards + styled activity feed |
| Modify | `src/portals/internal/pages/Students.tsx` | Pill filter bar + avatar column |
| Modify | `src/portals/internal/pages/Enrollments.tsx` | useSubNav status tabs |
| Modify | `src/portals/internal/pages/Payments.tsx` | useSubNav pending/all tabs |
| Modify | `src/portals/internal/pages/Courses.tsx` | Styled header + dialog |
| Modify | `src/portals/student/pages/CourseCatalog.tsx` | Improved card grid styling |
| Modify | `src/portals/student/pages/MyEnrollments.tsx` | useSubNav tabs |
| Modify | `src/portals/student/pages/Certificates.tsx` | 3-col grid + improved card |
| Modify | `src/portals/student/pages/Profile.tsx` | Two-col layout |
| Modify | `src/portals/student/pages/Dashboard.tsx` | Remove max-w hero constraint |
| Modify | `src/portals/franchise/pages/Dashboard.tsx` | Minor styling refresh |

---

## Task 1: Fonts + CSS foundation

**Files:**
- Modify: `index.html`
- Modify: `tailwind.config.ts`
- Modify: `src/index.css`

- [ ] **Step 1: Update `index.html` to load Plus Jakarta Sans + DM Mono**

Replace the existing `<link>` font tags with:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet" />
    <title>VernonEdu</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 2: Update `tailwind.config.ts` — fontFamily**

In `theme.extend.fontFamily`, change `sans`:

```ts
fontFamily: {
  sans: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
  mono: ['"DM Mono"', 'ui-monospace', 'monospace'],
},
```

- [ ] **Step 3: Update `src/index.css` — add nav-height CSS vars**

Add inside `:root { ... }` (after existing vars):

```css
--nav-height: 3.5rem;
--subnav-height: 2.75rem;
```

- [ ] **Step 4: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add index.html tailwind.config.ts src/index.css && git commit -m "style: switch to Plus Jakarta Sans + DM Mono, add nav height vars"
```

---

## Task 2: Create SubNavContext

**Files:**
- Create: `src/components/layout/SubNavContext.tsx`

- [ ] **Step 1: Create `src/components/layout/` directory and `SubNavContext.tsx`**

```bash
mkdir -p /Users/erickmo/Desktop/Project/vernonedu2/frontend/src/components/layout
```

Create `src/components/layout/SubNavContext.tsx`:

```tsx
import { createContext, useContext, useEffect, useRef, useState, ReactNode } from 'react'
import { cn } from '@/lib/utils/cn'

export interface SubNavItem {
  label: string
  value: string
}

interface SubNavState {
  items: SubNavItem[]
  active: string
  onChange: (value: string) => void
}

interface SubNavContextValue {
  state: SubNavState | null
  setState: (s: SubNavState | null) => void
}

const SubNavContext = createContext<SubNavContextValue>({
  state: null,
  setState: () => {},
})

export function SubNavProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<SubNavState | null>(null)
  return (
    <SubNavContext.Provider value={{ state, setState }}>
      {children}
    </SubNavContext.Provider>
  )
}

/**
 * Called by pages to register their sub-nav tabs.
 * `items` must be a stable reference (module-level constant or useMemo).
 * `onChange` from useState is always stable.
 */
export function useSubNav(
  items: SubNavItem[],
  active: string,
  onChange: (value: string) => void,
) {
  const { setState } = useContext(SubNavContext)
  const onChangeRef = useRef(onChange)
  onChangeRef.current = onChange

  useEffect(() => {
    setState({ items, active, onChange: (v) => onChangeRef.current(v) })
    return () => setState(null)
  }, [active, setState, items])
}

export function useSubNavState(): SubNavState | null {
  return useContext(SubNavContext).state
}

/** Rendered by portal layouts between Nav1 and main content. */
export function SubNavBar() {
  const state = useSubNavState()
  if (!state || state.items.length === 0) return null

  return (
    <div className="sticky top-14 z-40 h-11 bg-neutral-50 border-b border-neutral-100 flex items-center px-6 md:px-8 gap-0.5 overflow-x-auto scrollbar-none">
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

- [ ] **Step 2: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/components/layout/SubNavContext.tsx && git commit -m "feat(layout): add SubNavContext for page-injected sub-navigation tabs"
```

---

## Task 3: Create TopNavBar

**Files:**
- Create: `src/components/layout/TopNavBar.tsx`

- [ ] **Step 1: Create `src/components/layout/TopNavBar.tsx`**

```tsx
import { useState } from 'react'
import { NavLink, Link } from 'react-router-dom'
import { Bell, ChevronDown, GraduationCap, LogOut, Menu, X } from 'lucide-react'
import * as DropdownMenu from '@radix-ui/react-dropdown-menu'
import { cn } from '@/lib/utils/cn'

export interface NavItem {
  to: string
  label: string
  end?: boolean
}

interface TopNavBarProps {
  mainNav: NavItem[]
  user: { id: string; name: string; role: string; email: string } | null
  unreadCount?: number
  onLogout: () => void
  avatarClass?: string
}

export default function TopNavBar({
  mainNav,
  user,
  unreadCount = 0,
  onLogout,
  avatarClass = 'bg-brand-100 text-brand-700',
}: TopNavBarProps) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const initial = user?.name?.charAt(0).toUpperCase() ?? '?'

  return (
    <>
      <header className="sticky top-0 z-50 h-14 bg-white/95 backdrop-blur-sm border-b border-neutral-100 flex items-center gap-4 px-6 md:px-8">
        {/* Logo */}
        <Link to="/" className="flex items-center gap-2.5 shrink-0 mr-2">
          <div className="w-8 h-8 rounded-lg bg-brand-600 flex items-center justify-center">
            <GraduationCap className="w-4.5 h-4.5 text-white" />
          </div>
          <span className="font-bold text-neutral-900 text-sm tracking-tight">VernonEdu</span>
        </Link>

        {/* Main nav — desktop */}
        <nav className="hidden md:flex items-center gap-0.5 flex-1">
          {mainNav.map((item) => (
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

        {/* Right side */}
        <div className="flex items-center gap-1 ml-auto">
          <button className="relative p-2 rounded-lg hover:bg-neutral-100 transition-colors">
            <Bell className="w-5 h-5 text-neutral-500" />
            {unreadCount > 0 && (
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full ring-2 ring-white" />
            )}
          </button>

          <DropdownMenu.Root>
            <DropdownMenu.Trigger className="flex items-center gap-2 px-2 py-1.5 rounded-lg hover:bg-neutral-100 transition-colors outline-none">
              <div
                className={cn(
                  'w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold shrink-0',
                  avatarClass,
                )}
              >
                {initial}
              </div>
              <div className="hidden sm:block text-left leading-tight">
                <p className="text-xs font-semibold text-neutral-800">{user?.name}</p>
                <p className="text-[11px] text-neutral-500 capitalize">{user?.role}</p>
              </div>
              <ChevronDown className="w-3.5 h-3.5 text-neutral-400 hidden sm:block" />
            </DropdownMenu.Trigger>

            <DropdownMenu.Portal>
              <DropdownMenu.Content
                align="end"
                sideOffset={6}
                className="z-50 min-w-[200px] bg-white rounded-xl shadow-lg border border-neutral-100 p-1.5 animate-in fade-in-0 zoom-in-95 duration-100"
              >
                <div className="px-3 py-2">
                  <p className="text-xs font-semibold text-neutral-800">{user?.name}</p>
                  <p className="text-[11px] text-neutral-500 truncate">{user?.email}</p>
                </div>
                <DropdownMenu.Separator className="my-1 -mx-1.5 border-t border-neutral-100" />
                <DropdownMenu.Item
                  onClick={onLogout}
                  className="flex items-center gap-2 px-3 py-2 text-sm text-red-600 rounded-lg cursor-pointer hover:bg-red-50 outline-none"
                >
                  <LogOut className="w-4 h-4" />
                  Sign out
                </DropdownMenu.Item>
              </DropdownMenu.Content>
            </DropdownMenu.Portal>
          </DropdownMenu.Root>

          {/* Mobile hamburger */}
          <button
            onClick={() => setMobileOpen((v) => !v)}
            className="md:hidden p-2 rounded-lg hover:bg-neutral-100 transition-colors"
          >
            {mobileOpen ? (
              <X className="w-5 h-5 text-neutral-600" />
            ) : (
              <Menu className="w-5 h-5 text-neutral-600" />
            )}
          </button>
        </div>
      </header>

      {/* Mobile nav drawer */}
      {mobileOpen && (
        <div className="md:hidden fixed inset-x-0 top-14 z-40 bg-white border-b border-neutral-100 shadow-lg px-4 py-3 space-y-0.5">
          {mainNav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              onClick={() => setMobileOpen(false)}
              className={({ isActive }) =>
                cn(
                  'flex items-center px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-brand-50 text-brand-700'
                    : 'text-neutral-600 hover:bg-neutral-50 hover:text-neutral-900',
                )
              }
            >
              {item.label}
            </NavLink>
          ))}
        </div>
      )}
    </>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/components/layout/TopNavBar.tsx && git commit -m "feat(layout): add TopNavBar shared nav1 primitive with mobile drawer"
```

---

## Task 4: Refactor InternalPortal

**Files:**
- Modify: `src/portals/internal/InternalPortal.tsx`

- [ ] **Step 1: Replace sidebar with TopNavBar + SubNavBar**

Overwrite `src/portals/internal/InternalPortal.tsx`:

```tsx
import { Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import { useRBAC } from '@/lib/auth/useRBAC'
import { useUnreadCount } from '@/lib/api/platform'
import { SubNavProvider, SubNavBar, useSubNavState } from '@/components/layout/SubNavContext'
import TopNavBar, { NavItem } from '@/components/layout/TopNavBar'

const NAV_ITEMS: NavItem[] = [
  { to: '/internal', label: 'Dashboard', end: true },
  { to: '/internal/enrollments', label: 'Enrollments' },
  { to: '/internal/payments', label: 'Payments' },
  { to: '/internal/courses', label: 'Courses' },
  { to: '/internal/students', label: 'Students' },
]

function InternalLayout() {
  const { user, logout } = useAuth()
  const unread = useUnreadCount()
  const navigate = useNavigate()
  const subNavState = useSubNavState()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const hasSubNav = subNavState && subNavState.items.length > 0

  return (
    <div className="min-h-screen bg-neutral-50">
      <TopNavBar
        mainNav={NAV_ITEMS}
        user={user}
        unreadCount={unread}
        onLogout={handleLogout}
        avatarClass="bg-brand-100 text-brand-700"
      />
      <SubNavBar />
      <main
        className="px-6 md:px-8 lg:px-12 py-6"
        style={hasSubNav ? { paddingTop: '1.5rem' } : undefined}
      >
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

Note: `useRBAC` is imported from existing code — keep the import even if not used in this layout, to preserve RBAC functionality used by individual pages.

- [ ] **Step 2: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors. If `useRBAC` is unused, remove that import.

- [ ] **Step 3: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/internal/InternalPortal.tsx && git commit -m "refactor(internal): replace sidebar with TopNavBar + SubNavBar layout"
```

---

## Task 5: Refactor StudentPortal

**Files:**
- Modify: `src/portals/student/StudentPortal.tsx`

- [ ] **Step 1: Overwrite `src/portals/student/StudentPortal.tsx`**

```tsx
import { Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import { useUnreadCount } from '@/lib/api/platform'
import { SubNavProvider, SubNavBar } from '@/components/layout/SubNavContext'
import TopNavBar, { NavItem } from '@/components/layout/TopNavBar'

const NAV_ITEMS: NavItem[] = [
  { to: '/student', label: 'Dashboard', end: true },
  { to: '/student/catalog', label: 'Course Catalog' },
  { to: '/student/enrollments', label: 'My Enrollments' },
  { to: '/student/certificates', label: 'Certificates' },
  { to: '/student/profile', label: 'Profile' },
]

function StudentLayout() {
  const { user, logout } = useAuth()
  const unread = useUnreadCount()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-neutral-50">
      <TopNavBar
        mainNav={NAV_ITEMS}
        user={user}
        unreadCount={unread}
        onLogout={handleLogout}
        avatarClass="bg-emerald-100 text-emerald-700"
      />
      <SubNavBar />
      <main className="px-6 md:px-8 lg:px-12 py-6">
        <Outlet />
      </main>
    </div>
  )
}

export default function StudentPortal() {
  return (
    <SubNavProvider>
      <StudentLayout />
    </SubNavProvider>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/student/StudentPortal.tsx && git commit -m "refactor(student): replace nav with TopNavBar + SubNavBar layout"
```

---

## Task 6: Refactor FranchisePortal

**Files:**
- Modify: `src/portals/franchise/FranchisePortal.tsx`

- [ ] **Step 1: Overwrite `src/portals/franchise/FranchisePortal.tsx`**

```tsx
import { Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import { SubNavProvider, SubNavBar } from '@/components/layout/SubNavContext'
import TopNavBar, { NavItem } from '@/components/layout/TopNavBar'

const NAV_ITEMS: NavItem[] = [
  { to: '/franchise', label: 'Dashboard', end: true },
]

function FranchiseLayout() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-neutral-50">
      <TopNavBar
        mainNav={NAV_ITEMS}
        user={user}
        unreadCount={0}
        onLogout={handleLogout}
        avatarClass="bg-violet-100 text-violet-700"
      />
      <SubNavBar />
      <main className="px-6 md:px-8 lg:px-12 py-6">
        <Outlet />
      </main>
    </div>
  )
}

export default function FranchisePortal() {
  return (
    <SubNavProvider>
      <FranchiseLayout />
    </SubNavProvider>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/franchise/FranchisePortal.tsx && git commit -m "refactor(franchise): replace sidebar with TopNavBar layout"
```

---

## Task 7: Internal Dashboard page

**Files:**
- Modify: `src/portals/internal/pages/Dashboard.tsx`

- [ ] **Step 1: Overwrite `src/portals/internal/pages/Dashboard.tsx`**

```tsx
import { GraduationCap, Clock, AlertTriangle, BookOpen, ArrowRight } from 'lucide-react'
import { Link } from 'react-router-dom'
import { useEnrollments } from '@/lib/api/enrollment'
import { useInvoices } from '@/lib/api/finance'
import { useCourses } from '@/lib/api/catalog'
import { formatDate } from '@/lib/utils/format'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

interface KPICardProps {
  title: string
  value: number | string
  icon: typeof GraduationCap
  bgClass: string
  iconClass: string
  loading?: boolean
}

function KPICard({ title, value, icon: Icon, bgClass, iconClass, loading }: KPICardProps) {
  return (
    <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <p className="text-xs font-medium text-neutral-500 uppercase tracking-wide">{title}</p>
          {loading ? (
            <div className="h-9 w-20 bg-neutral-100 rounded-lg animate-pulse mt-2" />
          ) : (
            <p className="text-3xl font-bold text-neutral-900 mt-1.5 font-mono tabular-nums">{value}</p>
          )}
        </div>
        <div className={`w-11 h-11 rounded-xl flex items-center justify-center shrink-0 ${bgClass}`}>
          <Icon className={`w-5 h-5 ${iconClass}`} />
        </div>
      </div>
    </div>
  )
}

export default function InternalDashboard() {
  const { data: activeEnrollments, isLoading: l1 } = useEnrollments({ status: 'confirmed', limit: 1 })
  const { data: pendingEnrollments, isLoading: l2 } = useEnrollments({ status: 'pending', limit: 1 })
  const { data: overdueInvoices, isLoading: l3 } = useInvoices({ status: 'overdue', limit: 1 })
  const { data: openCourses, isLoading: l4 } = useCourses({ status: 'active', limit: 1 })
  const { data: recentEnrollments, isLoading: loadingRecent } = useEnrollments({ limit: 8 })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Dashboard</h1>
          <p className="text-sm text-neutral-500 mt-0.5">Operations overview</p>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <KPICard
          title="Active Enrollments"
          value={activeEnrollments?.total ?? 0}
          icon={GraduationCap}
          bgClass="bg-brand-50"
          iconClass="text-brand-600"
          loading={l1}
        />
        <KPICard
          title="Pending Confirmations"
          value={pendingEnrollments?.total ?? 0}
          icon={Clock}
          bgClass="bg-amber-50"
          iconClass="text-amber-600"
          loading={l2}
        />
        <KPICard
          title="Overdue Invoices"
          value={overdueInvoices?.total ?? 0}
          icon={AlertTriangle}
          bgClass="bg-red-50"
          iconClass="text-red-600"
          loading={l3}
        />
        <KPICard
          title="Active Courses"
          value={openCourses?.total ?? 0}
          icon={BookOpen}
          bgClass="bg-emerald-50"
          iconClass="text-emerald-600"
          loading={l4}
        />
      </div>

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4 border-b border-neutral-100">
          <div>
            <h2 className="font-semibold text-neutral-900">Recent Enrollments</h2>
            <p className="text-xs text-neutral-500 mt-0.5">Latest activity</p>
          </div>
          <Link
            to="/internal/enrollments"
            className="inline-flex items-center gap-1 text-sm font-medium text-brand-600 hover:text-brand-700 transition-colors"
          >
            View all <ArrowRight className="w-3.5 h-3.5" />
          </Link>
        </div>

        {loadingRecent ? (
          <LoadingSpinner className="py-12" />
        ) : (
          <ul className="divide-y divide-neutral-50">
            {(recentEnrollments?.data ?? []).map((e) => (
              <li
                key={e.id}
                className="flex items-center justify-between px-5 py-3.5 hover:bg-neutral-50/60 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-brand-50 flex items-center justify-center text-xs font-bold text-brand-700">
                    {(e.student_id ?? '?').charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <p className="text-sm font-medium text-neutral-800">{e.student_id}</p>
                    <p className="text-xs text-neutral-500">Batch {e.batch_id}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-xs text-neutral-400">{formatDate(e.enrolled_at)}</span>
                  <span
                    className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${
                      e.status === 'pending'
                        ? 'bg-amber-50 text-amber-700'
                        : e.status === 'confirmed'
                          ? 'bg-emerald-50 text-emerald-700'
                          : 'bg-neutral-100 text-neutral-500'
                    }`}
                  >
                    {e.status}
                  </span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/internal/pages/Dashboard.tsx && git commit -m "style(internal): redesign dashboard KPI cards and activity feed"
```

---

## Task 8: Internal Students page

**Files:**
- Modify: `src/portals/internal/pages/Students.tsx`

- [ ] **Step 1: Read the full current `Students.tsx`**

```bash
cat /Users/erickmo/Desktop/Project/vernonedu2/frontend/src/portals/internal/pages/Students.tsx
```

- [ ] **Step 2: Replace filter bar + add avatar column**

Keep ALL existing logic (form, mutation, dialog, `createStudent`). Only change:
1. The filter bar above the table — replace with pill-style source buttons + search input
2. Add avatar initials as first column in `COLUMNS`
3. Update `PageHeader` actions button style

Replace the full file with:

```tsx
import { useState } from 'react'
import { Plus, Search } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useStudents, useCreateStudent, type Student } from '@/lib/api/identity'
import { formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const studentSchema = z.object({
  name: z.string().min(2, 'Name required'),
  email: z.string().email('Valid email required'),
  phone: z.string().min(8, 'Phone required'),
  source: z.enum(['b2c', 'b2b']),
})

type StudentForm = z.infer<typeof studentSchema>

const SOURCE_FILTERS = [
  { label: 'All', value: '' },
  { label: 'B2C', value: 'b2c' },
  { label: 'B2B', value: 'b2b' },
] as const

const LIMIT = 15

export default function Students() {
  const [page, setPage] = useState(1)
  const [sourceFilter, setSourceFilter] = useState<'' | 'b2c' | 'b2b'>('')
  const [search, setSearch] = useState('')
  const [open, setOpen] = useState(false)

  const { data, isLoading } = useStudents({
    source: sourceFilter || undefined,
    search: search || undefined,
    page,
    limit: LIMIT,
  })

  const createStudent = useCreateStudent()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<StudentForm>({
    resolver: zodResolver(studentSchema),
    defaultValues: { source: 'b2c' },
  })

  const onSubmit = async (form: StudentForm) => {
    try {
      await createStudent.mutateAsync(form)
      toast.success('Student created')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to create student')
    }
  }

  const COLUMNS: Column<Student>[] = [
    {
      header: '',
      accessor: 'name',
      className: 'w-10',
      cell: (row) => (
        <div className="w-8 h-8 rounded-full bg-brand-50 flex items-center justify-center text-xs font-bold text-brand-700">
          {row.name.charAt(0).toUpperCase()}
        </div>
      ),
    },
    { header: 'Name', accessor: 'name' },
    { header: 'Email', accessor: 'email' },
    { header: 'Phone', accessor: 'phone' },
    {
      header: 'Source',
      accessor: 'source',
      cell: (row) => (
        <span
          className={cn(
            'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
            row.source === 'b2b'
              ? 'bg-violet-50 text-violet-700'
              : 'bg-brand-50 text-brand-700',
          )}
        >
          {row.source.toUpperCase()}
        </span>
      ),
    },
    {
      header: 'Joined',
      accessor: 'created_at',
      cell: (row) => (
        <span className="text-xs text-neutral-500 font-mono">{formatDate(row.created_at)}</span>
      ),
    },
  ]

  return (
    <div className="space-y-5">
      <PageHeader
        title="Students"
        subtitle="Manage registered students"
        actions={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors shadow-sm"
          >
            <Plus className="w-4 h-4" />
            Add Student
          </button>
        }
      />

      {/* Filter bar */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            placeholder="Search by name or email…"
            className="w-full pl-9 pr-4 py-2 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
          />
        </div>
        <div className="flex items-center gap-1 bg-white border border-neutral-200 rounded-lg p-1">
          {SOURCE_FILTERS.map((f) => (
            <button
              key={f.value}
              onClick={() => { setSourceFilter(f.value as typeof sourceFilter); setPage(1) }}
              className={cn(
                'px-3 py-1 text-sm font-medium rounded-md transition-colors',
                sourceFilter === f.value
                  ? 'bg-brand-600 text-white shadow-sm'
                  : 'text-neutral-600 hover:bg-neutral-50',
              )}
            >
              {f.label}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={COLUMNS}
          data={data?.data ?? []}
          loading={isLoading}
          pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
          onPageChange={setPage}
          rowKey={(row) => row.id}
        />
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 animate-in fade-in-0" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-2xl shadow-xl p-6 animate-in fade-in-0 zoom-in-95">
            <Dialog.Title className="text-lg font-bold text-neutral-900 mb-5">Add Student</Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              {(['name', 'email', 'phone'] as const).map((field) => (
                <div key={field} className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700 capitalize">{field}</label>
                  <input
                    {...register(field)}
                    type={field === 'email' ? 'email' : field === 'phone' ? 'tel' : 'text'}
                    className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                  {errors[field] && (
                    <p className="text-xs text-red-600">{errors[field]?.message}</p>
                  )}
                </div>
              ))}

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-neutral-700">Source</label>
                <select
                  {...register('source')}
                  className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
                >
                  <option value="b2c">B2C</option>
                  <option value="b2b">B2B</option>
                </select>
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <Dialog.Close asChild>
                  <button
                    type="button"
                    className="px-4 py-2 text-sm font-medium text-neutral-600 border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors"
                  >
                    Cancel
                  </button>
                </Dialog.Close>
                <button
                  type="submit"
                  disabled={createStudent.isPending}
                  className="px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-50 transition-colors"
                >
                  {createStudent.isPending ? 'Creating…' : 'Create Student'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
```

- [ ] **Step 3: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors. If `useStudents` does not accept `search` param, remove it (check `StudentFilters` type in `src/lib/api/identity.ts` — it has `search?: string`).

- [ ] **Step 4: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/internal/pages/Students.tsx && git commit -m "style(internal): redesign students page with pill filter bar and avatar column"
```

---

## Task 9: Internal Enrollments with SubNav tabs

**Files:**
- Modify: `src/portals/internal/pages/Enrollments.tsx`

- [ ] **Step 1: Read full current `Enrollments.tsx`**

```bash
cat /Users/erickmo/Desktop/Project/vernonedu2/frontend/src/portals/internal/pages/Enrollments.tsx
```

- [ ] **Step 2: Overwrite with SubNav-based status filter**

```tsx
import { useState, useMemo } from 'react'
import { useEnrollments, type Enrollment } from '@/lib/api/enrollment'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { useSubNav, SubNavItem } from '@/components/layout/SubNavContext'

const STATUS_TABS: SubNavItem[] = [
  { label: 'All', value: '' },
  { label: 'Pending', value: 'pending' },
  { label: 'Confirmed', value: 'confirmed' },
  { label: 'Completed', value: 'completed' },
  { label: 'Dropped', value: 'dropped' },
]

const LIMIT = 15

const COLUMNS: Column<Enrollment>[] = [
  { header: 'Student', accessor: 'student_id' },
  { header: 'Batch', accessor: 'batch_id' },
  {
    header: 'Status',
    accessor: 'status',
    cell: (row) => <StatusBadge status={row.status} variant="enrollment" />,
  },
  {
    header: 'Payment',
    accessor: 'payment_status',
    cell: (row) => <StatusBadge status={row.payment_status} variant="payment" />,
  },
  {
    header: 'Progress',
    accessor: 'completion_percent',
    cell: (row) => (
      <div className="flex items-center gap-2">
        <div className="w-20 h-1.5 bg-neutral-100 rounded-full overflow-hidden">
          <div
            className="h-full bg-brand-500 rounded-full"
            style={{ width: `${row.completion_percent}%` }}
          />
        </div>
        <span className="text-xs text-neutral-500 font-mono tabular-nums">
          {row.completion_percent}%
        </span>
      </div>
    ),
  },
  {
    header: 'Enrolled',
    accessor: 'enrolled_at',
    cell: (row) => <span className="text-xs text-neutral-500">{formatDate(row.enrolled_at)}</span>,
  },
]

export default function Enrollments() {
  const [activeTab, setActiveTab] = useState('')
  const [page, setPage] = useState(1)

  const handleTabChange = useMemo(
    () => (v: string) => { setActiveTab(v); setPage(1) },
    [],
  )

  useSubNav(STATUS_TABS, activeTab, handleTabChange)

  const { data, isLoading } = useEnrollments({
    status: activeTab || undefined,
    page,
    limit: LIMIT,
  })

  return (
    <div className="space-y-5">
      <PageHeader title="Enrollments" subtitle="Manage all student enrollments" />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={COLUMNS}
          data={data?.data ?? []}
          loading={isLoading}
          pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
          onPageChange={setPage}
          rowKey={(row) => row.id}
        />
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/internal/pages/Enrollments.tsx && git commit -m "style(internal): move enrollment status filter to SubNav tabs"
```

---

## Task 10: Internal Payments with SubNav tabs

**Files:**
- Modify: `src/portals/internal/pages/Payments.tsx`

- [ ] **Step 1: Read full current `Payments.tsx`**

```bash
cat /Users/erickmo/Desktop/Project/vernonedu2/frontend/src/portals/internal/pages/Payments.tsx
```

- [ ] **Step 2: Overwrite with SubNav-based tab filter**

Keep confirm/reject logic. Replace Radix Tabs with `useSubNav`:

```tsx
import { useState, useMemo } from 'react'
import { Check, X } from 'lucide-react'
import { toast } from 'sonner'
import { useInvoices, useUpdateInvoiceStatus, type Invoice } from '@/lib/api/finance'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { useSubNav, SubNavItem } from '@/components/layout/SubNavContext'

const PAYMENT_TABS: SubNavItem[] = [
  { label: 'Pending', value: 'pending' },
  { label: 'All', value: 'all' },
]

const LIMIT = 15

export default function Payments() {
  const [activeTab, setActiveTab] = useState('pending')
  const [page, setPage] = useState(1)
  const [confirmItem, setConfirmItem] = useState<Invoice | null>(null)

  const handleTabChange = useMemo(
    () => (v: string) => { setActiveTab(v); setPage(1) },
    [],
  )

  useSubNav(PAYMENT_TABS, activeTab, handleTabChange)

  const updateStatus = useUpdateInvoiceStatus()

  const { data, isLoading } = useInvoices({
    status: activeTab === 'pending' ? 'sent' : undefined,
    page,
    limit: LIMIT,
  })

  const handleConfirm = async () => {
    if (!confirmItem) return
    try {
      await updateStatus.mutateAsync({ id: confirmItem.id, status: 'paid' })
      toast.success('Payment confirmed')
      setConfirmItem(null)
    } catch {
      toast.error('Failed to confirm payment')
    }
  }

  const columns: Column<Invoice>[] = [
    {
      header: 'Invoice #',
      accessor: 'number',
      cell: (row) => (
        <span className="font-mono text-xs text-neutral-700">{row.number}</span>
      ),
    },
    {
      header: 'Amount',
      accessor: 'total',
      cell: (row) => (
        <span className="font-semibold text-neutral-800 font-mono">
          {formatCurrency(row.total)}
        </span>
      ),
    },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <StatusBadge status={row.status} variant="invoice" />,
    },
    {
      header: 'Due Date',
      accessor: 'due_date',
      cell: (row) => (
        <span className="text-xs text-neutral-500">{formatDate(row.due_date)}</span>
      ),
    },
    {
      header: 'Issued',
      accessor: 'issued_date',
      cell: (row) => (
        <span className="text-xs text-neutral-500">{formatDate(row.issued_date)}</span>
      ),
    },
    ...(activeTab === 'pending'
      ? [
          {
            header: 'Actions',
            accessor: 'id' as keyof Invoice,
            cell: (row: Invoice) => (
              <div className="flex items-center gap-1.5">
                <button
                  onClick={() => setConfirmItem(row)}
                  className="inline-flex items-center gap-1 px-2.5 py-1 text-xs font-medium text-emerald-700 bg-emerald-50 rounded-lg hover:bg-emerald-100 transition-colors"
                >
                  <Check className="w-3 h-3" /> Confirm
                </button>
              </div>
            ),
          } satisfies Column<Invoice>,
        ]
      : []),
  ]

  return (
    <div className="space-y-5">
      <PageHeader title="Payments" subtitle="Invoice and payment management" />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={columns}
          data={data?.data ?? []}
          loading={isLoading}
          pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
          onPageChange={setPage}
          rowKey={(row) => row.id}
        />
      </div>

      <ConfirmDialog
        open={!!confirmItem}
        title="Confirm Payment"
        description={`Mark invoice ${confirmItem?.number ?? ''} as paid?`}
        onConfirm={handleConfirm}
        onCancel={() => setConfirmItem(null)}
        loading={updateStatus.isPending}
      />
    </div>
  )
}
```

- [ ] **Step 3: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors. Check `ConfirmDialog` props against its interface — adjust `onCancel`/`onClose` prop name if needed by reading `src/components/shared/ConfirmDialog.tsx`.

- [ ] **Step 4: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/internal/pages/Payments.tsx && git commit -m "style(internal): move payment tab filter to SubNav, remove Radix Tabs"
```

---

## Task 11: Internal Courses page

**Files:**
- Modify: `src/portals/internal/pages/Courses.tsx`

- [ ] **Step 1: Read full current `Courses.tsx`**

```bash
cat /Users/erickmo/Desktop/Project/vernonedu2/frontend/src/portals/internal/pages/Courses.tsx
```

- [ ] **Step 2: Update header + table card wrapper**

Keep ALL existing logic (form schema, `createCourse`, `departments` query, dialog). Only change:
1. Wrap DataTable in styled card div
2. Update dialog layout for better visual (two-column fields on large screens)
3. Update PageHeader actions button style

Find the `return (` block and replace it with:

```tsx
  return (
    <div className="space-y-5">
      <PageHeader
        title="Courses"
        subtitle="Manage training courses"
        actions={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors shadow-sm"
          >
            <Plus className="w-4 h-4" />
            Add Course
          </button>
        }
      />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={COLUMNS}
          data={data?.data ?? []}
          loading={isLoading}
          pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
          onPageChange={setPage}
          rowKey={(row) => row.id}
        />
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 animate-in fade-in-0" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-lg bg-white rounded-2xl shadow-xl p-6 animate-in fade-in-0 zoom-in-95 max-h-[90vh] overflow-y-auto">
            <Dialog.Title className="text-lg font-bold text-neutral-900 mb-5">Add Course</Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700">Course Name</label>
                  <input {...register('name')} className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500" />
                  {errors.name && <p className="text-xs text-red-600">{errors.name.message}</p>}
                </div>
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700">Code</label>
                  <input {...register('code')} className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500" />
                  {errors.code && <p className="text-xs text-red-600">{errors.code.message}</p>}
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-neutral-700">Department</label>
                <select {...register('department_id')} className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white">
                  <option value="">Select department</option>
                  {(departments ?? []).map((d) => (
                    <option key={d.id} value={d.id}>{d.name}</option>
                  ))}
                </select>
                {errors.department_id && <p className="text-xs text-red-600">{errors.department_id.message}</p>}
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-neutral-700">Description</label>
                <textarea {...register('description')} rows={3} className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none" />
                {errors.description && <p className="text-xs text-red-600">{errors.description.message}</p>}
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700">Duration (days)</label>
                  <input {...register('duration_days')} type="number" min={1} className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500" />
                </div>
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700">Format</label>
                  <select {...register('format')} className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white">
                    <option value="online">Online</option>
                    <option value="offline">Offline</option>
                    <option value="hybrid">Hybrid</option>
                  </select>
                </div>
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700">Status</label>
                  <select {...register('status')} className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white">
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <Dialog.Close asChild>
                  <button type="button" className="px-4 py-2 text-sm font-medium text-neutral-600 border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors">
                    Cancel
                  </button>
                </Dialog.Close>
                <button
                  type="submit"
                  disabled={createCourse.isPending}
                  className="px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-50 transition-colors"
                >
                  {createCourse.isPending ? 'Creating…' : 'Create Course'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
```

- [ ] **Step 3: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/internal/pages/Courses.tsx && git commit -m "style(internal): update courses page card wrapper and improved dialog layout"
```

---

## Task 12: Student CourseCatalog card grid improvements

**Files:**
- Modify: `src/portals/student/pages/CourseCatalog.tsx`

- [ ] **Step 1: Update card style and remove PageHeader breadcrumbs**

The existing card grid is already functional. Make targeted improvements:
1. Remove `PageHeader` import + usage (replace with inline heading)
2. Improve card shadow/border to match new design system
3. Add `font-mono` to duration and code

Overwrite `src/portals/student/pages/CourseCatalog.tsx`:

```tsx
import { useState } from 'react'
import { Search, Calendar, Monitor, MapPin, Layers } from 'lucide-react'
import { useCourses } from '@/lib/api/catalog'
import { useDepartments } from '@/lib/api/identity'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'

const FORMAT_ICON = {
  online: Monitor,
  offline: MapPin,
  hybrid: Layers,
} as const

const FORMAT_COLOR = {
  online: 'bg-brand-50 text-brand-700',
  offline: 'bg-amber-50 text-amber-700',
  hybrid: 'bg-violet-50 text-violet-700',
} as const

export default function CourseCatalog() {
  const [search, setSearch] = useState('')
  const [departmentId, setDepartmentId] = useState('')

  const { data: departments } = useDepartments()
  const { data: coursesData, isLoading, isError } = useCourses({
    search: search || undefined,
    department_id: departmentId || undefined,
    status: 'active',
  })

  const courses = coursesData?.data ?? []

  if (isError) {
    return (
      <EmptyState
        title="Failed to load courses"
        description="Unable to fetch the course catalog. Please try again."
      />
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">Course Catalog</h1>
        <p className="text-sm text-neutral-500 mt-0.5">Browse available training programs</p>
      </div>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search courses…"
            className="w-full pl-9 pr-4 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
          />
        </div>
        <select
          value={departmentId}
          onChange={(e) => setDepartmentId(e.target.value)}
          className="px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
        >
          <option value="">All departments</option>
          {(departments ?? []).map((d) => (
            <option key={d.id} value={d.id}>{d.name}</option>
          ))}
        </select>
      </div>

      {isLoading ? (
        <LoadingSpinner className="py-20" size="lg" />
      ) : courses.length === 0 ? (
        <EmptyState
          title="No courses found"
          description="Try adjusting your search or filter criteria."
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {courses.map((course) => {
            const Icon = FORMAT_ICON[course.format] ?? Monitor
            const fmtColor = FORMAT_COLOR[course.format] ?? 'bg-neutral-100 text-neutral-600'
            return (
              <div
                key={course.id}
                className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] hover:shadow-md transition-shadow overflow-hidden group"
              >
                <div className="h-1.5 bg-gradient-to-r from-brand-500 to-brand-400 group-hover:from-brand-600 group-hover:to-violet-500 transition-all duration-300" />
                <div className="p-5 space-y-3">
                  <div className="flex items-start justify-between gap-2">
                    <h3 className="font-semibold text-neutral-900 text-sm leading-snug">
                      {course.name}
                    </h3>
                    <span
                      className={`shrink-0 inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${fmtColor}`}
                    >
                      <Icon className="w-3 h-3" />
                      {course.format}
                    </span>
                  </div>

                  <p className="text-xs text-neutral-500 line-clamp-2 leading-relaxed">
                    {course.description}
                  </p>

                  <div className="flex items-center gap-3 text-xs text-neutral-500 pt-1">
                    <span className="flex items-center gap-1 font-mono">
                      <Calendar className="w-3.5 h-3.5" />
                      {course.duration_days}d
                    </span>
                    <span className="font-mono text-neutral-300">·</span>
                    <span className="font-mono">{course.code}</span>
                  </div>

                  <div className="pt-2 border-t border-neutral-50">
                    <button className="w-full py-2 text-xs font-semibold text-brand-600 hover:text-brand-700 hover:bg-brand-50 rounded-lg transition-colors">
                      View batches →
                    </button>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/student/pages/CourseCatalog.tsx && git commit -m "style(student): improve course catalog card grid with format colors and hover effects"
```

---

## Task 13: Student MyEnrollments with SubNav tabs

**Files:**
- Modify: `src/portals/student/pages/MyEnrollments.tsx`

- [ ] **Step 1: Read full current `MyEnrollments.tsx`**

```bash
cat /Users/erickmo/Desktop/Project/vernonedu2/frontend/src/portals/student/pages/MyEnrollments.tsx
```

- [ ] **Step 2: Replace Radix Tabs with `useSubNav`**

Keep ALL column definitions and data logic. Only change how active tab state is managed:

```tsx
import { useState, useMemo } from 'react'
import { useAuth } from '@/lib/auth/useAuth'
import { useEnrollments, type Enrollment } from '@/lib/api/enrollment'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import { useSubNav, SubNavItem } from '@/components/layout/SubNavContext'

const ENROLLMENT_TABS: SubNavItem[] = [
  { label: 'Active', value: 'confirmed' },
  { label: 'Completed', value: 'completed' },
  { label: 'Dropped', value: 'dropped' },
]

const LIMIT = 10

const COLUMNS: Column<Enrollment>[] = [
  { header: 'Batch', accessor: 'batch_id' },
  {
    header: 'Enrolled',
    accessor: 'enrolled_at',
    cell: (row) => (
      <span className="text-xs text-neutral-500">{formatDate(row.enrolled_at)}</span>
    ),
  },
  {
    header: 'Payment',
    accessor: 'payment_status',
    cell: (row) => <StatusBadge status={row.payment_status} variant="payment" />,
  },
  {
    header: 'Progress',
    accessor: 'completion_percent',
    cell: (row) => (
      <div className="flex items-center gap-2">
        <div className="w-20 h-1.5 bg-neutral-100 rounded-full overflow-hidden">
          <div
            className="h-full bg-brand-500 rounded-full"
            style={{ width: `${row.completion_percent}%` }}
          />
        </div>
        <span className="text-xs text-neutral-500 font-mono tabular-nums">
          {row.completion_percent}%
        </span>
      </div>
    ),
  },
  {
    header: 'Certificate',
    accessor: 'certificate_id',
    cell: (row) =>
      row.certificate_id ? (
        <span className="text-xs font-medium text-emerald-600">Issued</span>
      ) : (
        <span className="text-xs text-neutral-400">—</span>
      ),
  },
]

export default function MyEnrollments() {
  const { user } = useAuth()
  const [activeTab, setActiveTab] = useState('confirmed')
  const [page, setPage] = useState(1)

  const handleTabChange = useMemo(
    () => (v: string) => { setActiveTab(v); setPage(1) },
    [],
  )

  useSubNav(ENROLLMENT_TABS, activeTab, handleTabChange)

  const { data, isLoading } = useEnrollments({
    student_id: user?.id,
    status: activeTab,
    page,
    limit: LIMIT,
  })

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">My Enrollments</h1>
        <p className="text-sm text-neutral-500 mt-0.5">Track your enrolled courses</p>
      </div>

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={COLUMNS}
          data={data?.data ?? []}
          loading={isLoading}
          pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
          onPageChange={setPage}
          rowKey={(row) => row.id}
        />
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/student/pages/MyEnrollments.tsx && git commit -m "style(student): replace Radix Tabs with SubNav in MyEnrollments"
```

---

## Task 14: Student Certificates 3-col grid

**Files:**
- Modify: `src/portals/student/pages/Certificates.tsx`

- [ ] **Step 1: Update to 3-col grid with improved card design**

Overwrite `src/portals/student/pages/Certificates.tsx`:

```tsx
import { Award, Download, ExternalLink, ShieldCheck } from 'lucide-react'
import { useAuth } from '@/lib/auth/useAuth'
import { useCertificates } from '@/lib/api/credentialing'
import { formatDate } from '@/lib/utils/format'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'

export default function Certificates() {
  const { user } = useAuth()
  const { data: certificates, isLoading, isError } = useCertificates(user?.id)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">My Certificates</h1>
        <p className="text-sm text-neutral-500 mt-0.5">Your earned credentials</p>
      </div>

      {isLoading && <LoadingSpinner className="py-20" size="lg" />}

      {isError && (
        <EmptyState
          title="Failed to load certificates"
          description="Could not fetch your certificates. Please try again."
        />
      )}

      {!isLoading && !isError && (certificates?.length ?? 0) === 0 && (
        <EmptyState
          title="No certificates yet"
          description="Complete a course to earn your first certificate."
        />
      )}

      {!isLoading && !isError && (certificates?.length ?? 0) > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {(certificates ?? []).map((cert) => (
            <div
              key={cert.id}
              className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] hover:shadow-md transition-shadow overflow-hidden"
            >
              {/* Card header */}
              <div className="bg-gradient-to-br from-emerald-500 to-emerald-600 px-5 py-4 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
                  <Award className="w-5 h-5 text-white" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-white text-sm truncate">{cert.course_name}</p>
                  <p className="text-emerald-100 text-[11px] font-mono truncate mt-0.5">
                    {cert.cert_number}
                  </p>
                </div>
                {cert.status === 'valid' && (
                  <ShieldCheck className="w-5 h-5 text-emerald-200 shrink-0" />
                )}
              </div>

              {/* Card body */}
              <div className="px-5 py-4 space-y-3">
                <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-neutral-500">
                  <span>Issued: <span className="text-neutral-700 font-medium">{formatDate(cert.issued_at)}</span></span>
                  {cert.expires_at && (
                    <span>Expires: <span className="text-neutral-700 font-medium">{formatDate(cert.expires_at)}</span></span>
                  )}
                </div>

                <div className="flex items-center gap-2 pt-1">
                  <a
                    href={`/verify/${cert.cert_number}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-neutral-600 border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors"
                  >
                    <ExternalLink className="w-3.5 h-3.5" />
                    Verify
                  </a>
                  <button className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-white bg-emerald-600 rounded-lg hover:bg-emerald-700 transition-colors">
                    <Download className="w-3.5 h-3.5" />
                    Download
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/student/pages/Certificates.tsx && git commit -m "style(student): redesign certificates page with 3-col grid and gradient card headers"
```

---

## Task 15: Student Profile — two-column layout

**Files:**
- Modify: `src/portals/student/pages/Profile.tsx`

- [ ] **Step 1: Update to two-column layout + remove max-w constraint**

Keep ALL form logic (`useForm`, `useUpdateStudentProfile`, `onSubmit`). Only change the layout structure and remove `max-w-2xl`:

Overwrite `src/portals/student/pages/Profile.tsx`:

```tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { User, Mail, Phone, Shield } from 'lucide-react'
import { useAuth } from '@/lib/auth/useAuth'
import { useUpdateStudentProfile } from '@/lib/api/identity'

const profileSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email'),
  phone: z.string().min(8, 'Phone must be at least 8 characters'),
})

type ProfileForm = z.infer<typeof profileSchema>

export default function StudentProfile() {
  const { user } = useAuth()
  const updateProfile = useUpdateStudentProfile()

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isDirty },
  } = useForm<ProfileForm>({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      name: user?.name ?? '',
      email: user?.email ?? '',
      phone: '',
    },
  })

  const values = watch()
  const filledCount = [values.name, values.email, values.phone].filter(Boolean).length
  const completionPercent = Math.round((filledCount / 3) * 100)

  const onSubmit = async (data: ProfileForm) => {
    if (!user?.id) return
    try {
      await updateProfile.mutateAsync({ id: user.id, ...data })
      toast.success('Profile updated successfully')
    } catch {
      toast.error('Failed to update profile')
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">My Profile</h1>
        <p className="text-sm text-neutral-500 mt-0.5">Manage your personal information</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left: info card */}
        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-6 flex flex-col items-center text-center">
            <div className="w-20 h-20 rounded-full bg-emerald-50 flex items-center justify-center text-3xl font-bold text-emerald-700 mb-3">
              {user?.name?.charAt(0).toUpperCase() ?? '?'}
            </div>
            <p className="font-semibold text-neutral-900">{user?.name}</p>
            <p className="text-sm text-neutral-500 capitalize mt-0.5">{user?.role}</p>
          </div>

          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5 space-y-3">
            <p className="text-xs font-semibold text-neutral-500 uppercase tracking-wide">Account Info</p>
            <div className="flex items-center gap-2.5 text-sm text-neutral-700">
              <Mail className="w-4 h-4 text-neutral-400 shrink-0" />
              <span className="truncate">{user?.email}</span>
            </div>
            <div className="flex items-center gap-2.5 text-sm text-neutral-700">
              <Shield className="w-4 h-4 text-neutral-400 shrink-0" />
              <span className="capitalize">{user?.role}</span>
            </div>
          </div>

          {/* Profile completion */}
          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5">
            <div className="flex items-center justify-between mb-2">
              <p className="text-sm font-medium text-neutral-700">Profile completion</p>
              <p className="text-sm font-bold text-emerald-600">{completionPercent}%</p>
            </div>
            <div className="w-full h-1.5 bg-neutral-100 rounded-full overflow-hidden">
              <div
                className="h-full bg-emerald-500 rounded-full transition-all duration-500"
                style={{ width: `${completionPercent}%` }}
              />
            </div>
          </div>
        </div>

        {/* Right: edit form */}
        <div className="lg:col-span-2">
          <form
            onSubmit={handleSubmit(onSubmit)}
            className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-6 space-y-5"
          >
            <h2 className="font-semibold text-neutral-900 text-base">Edit Information</h2>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-neutral-700 flex items-center gap-1.5">
                <User className="w-3.5 h-3.5 text-neutral-400" /> Full name
              </label>
              <input
                {...register('name')}
                className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                placeholder="Your full name"
              />
              {errors.name && <p className="text-xs text-red-600">{errors.name.message}</p>}
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-neutral-700 flex items-center gap-1.5">
                <Mail className="w-3.5 h-3.5 text-neutral-400" /> Email address
              </label>
              <input
                {...register('email')}
                type="email"
                className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                placeholder="you@example.com"
              />
              {errors.email && <p className="text-xs text-red-600">{errors.email.message}</p>}
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-neutral-700 flex items-center gap-1.5">
                <Phone className="w-3.5 h-3.5 text-neutral-400" /> Phone number
              </label>
              <input
                {...register('phone')}
                type="tel"
                className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                placeholder="+62 xxx xxxx xxxx"
              />
              {errors.phone && <p className="text-xs text-red-600">{errors.phone.message}</p>}
            </div>

            <div className="pt-2 flex justify-end">
              <button
                type="submit"
                disabled={!isDirty || updateProfile.isPending}
                className="px-5 py-2.5 text-sm font-semibold text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {updateProfile.isPending ? 'Saving…' : 'Save changes'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/student/pages/Profile.tsx && git commit -m "style(student): redesign profile with two-column layout and info sidebar"
```

---

## Task 16: Student Dashboard — full-width hero

**Files:**
- Modify: `src/portals/student/pages/Dashboard.tsx`

- [ ] **Step 1: Remove `max-w-2xl` from hero section**

Open `src/portals/student/pages/Dashboard.tsx`. Find the hero banner div:

```tsx
<div className="relative max-w-2xl space-y-3">
```

Change to:

```tsx
<div className="relative space-y-3">
```

- [ ] **Step 2: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/student/pages/Dashboard.tsx && git commit -m "style(student): remove max-w-2xl constraint from dashboard hero banner"
```

---

## Task 17: Franchise Dashboard styling refresh

**Files:**
- Modify: `src/portals/franchise/pages/Dashboard.tsx`

- [ ] **Step 1: Update card style to match design system**

The franchise dashboard already has good content. Only update card class and heading style.

Find all occurrences of:
```tsx
className="bg-white rounded-xl border border-border p-5"
```

Replace with:
```tsx
className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5"
```

Also find the page heading:
```tsx
<h1 className="text-2xl font-bold text-neutral-900">Franchise Dashboard</h1>
```

No change needed — already correct.

- [ ] **Step 2: Typecheck**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run typecheck
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add src/portals/franchise/pages/Dashboard.tsx && git commit -m "style(franchise): update card border/shadow to match design system"
```

---

## Task 18: Final build verification

- [ ] **Step 1: Run full build**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run build
```

Expected: Build succeeds with no TypeScript errors. Output in `dist/`.

- [ ] **Step 2: Fix any build errors**

Common issues to watch for:
- Unused imports causing lint errors → remove them
- `satisfies` operator (used in Payments task) — requires TypeScript 4.9+. Check `tsconfig.json` target. If issue, replace `satisfies Column<Invoice>` with a type cast: `as Column<Invoice>`
- `cn()` import path — ensure all new files import from `@/lib/utils/cn`

- [ ] **Step 3: Start dev server and do a smoke check**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && npm run dev
```

Navigate to:
- `http://localhost:5173/login` — verify login page renders
- After login as internal user → `http://localhost:5173/internal` — verify TopNavBar visible, Dashboard renders
- Click "Enrollments" → verify SubNavBar tabs appear (All / Pending / Confirmed / Completed / Dropped)
- Click "Payments" → verify SubNavBar shows Pending / All
- Click "Students" → verify pill filter bar
- Resize to mobile → verify hamburger menu works

- [ ] **Step 4: Final commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/frontend && git add -p && git commit -m "chore(frontend): final build fix and cleanup"
```

---

## Self-Review Checklist

- [x] **SubNavContext** — covered in Task 2; `useSubNav` used in Tasks 9, 10, 13
- [x] **TopNavBar** — covered in Task 3; used in Tasks 4, 5, 6
- [x] **All 3 portals refactored** — Tasks 4, 5, 6
- [x] **Internal pages** — Tasks 7 (Dashboard), 8 (Students), 9 (Enrollments), 10 (Payments), 11 (Courses)
- [x] **Student pages** — Tasks 12 (Catalog), 13 (Enrollments), 14 (Certificates), 15 (Profile), 16 (Dashboard hero)
- [x] **Franchise** — Task 17
- [x] **Fonts** — Task 1
- [x] **Build check** — Task 18
- [x] No `TBD` placeholders — all code is complete
- [x] Type consistency — `SubNavItem` used in Tasks 2, 9, 10, 13; `NavItem` used in Tasks 3, 4, 5, 6
- [x] `useSubNav(items, active, onChange)` signature consistent across all usages
