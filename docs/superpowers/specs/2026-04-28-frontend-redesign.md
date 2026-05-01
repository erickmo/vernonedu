# Frontend Redesign Spec
**Date**: 2026-04-28  
**Scope**: All three portals — layout shell + page visual refresh (option C)

---

## Goal

Replace current sidebar layouts (Internal, Franchise) and generic top-nav (Student) with a unified double-nav system. Refresh page designs to use card/flat aesthetic throughout. Maintain 100% API compatibility — no data layer changes.

---

## Design System

### Typography
- **Display/Body**: `Plus Jakarta Sans` (Google Fonts) — loaded in `index.html`
- **Mono**: `DM Mono` (Google Fonts) — used for numbers, codes, IDs
- Replace `fontFamily.sans` in `tailwind.config.ts`

### Colors
- Brand: existing `brand.*` palette (blue `#2563eb` primary)
- Neutral: existing `neutral.*` palette
- No new colors added — use existing tokens

### Cards
```
bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]
hover:shadow-md transition-shadow
```

### CSS Variables (index.css)
- Keep existing CSS vars
- Add `--nav-height: 3.5rem` (56px) for nav1
- Add `--subnav-height: 2.75rem` (44px) for nav2

---

## Layout Architecture

### Nav1 — `TopNavBar.tsx`
Shared primitive used by all portal layouts.

```
height: 56px | bg-white/95 backdrop-blur-sm | border-b border-neutral-100 | sticky top-0 z-50
```

Slots:
- **Left**: Logo mark (brand-600 bg) + "VernonEdu" wordmark
- **Center**: `mainNav` prop — array of `{ to, label, end? }` rendered as NavLinks with `border-b-2 border-brand-600` active indicator
- **Right**: `NotificationBell` + `AvatarMenu`

Mobile (`< md`): center nav hidden, replaced by hamburger that opens a mobile menu drawer.

Props:
```ts
interface TopNavBarProps {
  mainNav: NavItem[]
  onLogout: () => void
  user: { name: string; role: string } | null
  unreadCount?: number
  portalLabel?: string  // shown on mobile menu header
}
```

### Nav2 — `SubNavContext.tsx` + portal render
Context-based injection: pages set their sub-nav tabs, portal renders them.

```ts
interface SubNavTab {
  label: string
  value: string
  active: boolean
  onClick: () => void
}

// Hook used by pages:
useSubNav(tabs: SubNavTab[])  // sets tabs, clears on unmount
```

Portal renders nav2 bar below nav1 when `tabs.length > 0`:
```
height: 44px | bg-neutral-50 | border-b border-neutral-100 | sticky top-14 z-40
px-6 md:px-8 | flex items-center gap-1
```

Tab style:
- Default: `text-sm text-neutral-500 px-3 py-2 font-medium`
- Active: `text-brand-600 border-b-2 border-brand-600`
- Hover: `text-neutral-700`

### Main content area
```
min-h-[calc(100vh-3.5rem)] | pt-0 | px-6 md:px-8 lg:px-12 | py-6 | bg-neutral-50
```
Full width — no max-w constraint.

---

## Portal Layouts

### InternalPortal.tsx
- Replace sidebar with `TopNavBar` (mainNav = Dashboard, Enrollments, Payments, Courses, Students)
- Add `SubNavContext.Provider` wrapping `<Outlet />`
- Render `SubNavBar` between nav1 and main content (sticky top-14)

### StudentPortal.tsx
- Replace current top-nav with `TopNavBar` (mainNav = Dashboard, Catalog, Enrollments, Certificates, Profile)
- Add `SubNavContext.Provider`
- Render `SubNavBar`

### FranchisePortal.tsx
- Replace sidebar with `TopNavBar` (mainNav = Dashboard)
- Add `SubNavContext.Provider`

---

## Page Redesigns

### Internal Pages

**Dashboard** (`pages/internal/Dashboard.tsx`):
- Keep KPI grid (4 cards) — improve card: left metric + right icon, bottom trend text
- Replace "Recent Activity" list with proper card table (student name resolved, not raw ID)
- Add page-level heading inside content area

**Students** (`pages/internal/Students.tsx`):
- Keep DataTable, upgrade filter bar: pill-style source filter buttons + search input
- Add avatar initials column
- "Add Student" button: solid brand-600

**Enrollments** (`pages/internal/Enrollments.tsx`):
- Use `useSubNav` for status filter tabs (All / Pending / Confirmed / Completed / Dropped)
- Remove separate filter dropdowns for status (moved to nav2 tabs)
- Keep payment filter as dropdown in filter bar

**Payments** (`pages/internal/Payments.tsx`):
- Replace Radix Tabs with `useSubNav` tabs (Pending / All)
- Keep DataTable and confirm/reject action columns

**Courses** (`pages/internal/Courses.tsx`):
- Keep DataTable
- Improve "Add Course" dialog: better field layout

### Student Pages

**Dashboard** (`pages/student/Dashboard.tsx`):
- Mostly fine — minor: remove max-w-2xl from hero banner to go full-width

**CourseCatalog** (`pages/student/CourseCatalog.tsx`):
- Replace current list with card grid (3 cols → 2 cols → 1 col responsive)
- Each card: course name, department, format badge, duration, "Enroll" CTA

**MyEnrollments** (`pages/student/MyEnrollments.tsx`):
- Use `useSubNav` for tabs (Active / Completed / Dropped)
- Keep DataTable

**Certificates** (`pages/student/Certificates.tsx`):
- Card grid layout (3 cols)
- Each card: gradient header, cert number, course name, issued date, verify link

**Profile** (`pages/student/Profile.tsx`):
- Two-column card: left info, right edit form

### Franchise

**Dashboard** (`pages/franchise/Dashboard.tsx`):
- Simple 3-card stats row + placeholder message

---

## Shared Components

**PageHeader** (`components/shared/PageHeader.tsx`):
- Simplify: just `<h1>` + optional subtitle, no breadcrumbs logic needed
- Breadcrumbs rendered by portal if needed in future

**DataTable** (`components/shared/DataTable.tsx`):
- No logic changes
- Minor style: `thead` bg `neutral-50`, row hover `neutral-50/60`

**StatusBadge** (`components/shared/StatusBadge.tsx`):
- No changes needed

---

## Responsive Breakpoints

| Breakpoint | Nav behavior |
|------------|-------------|
| `< md` (< 768px) | Hamburger menu, nav items in drawer |
| `md–lg` | Full nav1 + nav2 visible, content px-6 |
| `> lg` | Full nav1 + nav2 visible, content px-8 lg:px-12 |

---

## Files Changed / Created

| Action | File |
|--------|------|
| Create | `src/components/layout/SubNavContext.tsx` |
| Create | `src/components/layout/TopNavBar.tsx` |
| Modify | `src/portals/internal/InternalPortal.tsx` |
| Modify | `src/portals/student/StudentPortal.tsx` |
| Modify | `src/portals/franchise/FranchisePortal.tsx` |
| Modify | `src/portals/internal/pages/Dashboard.tsx` |
| Modify | `src/portals/internal/pages/Students.tsx` |
| Modify | `src/portals/internal/pages/Enrollments.tsx` |
| Modify | `src/portals/internal/pages/Payments.tsx` |
| Modify | `src/portals/internal/pages/Courses.tsx` |
| Modify | `src/portals/student/pages/CourseCatalog.tsx` |
| Modify | `src/portals/student/pages/MyEnrollments.tsx` |
| Modify | `src/portals/student/pages/Certificates.tsx` |
| Modify | `src/portals/student/pages/Profile.tsx` |
| Modify | `src/portals/franchise/pages/Dashboard.tsx` |
| Modify | `src/components/shared/PageHeader.tsx` |
| Modify | `src/index.css` |
| Modify | `tailwind.config.ts` |
| Modify | `index.html` |

---

## Non-goals

- No new API calls or data layer changes
- No dark mode (not requested)
- No animation library additions (CSS transitions only)
- No new routes added
- Student Dashboard already good — only hero banner width fix
