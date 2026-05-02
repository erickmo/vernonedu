# Standardized Frontend Layout & Partners Bug Fix

**Date:** 2026-05-01  
**Scope:** Fix partners routing bug, add edit button, create StandardPageLayout for all pages  
**Stack:** React 18 + TypeScript, React Router v6, Tailwind CSS, Radix UI

---

## Overview

Three connected tasks:
1. **Partners Route Bug Fix** — `/partners/new` currently treated as ID, causing "partner not found" error
2. **Partners Edit Button** — Add edit functionality to partner detail page
3. **Standardized Layout** — Create flexible StandardPageLayout component and refactor all pages (public, internal, admin) to use it for consistent UX and easier development

---

## 1. Partners Route Bug Fix

### Problem

Route `/internal/partners/new` is interpreted as ID "new", triggering detail page load → API returns 404.

### Solution

Separate route for creation:
```
/partners/new          → PartnerCreatePage (new)
/partners/:id          → PartnerDetailPage (existing)
/partners              → PartnerListPage (existing)
```

Router must define `/new` BEFORE `/:id` to prevent match collision.

Router config:
```typescript
{
  path: '/partners',
  element: <PartnerLayout />,
  children: [
    { path: '', element: <PartnerListPage /> },
    { path: 'new', element: <PartnerCreatePage /> },  // Before :id
    { path: ':id', element: <PartnerDetailPage /> },
  ],
}
```

---

## 2. Partners Edit Button

### Detail Page Enhancement

Add "Edit" button on partner detail page:
- Location: Top-right actions area (next to delete if exists)
- Behavior: Navigate to `/partners/:id/edit` OR open edit form in modal/drawer
- Button style: Primary or secondary action button

Two implementation options:
- **Option A:** Separate edit route `/partners/:id/edit` with edit form page
- **Option B:** Modal/drawer on detail page (toggle mode: view vs edit)

**Recommendation:** Option A (cleaner routing, clearer URL state, better back button UX)

Edit page:
```
/partners/:id/edit     → PartnerEditPage (form pre-filled with current data)
```

---

## 3. Standardized Layout Component

### New Component: StandardPageLayout

Located: `src/components/layout/StandardPageLayout.tsx`

Purpose: Consistent header + breadcrumbs + content structure across all pages (public, internal, admin).

Props:
```typescript
interface StandardPageLayoutProps {
  header?: ReactNode;               // Top nav (optional, custom per page type)
  breadcrumbs?: BreadcrumbItem[];   // Navigation breadcrumbs
  title?: string;                   // Page title
  subtitle?: string;                // Page description
  actions?: ReactNode;              // Action buttons (edit, delete, create, etc)
  tabs?: DetailTab[];               // Tab navigation (optional)
  activeTab?: string;
  onTabChange?: (value: string) => void;
  children: ReactNode;              // Main content area
}
```

### Structure

```
┌─────────────────────────────────┐
│       Header Slot (nav)         │  ← header prop (optional)
├─────────────────────────────────┤
│ Breadcrumbs | Title | Actions   │  ← breadcrumbs, title, actions props
│ Subtitle (optional)             │  ← subtitle prop
├─────────────────────────────────┤
│ Tabs (optional)                 │  ← tabs, activeTab, onTabChange props
├─────────────────────────────────┤
│                                 │
│    Main Content Area            │  ← children
│    (page-specific content)      │
│                                 │
└─────────────────────────────────┘
```

### Design Principles

1. **Minimal but complete** — Include essentials (title, breadcrumbs, content), optional sections as props
2. **Flexible content** — Children can be anything (forms, tables, cards, custom layouts)
3. **Props-driven** — Behavior/appearance configured via props, not hard-coded
4. **Responsive** — Works on mobile/tablet/desktop
5. **Header agnostic** — Header passed as prop, can differ by page type (public, internal, admin)

### Styling

- Background: Consistent (light gray or white)
- Spacing: Standardized padding/gaps
- Typography: Use existing design system (sizes, colors)
- Borders/dividers: Between sections
- Follow existing Tailwind patterns in project

---

## 4. Page Migration Strategy

### Phase 1: Foundation (Partners + StandardPageLayout)

1. Create StandardPageLayout component
2. Fix partners routes (`/new` before `/:id`)
3. Add PartnerCreatePage (new)
4. Rename/refactor PartnerDetailPage to use edit route
5. Add PartnerEditPage (new or modal)
6. Integrate StandardPageLayout into partners pages
7. Add edit button to partner detail

### Phase 2: Refactor All Pages (phased rollout)

Refactor existing pages to use StandardPageLayout:

**Public Pages (no header needed):**
- Login → StandardPageLayout (no header)
- Register → StandardPageLayout (no header)
- CertificateVerify → StandardPageLayout (minimal header)

**Internal Pages:**
- Partners (list, create, detail, edit) — StandardPageLayout with full features
- Other internal pages — StandardPageLayout (TBD based on page type)

**Admin Pages:**
- Department pages — Already have AdminLayout, can migrate to StandardPageLayout if needed

### Migration Order

1. PartnerListPage → StandardPageLayout
2. PartnerCreatePage → StandardPageLayout (new)
3. PartnerDetailPage → StandardPageLayout
4. PartnerEditPage → StandardPageLayout (new)
5. Login → StandardPageLayout
6. Register → StandardPageLayout
7. CertificateVerify → StandardPageLayout
8. Admin pages (optional, may keep AdminLayout)

---

## 5. Implementation Details

### Files to Create

- `src/components/layout/StandardPageLayout.tsx` — New layout component
- `src/pages/internal/PartnerCreatePage.tsx` — New create page
- `src/pages/internal/PartnerEditPage.tsx` — New edit page

### Files to Modify

- `src/App.tsx` — Add partner routes (`/new`, `/edit`)
- `src/pages/internal/PartnerListPage.tsx` — Wrap with StandardPageLayout
- `src/pages/internal/PartnerDetailPage.tsx` — Wrap with StandardPageLayout + add edit button
- `src/pages/Login.tsx` — Wrap with StandardPageLayout
- `src/pages/Register.tsx` — Wrap with StandardPageLayout
- `src/pages/CertificateVerify.tsx` — Wrap with StandardPageLayout

### Component Dependencies

- StandardPageLayout uses existing:
  - BreadcrumbItem interface (from DetailPageLayout)
  - Tailwind CSS
  - Radix UI (if tabs used)
  - Lucide icons (for action buttons)

---

## 6. Success Criteria

- ✅ `/partners/new` route works (no 404)
- ✅ Partner creation flow complete
- ✅ Partner detail page has edit button
- ✅ Partner edit route/page works
- ✅ StandardPageLayout created and tested
- ✅ All public pages use StandardPageLayout
- ✅ All internal pages use StandardPageLayout
- ✅ Consistent header/breadcrumbs/content structure across app
- ✅ No broken links or routing errors
- ✅ Mobile-responsive layout verified

---

## 7. Notes

- Edit functionality: Can use same form component (PartnerForm) for both create and edit, pre-filled in edit mode
- Breadcrumbs: Auto-generate or pass explicitly? Define pattern.
- Header: Public pages may not need header, internal/admin pages do. Make header optional.
- Tabs: Optional feature, used only where needed (e.g., detail pages with multiple sections)
- Phase 2 can be rolled out gradually after Phase 1 stabilizes
