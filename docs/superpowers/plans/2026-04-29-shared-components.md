# Shared Components — Layered Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a layered component system (ui atoms → shared molecules → page templates) and migrate existing pages to eliminate duplicated search bars, filter tabs, and create dialog patterns.

**Architecture:** Three layers — `components/ui/` (atoms, no business logic), `components/shared/` (extend existing molecules), `components/templates/` (page scaffolding). Entity modals extracted to `portals/[portal]/components/`. Pages refactored to use `ListPageTemplate`.

**Tech Stack:** React 18, TypeScript, Tailwind CSS, Radix UI, react-hook-form, zod, class-variance-authority, sonner

---

## File Map

**New — `components/ui/`**
- `frontend/src/components/ui/Button.tsx` — cva-based button with variant/size/loading
- `frontend/src/components/ui/Input.tsx` — forward-ref input with error state
- `frontend/src/components/ui/Label.tsx` — forward-ref label with required indicator
- `frontend/src/components/ui/Select.tsx` — forward-ref select with error state
- `frontend/src/components/ui/Textarea.tsx` — forward-ref textarea with error state

**New — `components/shared/`**
- `frontend/src/components/shared/AvatarInitial.tsx` — circular initial avatar
- `frontend/src/components/shared/TableCard.tsx` — visual wrapper for DataTable
- `frontend/src/components/shared/SearchInput.tsx` — search icon + input
- `frontend/src/components/shared/FilterTabs.tsx` — inline tab strip
- `frontend/src/components/shared/FormField.tsx` — label + control + error wrapper
- `frontend/src/components/shared/FormModal.tsx` — Radix Dialog shell for create/edit forms

**New — `components/templates/`**
- `frontend/src/components/templates/ListPageTemplate.tsx` — full list page composition
- `frontend/src/components/templates/DetailPageTemplate.tsx` — detail page with breadcrumbs

**New — `portals/internal/components/`**
- `frontend/src/portals/internal/components/CreateStudentModal.tsx`
- `frontend/src/portals/internal/components/CreateCourseModal.tsx`
- `frontend/src/portals/internal/components/CreateFranchiseeModal.tsx`

**Modified — internal pages**
- `frontend/src/portals/internal/pages/Students.tsx` — use ListPageTemplate + CreateStudentModal
- `frontend/src/portals/internal/pages/Enrollments.tsx` — use ListPageTemplate
- `frontend/src/portals/internal/pages/Courses.tsx` — use ListPageTemplate + CreateCourseModal
- `frontend/src/portals/internal/pages/Payments.tsx` — use ListPageTemplate
- `frontend/src/portals/internal/pages/Franchises.tsx` — use ListPageTemplate + CreateFranchiseeModal

**Modified — franchise pages**
- `frontend/src/portals/franchise/pages/Enrollments.tsx` — use ListPageTemplate

**Verification commands** (no test runner installed):
```bash
cd frontend && npm run typecheck
cd frontend && npm run lint
```

---

### Task 1: Button atom

**Files:**
- Create: `frontend/src/components/ui/Button.tsx`

- [ ] **Step 1: Create Button.tsx**

```tsx
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils/cn'

const buttonVariants = cva(
  'inline-flex items-center justify-center gap-2 rounded-lg text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed',
  {
    variants: {
      variant: {
        primary: 'bg-brand-600 text-white hover:bg-brand-700 shadow-sm',
        secondary: 'bg-neutral-100 text-neutral-700 hover:bg-neutral-200',
        ghost: 'text-neutral-600 hover:bg-neutral-50',
        danger: 'bg-red-600 text-white hover:bg-red-700',
      },
      size: {
        sm: 'px-3 py-1.5',
        md: 'px-4 py-2',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
)

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  loading?: boolean
}

export default function Button({
  variant,
  size,
  loading = false,
  className,
  children,
  disabled,
  ...props
}: ButtonProps) {
  return (
    <button
      {...props}
      disabled={disabled || loading}
      className={cn(buttonVariants({ variant, size }), className)}
    >
      {loading && (
        <span className="w-4 h-4 rounded-full border-2 border-current border-t-transparent animate-spin" />
      )}
      {children}
    </button>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/ui/Button.tsx
git commit -m "feat(ui): add Button atom with variant/size/loading"
```

---

### Task 2: Input and Label atoms

**Files:**
- Create: `frontend/src/components/ui/Input.tsx`
- Create: `frontend/src/components/ui/Label.tsx`

- [ ] **Step 1: Create Input.tsx**

```tsx
import { forwardRef } from 'react'
import { cn } from '@/lib/utils/cn'

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: boolean
}

const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ error, className, ...props }, ref) => (
    <input
      ref={ref}
      className={cn(
        'w-full px-3 py-2.5 text-sm border rounded-lg bg-white transition-colors',
        'focus:outline-none focus:ring-2 focus:ring-brand-500',
        error ? 'border-red-300 focus:ring-red-400' : 'border-neutral-200',
        className
      )}
      {...props}
    />
  )
)
Input.displayName = 'Input'
export default Input
```

- [ ] **Step 2: Create Label.tsx**

```tsx
import { forwardRef } from 'react'
import { cn } from '@/lib/utils/cn'

interface LabelProps extends React.LabelHTMLAttributes<HTMLLabelElement> {
  required?: boolean
}

const Label = forwardRef<HTMLLabelElement, LabelProps>(
  ({ required, children, className, ...props }, ref) => (
    <label
      ref={ref}
      className={cn('text-sm font-medium text-neutral-700', className)}
      {...props}
    >
      {children}
      {required && <span className="text-red-500 ml-0.5">*</span>}
    </label>
  )
)
Label.displayName = 'Label'
export default Label
```

- [ ] **Step 3: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add frontend/src/components/ui/Input.tsx frontend/src/components/ui/Label.tsx
git commit -m "feat(ui): add Input and Label atoms"
```

---

### Task 3: Select and Textarea atoms

**Files:**
- Create: `frontend/src/components/ui/Select.tsx`
- Create: `frontend/src/components/ui/Textarea.tsx`

- [ ] **Step 1: Create Select.tsx**

```tsx
import { forwardRef } from 'react'
import { cn } from '@/lib/utils/cn'

interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  error?: boolean
}

const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ error, className, ...props }, ref) => (
    <select
      ref={ref}
      className={cn(
        'w-full px-3 py-2.5 text-sm border rounded-lg bg-white transition-colors',
        'focus:outline-none focus:ring-2 focus:ring-brand-500',
        error ? 'border-red-300 focus:ring-red-400' : 'border-neutral-200',
        className
      )}
      {...props}
    />
  )
)
Select.displayName = 'Select'
export default Select
```

- [ ] **Step 2: Create Textarea.tsx**

```tsx
import { forwardRef } from 'react'
import { cn } from '@/lib/utils/cn'

interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  error?: boolean
}

const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ error, className, ...props }, ref) => (
    <textarea
      ref={ref}
      className={cn(
        'w-full px-3 py-2.5 text-sm border rounded-lg bg-white transition-colors resize-none',
        'focus:outline-none focus:ring-2 focus:ring-brand-500',
        error ? 'border-red-300 focus:ring-red-400' : 'border-neutral-200',
        className
      )}
      {...props}
    />
  )
)
Textarea.displayName = 'Textarea'
export default Textarea
```

- [ ] **Step 3: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add frontend/src/components/ui/Select.tsx frontend/src/components/ui/Textarea.tsx
git commit -m "feat(ui): add Select and Textarea atoms"
```

---

### Task 4: AvatarInitial and TableCard molecules

**Files:**
- Create: `frontend/src/components/shared/AvatarInitial.tsx`
- Create: `frontend/src/components/shared/TableCard.tsx`

- [ ] **Step 1: Create AvatarInitial.tsx**

```tsx
import * as Avatar from '@radix-ui/react-avatar'
import { cn } from '@/lib/utils/cn'

const SIZE: Record<'sm' | 'md', string> = {
  sm: 'w-8 h-8 text-xs',
  md: 'w-10 h-10 text-sm',
}

interface AvatarInitialProps {
  name: string
  size?: 'sm' | 'md'
}

export default function AvatarInitial({ name, size = 'sm' }: AvatarInitialProps) {
  return (
    <Avatar.Root
      className={cn(
        'rounded-full bg-brand-50 flex items-center justify-center font-bold text-brand-700 shrink-0',
        SIZE[size]
      )}
    >
      <Avatar.Fallback delayMs={0}>
        {name.charAt(0).toUpperCase()}
      </Avatar.Fallback>
    </Avatar.Root>
  )
}
```

- [ ] **Step 2: Create TableCard.tsx**

```tsx
interface TableCardProps {
  children: React.ReactNode
}

export default function TableCard({ children }: TableCardProps) {
  return (
    <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
      {children}
    </div>
  )
}
```

- [ ] **Step 3: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add frontend/src/components/shared/AvatarInitial.tsx frontend/src/components/shared/TableCard.tsx
git commit -m "feat(shared): add AvatarInitial and TableCard molecules"
```

---

### Task 5: SearchInput molecule

**Files:**
- Create: `frontend/src/components/shared/SearchInput.tsx`

- [ ] **Step 1: Create SearchInput.tsx**

```tsx
import { Search } from 'lucide-react'
import { cn } from '@/lib/utils/cn'

interface SearchInputProps {
  value: string
  onChange: (value: string) => void
  placeholder?: string
  className?: string
}

export default function SearchInput({
  value,
  onChange,
  placeholder = 'Search…',
  className,
}: SearchInputProps) {
  return (
    <div className={cn('relative', className)}>
      <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400 pointer-events-none" />
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full pl-9 pr-4 py-2 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
      />
    </div>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/shared/SearchInput.tsx
git commit -m "feat(shared): add SearchInput molecule"
```

---

### Task 6: FilterTabs molecule

**Files:**
- Create: `frontend/src/components/shared/FilterTabs.tsx`

- [ ] **Step 1: Create FilterTabs.tsx**

```tsx
import { cn } from '@/lib/utils/cn'

interface Tab {
  label: string
  value: string
}

interface FilterTabsProps {
  tabs: Tab[]
  active: string
  onChange: (value: string) => void
}

export default function FilterTabs({ tabs, active, onChange }: FilterTabsProps) {
  return (
    <div className="flex items-center gap-1 bg-white border border-neutral-200 rounded-lg p-1 shrink-0">
      {tabs.map((tab) => (
        <button
          key={tab.value}
          type="button"
          onClick={() => onChange(tab.value)}
          className={cn(
            'px-3 py-1 text-sm font-medium rounded-md transition-colors',
            active === tab.value
              ? 'bg-brand-600 text-white shadow-sm'
              : 'text-neutral-600 hover:bg-neutral-50'
          )}
        >
          {tab.label}
        </button>
      ))}
    </div>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/shared/FilterTabs.tsx
git commit -m "feat(shared): add FilterTabs molecule"
```

---

### Task 7: FormField molecule

**Files:**
- Create: `frontend/src/components/shared/FormField.tsx`

- [ ] **Step 1: Create FormField.tsx**

```tsx
import { ReactNode } from 'react'
import Label from '@/components/ui/Label'
import { cn } from '@/lib/utils/cn'

interface FormFieldProps {
  label: string
  error?: string
  required?: boolean
  children: ReactNode
  className?: string
}

export default function FormField({
  label,
  error,
  required,
  children,
  className,
}: FormFieldProps) {
  return (
    <div className={cn('space-y-1.5', className)}>
      <Label required={required}>{label}</Label>
      {children}
      {error && <p className="text-xs text-red-600">{error}</p>}
    </div>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/shared/FormField.tsx
git commit -m "feat(shared): add FormField molecule"
```

---

### Task 8: FormModal molecule

**Files:**
- Create: `frontend/src/components/shared/FormModal.tsx`

- [ ] **Step 1: Create FormModal.tsx**

```tsx
import { ReactNode } from 'react'
import * as Dialog from '@radix-ui/react-dialog'
import Button from '@/components/ui/Button'

interface FormModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  onSubmit: () => void
  loading?: boolean
  submitLabel?: string
  children: ReactNode
}

export default function FormModal({
  open,
  onOpenChange,
  title,
  onSubmit,
  loading = false,
  submitLabel = 'Save',
  children,
}: FormModalProps) {
  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0" />
        <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-2xl shadow-xl p-6 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95">
          <Dialog.Title className="text-lg font-bold text-neutral-900 mb-5">{title}</Dialog.Title>
          <form
            onSubmit={(e) => { e.preventDefault(); onSubmit() }}
            className="space-y-4"
          >
            {children}
            <div className="flex justify-end gap-2 pt-2">
              <Dialog.Close asChild>
                <Button type="button" variant="secondary">Cancel</Button>
              </Dialog.Close>
              <Button type="submit" loading={loading}>
                {submitLabel}
              </Button>
            </div>
          </form>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/shared/FormModal.tsx
git commit -m "feat(shared): add FormModal molecule (Radix Dialog shell)"
```

---

### Task 9: ListPageTemplate

**Files:**
- Create: `frontend/src/components/templates/ListPageTemplate.tsx`

- [ ] **Step 1: Create ListPageTemplate.tsx**

```tsx
import { ReactNode } from 'react'
import PageHeader from '@/components/shared/PageHeader'
import SearchInput from '@/components/shared/SearchInput'
import FilterTabs from '@/components/shared/FilterTabs'
import TableCard from '@/components/shared/TableCard'
import DataTable, { Column } from '@/components/shared/DataTable'

interface SearchConfig {
  value: string
  onChange: (v: string) => void
  placeholder?: string
}

interface FilterTabsConfig {
  tabs: { label: string; value: string }[]
  active: string
  onChange: (v: string) => void
}

interface ListPageTemplateProps<T> {
  title: string
  subtitle?: string
  actions?: ReactNode

  search?: SearchConfig
  filterTabs?: FilterTabsConfig

  columns: Column<T>[]
  data: T[]
  loading: boolean
  pagination: { page: number; limit: number; total: number }
  onPageChange: (page: number) => void
  rowKey: (row: T) => string
  onRowClick?: (row: T) => void
}

export default function ListPageTemplate<T>({
  title,
  subtitle,
  actions,
  search,
  filterTabs,
  columns,
  data,
  loading,
  pagination,
  onPageChange,
  rowKey,
  onRowClick,
}: ListPageTemplateProps<T>) {
  const hasFilters = search || filterTabs

  return (
    <div className="space-y-5">
      <PageHeader title={title} subtitle={subtitle} actions={actions} />

      {hasFilters && (
        <div className="flex flex-col sm:flex-row gap-3">
          {search && (
            <SearchInput
              value={search.value}
              onChange={search.onChange}
              placeholder={search.placeholder}
              className="flex-1"
            />
          )}
          {filterTabs && (
            <FilterTabs
              tabs={filterTabs.tabs}
              active={filterTabs.active}
              onChange={filterTabs.onChange}
            />
          )}
        </div>
      )}

      <TableCard>
        <DataTable
          columns={columns}
          data={data}
          loading={loading}
          pagination={pagination}
          onPageChange={onPageChange}
          rowKey={rowKey}
          onRowClick={onRowClick}
        />
      </TableCard>
    </div>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/templates/ListPageTemplate.tsx
git commit -m "feat(templates): add ListPageTemplate"
```

---

### Task 10: DetailPageTemplate

**Files:**
- Create: `frontend/src/components/templates/DetailPageTemplate.tsx`

- [ ] **Step 1: Create DetailPageTemplate.tsx**

```tsx
import { ReactNode } from 'react'
import PageHeader from '@/components/shared/PageHeader'

interface Breadcrumb {
  label: string
  href?: string
}

interface DetailPageTemplateProps {
  title: string
  subtitle?: string
  breadcrumbs: Breadcrumb[]
  actions?: ReactNode
  children: ReactNode
}

export default function DetailPageTemplate({
  title,
  subtitle,
  breadcrumbs,
  actions,
  children,
}: DetailPageTemplateProps) {
  return (
    <div className="space-y-6">
      <PageHeader
        title={title}
        subtitle={subtitle}
        breadcrumbs={breadcrumbs}
        actions={actions}
      />
      {children}
    </div>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/templates/DetailPageTemplate.tsx
git commit -m "feat(templates): add DetailPageTemplate"
```

---

### Task 11: CreateStudentModal

**Files:**
- Create: `frontend/src/portals/internal/components/CreateStudentModal.tsx`

- [ ] **Step 1: Create CreateStudentModal.tsx**

```tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useCreateStudent } from '@/lib/api/identity'
import FormModal from '@/components/shared/FormModal'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'

const schema = z.object({
  name: z.string().min(2, 'Name required'),
  email: z.string().email('Valid email required'),
  phone: z.string().min(8, 'Phone required'),
  source: z.enum(['b2c', 'b2b']),
})

type FormData = z.infer<typeof schema>

interface CreateStudentModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

export default function CreateStudentModal({ open, onOpenChange }: CreateStudentModalProps) {
  const createStudent = useCreateStudent()
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { source: 'b2c' },
  })

  const onSubmit = async (data: FormData) => {
    try {
      await createStudent.mutateAsync(data)
      toast.success('Student created')
      onOpenChange(false)
      reset()
    } catch {
      toast.error('Failed to create student')
    }
  }

  return (
    <FormModal
      open={open}
      onOpenChange={onOpenChange}
      title="Add Student"
      onSubmit={handleSubmit(onSubmit)}
      loading={createStudent.isPending}
      submitLabel="Create Student"
    >
      <FormField label="Name" error={errors.name?.message} required>
        <Input {...register('name')} placeholder="Full name" error={!!errors.name} />
      </FormField>
      <FormField label="Email" error={errors.email?.message} required>
        <Input
          {...register('email')}
          type="email"
          placeholder="email@example.com"
          error={!!errors.email}
        />
      </FormField>
      <FormField label="Phone" error={errors.phone?.message} required>
        <Input {...register('phone')} type="tel" placeholder="+62..." error={!!errors.phone} />
      </FormField>
      <FormField label="Source" error={errors.source?.message} required>
        <Select {...register('source')} error={!!errors.source}>
          <option value="b2c">B2C</option>
          <option value="b2b">B2B</option>
        </Select>
      </FormField>
    </FormModal>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/components/CreateStudentModal.tsx
git commit -m "feat(internal): extract CreateStudentModal"
```

---

### Task 12: CreateCourseModal

**Files:**
- Create: `frontend/src/portals/internal/components/CreateCourseModal.tsx`

- [ ] **Step 1: Create CreateCourseModal.tsx**

```tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useCreateCourse } from '@/lib/api/catalog'
import { useDepartments } from '@/lib/api/identity'
import FormModal from '@/components/shared/FormModal'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Textarea from '@/components/ui/Textarea'

const schema = z.object({
  name: z.string().min(3, 'Name required'),
  code: z.string().min(2, 'Code required'),
  department_id: z.string().min(1, 'Department required'),
  description: z.string().min(10, 'Description required'),
  duration_days: z.coerce.number().min(1),
  format: z.enum(['online', 'offline', 'hybrid']),
  status: z.enum(['active', 'inactive']),
})

type FormData = z.infer<typeof schema>

interface CreateCourseModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

export default function CreateCourseModal({ open, onOpenChange }: CreateCourseModalProps) {
  const createCourse = useCreateCourse()
  const { data: departments } = useDepartments()
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { format: 'online', status: 'active' },
  })

  const onSubmit = async (data: FormData) => {
    try {
      await createCourse.mutateAsync(data)
      toast.success('Course created')
      onOpenChange(false)
      reset()
    } catch {
      toast.error('Failed to create course')
    }
  }

  return (
    <FormModal
      open={open}
      onOpenChange={onOpenChange}
      title="Add Course"
      onSubmit={handleSubmit(onSubmit)}
      loading={createCourse.isPending}
      submitLabel="Create Course"
    >
      <FormField label="Name" error={errors.name?.message} required>
        <Input {...register('name')} error={!!errors.name} />
      </FormField>
      <FormField label="Code" error={errors.code?.message} required>
        <Input {...register('code')} className="font-mono uppercase" error={!!errors.code} />
      </FormField>
      <FormField label="Department" error={errors.department_id?.message} required>
        <Select {...register('department_id')} error={!!errors.department_id}>
          <option value="">Select department…</option>
          {(departments?.data ?? []).map((d: { id: string; name: string }) => (
            <option key={d.id} value={d.id}>{d.name}</option>
          ))}
        </Select>
      </FormField>
      <FormField label="Description" error={errors.description?.message} required>
        <Textarea {...register('description')} rows={3} error={!!errors.description} />
      </FormField>
      <FormField label="Duration (days)" error={errors.duration_days?.message} required>
        <Input {...register('duration_days')} type="number" min={1} error={!!errors.duration_days} />
      </FormField>
      <FormField label="Format" error={errors.format?.message}>
        <Select {...register('format')}>
          <option value="online">Online</option>
          <option value="offline">Offline</option>
          <option value="hybrid">Hybrid</option>
        </Select>
      </FormField>
      <FormField label="Status" error={errors.status?.message}>
        <Select {...register('status')}>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </Select>
      </FormField>
    </FormModal>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors. If `departments?.data` type error appears, check the return type of `useDepartments` in `frontend/src/lib/api/identity.ts` and adjust the map type accordingly.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/components/CreateCourseModal.tsx
git commit -m "feat(internal): extract CreateCourseModal"
```

---

### Task 13: CreateFranchiseeModal

**Files:**
- Create: `frontend/src/portals/internal/components/CreateFranchiseeModal.tsx`

- [ ] **Step 1: Create CreateFranchiseeModal.tsx**

```tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useCreateFranchisee } from '@/lib/api/franchise'
import FormModal from '@/components/shared/FormModal'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'

const schema = z.object({
  name: z.string().min(2, 'Name required'),
  branch_name: z.string().min(2, 'Branch name required'),
  location: z.string().min(2, 'Location required'),
  contact: z.string().min(5, 'Contact required'),
})

type FormData = z.infer<typeof schema>

interface CreateFranchiseeModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

export default function CreateFranchiseeModal({ open, onOpenChange }: CreateFranchiseeModalProps) {
  const createFranchisee = useCreateFranchisee()
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormData>({ resolver: zodResolver(schema) })

  const onSubmit = async (data: FormData) => {
    try {
      await createFranchisee.mutateAsync(data)
      toast.success('Franchisee created')
      onOpenChange(false)
      reset()
    } catch {
      toast.error('Failed to create franchisee')
    }
  }

  return (
    <FormModal
      open={open}
      onOpenChange={onOpenChange}
      title="Add Franchisee"
      onSubmit={handleSubmit(onSubmit)}
      loading={createFranchisee.isPending}
      submitLabel="Create Franchisee"
    >
      <FormField label="Name" error={errors.name?.message} required>
        <Input {...register('name')} error={!!errors.name} />
      </FormField>
      <FormField label="Branch Name" error={errors.branch_name?.message} required>
        <Input {...register('branch_name')} error={!!errors.branch_name} />
      </FormField>
      <FormField label="Location" error={errors.location?.message} required>
        <Input {...register('location')} error={!!errors.location} />
      </FormField>
      <FormField label="Contact" error={errors.contact?.message} required>
        <Input {...register('contact')} error={!!errors.contact} />
      </FormField>
    </FormModal>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/components/CreateFranchiseeModal.tsx
git commit -m "feat(internal): extract CreateFranchiseeModal"
```

---

### Task 14: Refactor Students.tsx

**Files:**
- Modify: `frontend/src/portals/internal/pages/Students.tsx`

- [ ] **Step 1: Replace Students.tsx**

```tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useStudents, type Student } from '@/lib/api/identity'
import { formatDate } from '@/lib/utils/format'
import { Column } from '@/components/shared/DataTable'
import { cn } from '@/lib/utils/cn'
import AvatarInitial from '@/components/shared/AvatarInitial'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import CreateStudentModal from '@/portals/internal/components/CreateStudentModal'

const SOURCE_FILTERS = [
  { label: 'All', value: '' },
  { label: 'B2C', value: 'b2c' },
  { label: 'B2B', value: 'b2b' },
]

const LIMIT = 15

const COLUMNS: Column<Student>[] = [
  {
    header: '',
    accessor: 'name',
    className: 'w-10',
    cell: (row) => <AvatarInitial name={row.name} />,
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
          row.source === 'b2b' ? 'bg-violet-50 text-violet-700' : 'bg-brand-50 text-brand-700',
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

export default function Students() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [sourceFilter, setSourceFilter] = useState('')
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
        actions={
          <Button onClick={() => setOpen(true)}>
            <Plus className="w-4 h-4" />
            Add Student
          </Button>
        }
        search={{
          value: search,
          onChange: (v) => { setSearch(v); setPage(1) },
          placeholder: 'Search by name or email…',
        }}
        filterTabs={{
          tabs: SOURCE_FILTERS,
          active: sourceFilter,
          onChange: (v) => { setSourceFilter(v); setPage(1) },
        }}
        columns={COLUMNS}
        data={data?.data ?? []}
        loading={isLoading}
        pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
        onPageChange={setPage}
        rowKey={(row) => row.id}
        onRowClick={(row) => navigate(`/internal/students/${row.id}`)}
      />
      <CreateStudentModal open={open} onOpenChange={setOpen} />
    </>
  )
}
```

- [ ] **Step 2: Typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: no errors

- [ ] **Step 3: Lint**

```bash
cd frontend && npm run lint
```
Expected: no warnings

- [ ] **Step 4: Commit**

```bash
git add frontend/src/portals/internal/pages/Students.tsx
git commit -m "refactor(internal): Students uses ListPageTemplate + CreateStudentModal"
```

---

### Task 15: Refactor Enrollments.tsx (internal)

**Files:**
- Modify: `frontend/src/portals/internal/pages/Enrollments.tsx`

- [ ] **Step 1: Replace Enrollments.tsx**

```tsx
import { useState, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { useEnrollments, type Enrollment } from '@/lib/api/enrollment'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

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
    cell: (row) => (
      <span className="text-xs text-neutral-500">{formatDate(row.enrolled_at)}</span>
    ),
  },
]

export default function Enrollments() {
  const navigate = useNavigate()
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
    <ListPageTemplate
      title="Enrollments"
      subtitle="Manage all student enrollments"
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(row) => row.id}
      onRowClick={(row) => navigate(`/internal/enrollments/${row.id}`)}
    />
  )
}
```

- [ ] **Step 2: Typecheck + Lint**

```bash
cd frontend && npm run typecheck && npm run lint
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/pages/Enrollments.tsx
git commit -m "refactor(internal): Enrollments uses ListPageTemplate"
```

---

### Task 16: Refactor Courses.tsx (internal)

**Files:**
- Modify: `frontend/src/portals/internal/pages/Courses.tsx`

- [ ] **Step 1: Read the full current file to extract COLUMNS and hooks**

Read `frontend/src/portals/internal/pages/Courses.tsx` — keep all COLUMNS and hook calls, replace the Dialog block and render structure.

- [ ] **Step 2: Replace Courses.tsx**

The refactored file keeps all COLUMNS identical. Replace only the Dialog + render section:

```tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useCourses, type Course } from '@/lib/api/catalog'
import StatusBadge from '@/components/shared/StatusBadge'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import CreateCourseModal from '@/portals/internal/components/CreateCourseModal'

const LIMIT = 15

const COLUMNS: Column<Course>[] = [
  { header: 'Code', accessor: 'code', className: 'font-mono text-xs w-24' },
  { header: 'Name', accessor: 'name' },
  {
    header: 'Format',
    accessor: 'format',
    cell: (row) => <span className="capitalize">{row.format}</span>,
  },
  {
    header: 'Duration',
    accessor: 'duration_days',
    cell: (row) => `${row.duration_days} days`,
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (row) => <StatusBadge status={row.status} />,
  },
]

export default function Courses() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [open, setOpen] = useState(false)

  const { data, isLoading } = useCourses({ page, limit: LIMIT })

  return (
    <>
      <ListPageTemplate
        title="Courses"
        subtitle="Manage course catalog"
        actions={
          <Button onClick={() => setOpen(true)}>
            <Plus className="w-4 h-4" />
            Add Course
          </Button>
        }
        columns={COLUMNS}
        data={data?.data ?? []}
        loading={isLoading}
        pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
        onPageChange={setPage}
        rowKey={(row) => row.id}
        onRowClick={(row) => navigate(`/internal/courses/${row.id}`)}
      />
      <CreateCourseModal open={open} onOpenChange={setOpen} />
    </>
  )
}
```

Note: The original Courses.tsx may have additional filter state (check the full file in Step 1). If a status filter exists, add `filterTabs` prop to `ListPageTemplate` with the existing filter values.

- [ ] **Step 3: Typecheck + Lint**

```bash
cd frontend && npm run typecheck && npm run lint
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add frontend/src/portals/internal/pages/Courses.tsx
git commit -m "refactor(internal): Courses uses ListPageTemplate + CreateCourseModal"
```

---

### Task 17: Refactor Payments.tsx (internal)

**Files:**
- Modify: `frontend/src/portals/internal/pages/Payments.tsx`

- [ ] **Step 1: Read the full current file**

Read `frontend/src/portals/internal/pages/Payments.tsx` to get the full COLUMNS definition and the `useUpdateInvoiceStatus` confirm flow.

- [ ] **Step 2: Replace Payments.tsx**

The Payments page uses SubNav for tabs and has a ConfirmDialog for marking paid. Keep both — only replace the outer structure with `ListPageTemplate`:

```tsx
import { useState, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Check } from 'lucide-react'
import { toast } from 'sonner'
import { useInvoices, useUpdateInvoiceStatus, type Invoice } from '@/lib/api/finance'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

const PAYMENT_TABS: SubNavItem[] = [
  { label: 'Pending', value: 'pending' },
  { label: 'All', value: 'all' },
]

const LIMIT = 15

export default function Payments() {
  const navigate = useNavigate()
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

  const handleConfirmPaid = async () => {
    if (!confirmItem) return
    try {
      await updateStatus.mutateAsync({ id: confirmItem.id, status: 'paid' })
      toast.success('Invoice marked as paid')
      setConfirmItem(null)
    } catch {
      toast.error('Failed to update invoice')
    }
  }

  const COLUMNS: Column<Invoice>[] = [
    { header: 'Invoice #', accessor: 'invoice_number' },
    { header: 'Student', accessor: 'student_id' },
    {
      header: 'Amount',
      accessor: 'amount',
      cell: (row) => <span className="font-mono">{formatCurrency(row.amount)}</span>,
    },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <StatusBadge status={row.status} variant="invoice" />,
    },
    {
      header: 'Due',
      accessor: 'due_date',
      cell: (row) => (
        <span className="text-xs text-neutral-500">{formatDate(row.due_date)}</span>
      ),
    },
    {
      header: '',
      accessor: 'id',
      cell: (row) =>
        row.status === 'sent' ? (
          <Button
            variant="ghost"
            size="sm"
            onClick={(e) => { e.stopPropagation(); setConfirmItem(row) }}
          >
            <Check className="w-4 h-4" />
            Mark Paid
          </Button>
        ) : null,
    },
  ]

  return (
    <>
      <ListPageTemplate
        title="Payments"
        subtitle="Manage invoices and payments"
        columns={COLUMNS}
        data={data?.data ?? []}
        loading={isLoading}
        pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
        onPageChange={setPage}
        rowKey={(row) => row.id}
        onRowClick={(row) => navigate(`/internal/payments/${row.id}`)}
      />
      <ConfirmDialog
        open={!!confirmItem}
        title="Mark as Paid"
        description={`Mark invoice ${confirmItem?.invoice_number ?? ''} as paid?`}
        confirmLabel="Mark Paid"
        onConfirm={handleConfirmPaid}
        onCancel={() => setConfirmItem(null)}
      />
    </>
  )
}
```

Note: If `Invoice` type fields differ from the above, read `frontend/src/lib/api/finance.ts` to get the exact field names, then adjust COLUMNS accordingly.

- [ ] **Step 3: Typecheck + Lint**

```bash
cd frontend && npm run typecheck && npm run lint
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add frontend/src/portals/internal/pages/Payments.tsx
git commit -m "refactor(internal): Payments uses ListPageTemplate"
```

---

### Task 18: Refactor Franchises.tsx (internal)

**Files:**
- Modify: `frontend/src/portals/internal/pages/Franchises.tsx`

- [ ] **Step 1: Read the full current file**

Read `frontend/src/portals/internal/pages/Franchises.tsx` — it has two tabs (Franchisees and Royalty) and local StatusBadge sub-components that duplicate the shared one.

- [ ] **Step 2: Replace Franchises.tsx**

The Franchisees tab maps to `ListPageTemplate`. The Royalty tab is a second table — keep it as a separate section below. Replace the local StatusBadge sub-components with the shared `StatusBadge`. COLUMNS are defined inside the component (not at module scope) because `navigate` must be in scope for row click.

```tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import {
  useFranchisees,
  useRoyaltyRecords,
  type Franchisee,
  type RoyaltyRecord,
} from '@/lib/api/franchise'
import { formatCurrency } from '@/lib/utils/format'
import { Column } from '@/components/shared/DataTable'
import StatusBadge from '@/components/shared/StatusBadge'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import TableCard from '@/components/shared/TableCard'
import DataTable from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import Button from '@/components/ui/Button'
import FilterTabs from '@/components/shared/FilterTabs'
import CreateFranchiseeModal from '@/portals/internal/components/CreateFranchiseeModal'

const TABS = [
  { label: 'Franchisees', value: 'Franchisees' },
  { label: 'Royalty', value: 'Royalty' },
]

const LIMIT = 15

export default function Franchises() {
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState('Franchisees')
  const [page, setPage] = useState(1)
  const [open, setOpen] = useState(false)

  const { data: franchiseeData, isLoading: franchiseeLoading } = useFranchisees({ page, limit: LIMIT })
  const { data: royaltyData, isLoading: royaltyLoading } = useRoyaltyRecords({ page, limit: LIMIT })

  const FRANCHISEE_COLUMNS: Column<Franchisee>[] = [
    { header: 'Name', accessor: 'name' },
    { header: 'Branch', accessor: 'branch_name' },
    { header: 'Location', accessor: 'location' },
    { header: 'Contact', accessor: 'contact' },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <StatusBadge status={row.status} />,
    },
  ]

  const ROYALTY_COLUMNS: Column<RoyaltyRecord>[] = [
    { header: 'Franchisee', accessor: 'franchisee_id' },
    { header: 'Period', accessor: 'period' },
    {
      header: 'Amount',
      accessor: 'amount',
      cell: (row) => <span className="font-mono">{formatCurrency(row.amount)}</span>,
    },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <StatusBadge status={row.status} />,
    },
  ]

  const tabSwitcher = (
    <FilterTabs
      tabs={TABS}
      active={activeTab}
      onChange={(v) => { setActiveTab(v); setPage(1) }}
    />
  )

  if (activeTab === 'Royalty') {
    return (
      <div className="space-y-5">
        <PageHeader title="Franchises" subtitle="Manage franchise network" actions={tabSwitcher} />
        <TableCard>
          <DataTable
            columns={ROYALTY_COLUMNS}
            data={royaltyData?.data ?? []}
            loading={royaltyLoading}
            pagination={{ page, limit: LIMIT, total: royaltyData?.total ?? 0 }}
            onPageChange={setPage}
            rowKey={(row) => row.id}
          />
        </TableCard>
      </div>
    )
  }

  return (
    <>
      <ListPageTemplate
        title="Franchises"
        subtitle="Manage franchise network"
        actions={
          <div className="flex items-center gap-2">
            {tabSwitcher}
            <Button onClick={() => setOpen(true)}>
              <Plus className="w-4 h-4" />
              Add Franchisee
            </Button>
          </div>
        }
        columns={FRANCHISEE_COLUMNS}
        data={franchiseeData?.data ?? []}
        loading={franchiseeLoading}
        pagination={{ page, limit: LIMIT, total: franchiseeData?.total ?? 0 }}
        onPageChange={setPage}
        rowKey={(row) => row.id}
        onRowClick={(row) => navigate(`/internal/franchises/${row.id}`)}
      />
      <CreateFranchiseeModal open={open} onOpenChange={setOpen} />
    </>
  )
}
```

Note: Read the full `Franchises.tsx` in Step 1 — field names on `Franchisee` and `RoyaltyRecord` types may differ. Adjust COLUMNS to match exact field names from `frontend/src/lib/api/franchise.ts`. If `useMarkRoyaltyPaid` exists in the original, check if it's used in the Royalty tab and preserve that logic.

- [ ] **Step 3: Typecheck + Lint**

```bash
cd frontend && npm run typecheck && npm run lint
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add frontend/src/portals/internal/pages/Franchises.tsx
git commit -m "refactor(internal): Franchises uses ListPageTemplate + shared StatusBadge"
```

---

### Task 19: Refactor franchise portal Enrollments.tsx

**Files:**
- Modify: `frontend/src/portals/franchise/pages/Enrollments.tsx`

- [ ] **Step 1: Read the full current file**

Read `frontend/src/portals/franchise/pages/Enrollments.tsx` — get the full COLUMNS and hook calls.

- [ ] **Step 2: Replace with ListPageTemplate**

Pattern: same as internal Enrollments (Task 15) — SubNav tabs via `useSubNav`, no create action.

```tsx
import { useState, useMemo } from 'react'
import { useEnrollments, type Enrollment } from '@/lib/api/enrollment'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

const STATUS_TABS: SubNavItem[] = [
  { label: 'All', value: '' },
  { label: 'Pending', value: 'pending' },
  { label: 'Confirmed', value: 'confirmed' },
  { label: 'Completed', value: 'completed' },
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
    cell: (row) => (
      <span className="text-xs text-neutral-500">{formatDate(row.enrolled_at)}</span>
    ),
  },
]

export default function FranchiseEnrollments() {
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
    <ListPageTemplate
      title="Enrollments"
      subtitle="View franchise enrollments"
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(row) => row.id}
    />
  )
}
```

Note: The `useEnrollments` hook may accept a `franchisee_id` filter for franchise context. Check `frontend/src/lib/api/enrollment.ts` and add the filter if the hook supports it.

- [ ] **Step 3: Typecheck + Lint**

```bash
cd frontend && npm run typecheck && npm run lint
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add frontend/src/portals/franchise/pages/Enrollments.tsx
git commit -m "refactor(franchise): Enrollments uses ListPageTemplate"
```

---

### Task 20: Refactor remaining pages (Partners, TeamMembers, franchise Payments + TeamMembers, student CourseCatalog + MyEnrollments)

**Files:**
- Modify: `frontend/src/portals/internal/pages/Partners.tsx`
- Modify: `frontend/src/portals/internal/pages/TeamMembers.tsx`
- Modify: `frontend/src/portals/franchise/pages/Payments.tsx`
- Modify: `frontend/src/portals/franchise/pages/TeamMembers.tsx`
- Modify: `frontend/src/portals/student/pages/CourseCatalog.tsx`
- Modify: `frontend/src/portals/student/pages/MyEnrollments.tsx`

Each file follows the same refactor pattern. Do them one at a time:

- [ ] **Step 1: For each file, read the full current content**

Read each file before editing to get exact column definitions, hook names, and type imports.

- [ ] **Step 2: Refactor Partners.tsx**

Replace render with `ListPageTemplate`. Keep COLUMNS inside the component if any cell references `navigate`. Apply this structure:

```tsx
// Structure — fill in actual imports and COLUMNS from Step 1 read
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
// ... other imports from current file

export default function Partners() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  // ... other state from current file

  const COLUMNS = [ /* copy from current file */ ]

  const { data, isLoading } = usePartners({ page, limit: LIMIT })

  return (
    <ListPageTemplate
      title="Partners"
      subtitle="Manage business partners"
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(row) => row.id}
      onRowClick={(row) => navigate(`/internal/partners/${row.id}`)}
    />
  )
}
```

- [ ] **Step 3: Refactor internal TeamMembers.tsx**

Same pattern as Partners. Read current file, extract COLUMNS and hook name, wrap with `ListPageTemplate`. Add create modal if a Dialog exists in current file — extract it to `portals/internal/components/CreateTeamMemberModal.tsx` using `FormModal` + `FormField` + ui atoms.

- [ ] **Step 4: Refactor franchise Payments.tsx**

Read current file. If it uses `useSubNav` tabs, keep that and wrap with `ListPageTemplate` (no `filterTabs` prop — tabs handled by SubNav). If it has a confirm action (mark paid), keep `ConfirmDialog` alongside `ListPageTemplate` as in Task 17.

- [ ] **Step 5: Refactor franchise TeamMembers.tsx**

Read current file. Same pattern as internal TeamMembers but franchise-scoped data.

- [ ] **Step 6: Refactor student CourseCatalog.tsx**

Read current file. If it has a search input, pass it via the `search` prop. No create action (students can't create courses).

- [ ] **Step 7: Refactor student MyEnrollments.tsx**

Read current file. Likely uses SubNav tabs for status. Wrap with `ListPageTemplate`.

- [ ] **Step 8: Typecheck + Lint after all six files**

```bash
cd frontend && npm run typecheck && npm run lint
```
Expected: 0 errors, 0 warnings

- [ ] **Step 9: Commit**

```bash
git add \
  frontend/src/portals/internal/pages/Partners.tsx \
  frontend/src/portals/internal/pages/TeamMembers.tsx \
  frontend/src/portals/franchise/pages/Payments.tsx \
  frontend/src/portals/franchise/pages/TeamMembers.tsx \
  frontend/src/portals/student/pages/CourseCatalog.tsx \
  frontend/src/portals/student/pages/MyEnrollments.tsx
git commit -m "refactor: remaining pages use ListPageTemplate"
```

---

### Task 21: Final typecheck, lint, and verification

**Files:** No new files

- [ ] **Step 1: Full typecheck**

```bash
cd frontend && npm run typecheck
```
Expected: 0 errors

- [ ] **Step 2: Full lint**

```bash
cd frontend && npm run lint
```
Expected: 0 warnings (--max-warnings 0 is configured)

- [ ] **Step 3: Start dev server and visually verify**

```bash
cd frontend && npm run dev
```

Open browser and check these routes:
- `/internal/students` — search bar + filter tabs + table visible, Add Student button opens modal
- `/internal/enrollments` — SubNav tabs work, table visible  
- `/internal/courses` — table visible, Add Course button opens modal with all fields
- `/internal/payments` — SubNav tabs work, Mark Paid action works
- `/internal/franchises` — tab switching between Franchisees and Royalty works

- [ ] **Step 4: Final commit**

```bash
git commit --allow-empty -m "chore: shared components migration complete (21 tasks)"
```
