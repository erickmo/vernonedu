# Shared Components — Scalable Frontend Architecture

**Date:** 2026-04-29  
**Status:** Approved  
**Scope:** `frontend/src/`

## Problem

Three recurring pain points:
1. Adding new pages is slow — no scaffolding template
2. Existing pages are hard to maintain — logic and class strings duplicated across files
3. Design inconsistency across portals (internal, franchise, student)

## Solution

Layered component system: atoms → molecules → templates, with entity-specific modals colocated per portal.

## Layer Structure

```
src/components/
  ui/          ← atoms: no business logic, forward-ref wrappers
  shared/      ← existing + new molecules
  templates/   ← page scaffolding templates
src/portals/[portal]/components/  ← entity modals per portal
```

### Layer Rules
- `ui/` does NOT import from `shared/` or `templates/`
- `shared/` may import from `ui/`, NOT from `templates/`
- `templates/` may import from both `ui/` and `shared/`
- Entity modals import from `ui/` and `shared/`, NOT from `templates/`

## Component Specs

### Layer 1 — `ui/` Atoms

```tsx
// Input.tsx
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: boolean
}

// Select.tsx
interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  error?: boolean
}

// Textarea.tsx
interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  error?: boolean
}

// Label.tsx
interface LabelProps extends React.LabelHTMLAttributes<HTMLLabelElement> {
  required?: boolean
}

// Button.tsx
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger'
  size?: 'sm' | 'md'
  loading?: boolean
}
```

All atoms: styled with Tailwind, forward ref, `error` prop adds red ring.

### Layer 2 — `shared/` Molecules (New)

```tsx
// SearchInput.tsx
interface SearchInputProps {
  value: string
  onChange: (value: string) => void
  placeholder?: string
  debounceMs?: number
}

// FilterTabs.tsx — inline tabs, NOT SubNav
interface FilterTabsProps<T extends string> {
  tabs: { label: string; value: T }[]
  active: T
  onChange: (value: T) => void
}

// FormField.tsx — label + control + error wrapper
interface FormFieldProps {
  label: string
  error?: string
  required?: boolean
  children: ReactNode
}

// FormModal.tsx — Radix Dialog shell
interface FormModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  onSubmit: () => void
  loading?: boolean
  submitLabel?: string
  children: ReactNode
}

// TableCard.tsx — visual wrapper for DataTable
interface TableCardProps {
  children: ReactNode
}

// AvatarInitial.tsx — circular initial avatar
interface AvatarInitialProps {
  name: string
  size?: 'sm' | 'md'  // sm=w-8 h-8, md=w-10 h-10
}
```

### Layer 2 — `shared/` Existing (unchanged)
`DataTable`, `PageHeader`, `StatusBadge`, `EmptyState`, `LoadingSpinner`, `ErrorBoundary`, `ConfirmDialog`, `ApprovalTimeline`, `PriceBreakdown`

### Layer 3 — `templates/`

```tsx
// ListPageTemplate.tsx
interface ListPageTemplateProps<T> {
  title: string
  subtitle?: string
  actions?: ReactNode

  search?: {
    value: string
    onChange: (v: string) => void
    placeholder?: string
  }

  filterTabs?: {
    tabs: { label: string; value: string }[]
    active: string
    onChange: (v: string) => void
  }

  columns: Column<T>[]
  data: T[]
  loading: boolean
  pagination: { page: number; limit: number; total: number }
  onPageChange: (page: number) => void
  rowKey: (row: T) => string
  onRowClick?: (row: T) => void
}

// DetailPageTemplate.tsx
interface DetailPageTemplateProps {
  title: string
  subtitle?: string
  breadcrumbs: { label: string; href?: string }[]
  actions?: ReactNode
  children: ReactNode
}
```

### Entity Modals — Per Portal

Location: `portals/[portal]/components/Create*.tsx`  
Pattern: uses `FormModal` + `FormField` + `ui/` atoms + react-hook-form + zod.

```tsx
// portals/internal/components/CreateStudentModal.tsx
interface CreateStudentModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}
```

## Search Pattern

Two patterns coexist — context-dependent, both valid:

| Pattern | When | Component |
|---------|------|-----------|
| SubNav tabs | Status filters (Enrollment, Payment) | `useSubNav` hook (existing) |
| Inline search + FilterTabs | Text search + category filter (Students) | `SearchInput` + `FilterTabs` |

Pages may use both simultaneously (SubNav for status, inline search for text).

## Page After Refactor (Example)

```tsx
// portals/internal/pages/Students.tsx — after
export default function Students() {
  const navigate = useNavigate()
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

  return (
    <>
      <ListPageTemplate
        title="Students"
        subtitle="Manage registered students"
        actions={<Button onClick={() => setOpen(true)}><Plus className="w-4 h-4" /> Add Student</Button>}
        search={{ value: search, onChange: (v) => { setSearch(v); setPage(1) } }}
        filterTabs={{ tabs: SOURCE_FILTERS, active: sourceFilter, onChange: (v) => { setSourceFilter(v as typeof sourceFilter); setPage(1) } }}
        columns={COLUMNS}
        data={data?.data ?? []}
        loading={isLoading}
        pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
        onPageChange={setPage}
        rowKey={(r) => r.id}
        onRowClick={(r) => navigate(`/internal/students/${r.id}`)}
      />
      <CreateStudentModal open={open} onOpenChange={setOpen} />
    </>
  )
}
```

## Migration Strategy

### Phase Order (bottom-up, no big-bang)

**Phase 1 — `ui/` atoms**  
`Input`, `Select`, `Textarea`, `Label`, `Button`  
No deps. Safe to ship independently.

**Phase 2 — `shared/` molecules**  
`AvatarInitial`, `TableCard`, `SearchInput`, `FilterTabs`, `FormField`, `FormModal`  
Depends on Phase 1.

**Phase 3 — Entity modals**  
Extract `Create*.tsx` from existing pages into `portals/[portal]/components/`  
Depends on Phase 1 + 2.

**Phase 4 — Templates + page refactor**  
Build `ListPageTemplate`, `DetailPageTemplate`.  
Refactor priority pages:
- Internal: Students, Enrollments, Courses, Payments, Partners, Franchises, TeamMembers
- Franchise: Enrollments, Payments, TeamMembers
- Student: CourseCatalog, MyEnrollments

### Out of Scope
- Detail pages — can adopt `DetailPageTemplate` but internal logic unchanged
- Auth pages (Login, Register) — different pattern
- Domain overview pages (Academic, Finance, HR, Ops) — dashboard style

### Branch Strategy
```
feat/shared-components-phase1   ← ui/ atoms
feat/shared-components-phase2   ← molecules
feat/shared-components-phase3   ← entity modals
feat/shared-components-phase4   ← templates + page refactor
```
Each phase ships as its own PR. Breaking change risk: low — new components, existing pages untouched until Phase 4.

## Success Criteria

1. New list page can be built using only `ListPageTemplate` + entity modal — no boilerplate copy-paste
2. Zero duplicate search bar / filter tab HTML across pages
3. All create dialogs use `FormModal` + `FormField` + `ui/` atoms
4. Design consistent across internal, franchise, student portals
