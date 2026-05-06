# Franchisee Frontend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Franchisee pages (List, Form, Detail) to the Pengembangan section of the React dashboard.

**Architecture:** Follows existing dashboard patterns — `franchisee.service.ts` for API calls, `ListPageTemplate` / `FormPageTemplate` / `DetailPageTemplate` for UI, nav item added as a named constant to avoid shifting `ALL_ITEMS` indices, routes added to `routes.tsx`.

**Tech Stack:** React 18, TypeScript, React Router 6, TanStack React Query 5, CSS Modules, Vitest + RTL

---

## File Map

| Action | File |
|---|---|
| Create | `web-dashboard/src/services/franchisee.service.ts` |
| Create | `web-dashboard/src/pages/Franchisee/FranchiseeListPage.tsx` |
| Create | `web-dashboard/src/pages/Franchisee/FranchiseeFormPage.tsx` |
| Create | `web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx` |
| Create | `web-dashboard/src/pages/Franchisee/__tests__/FranchiseeListPage.test.tsx` |
| Create | `web-dashboard/src/pages/Franchisee/__tests__/FranchiseeFormPage.test.tsx` |
| Modify | `web-dashboard/src/layouts/AppSidebar/navItems.ts` |
| Modify | `web-dashboard/src/app/routes.tsx` |

---

## Task 1: Service Layer

**Files:**
- Create: `web-dashboard/src/services/franchisee.service.ts`

- [ ] **Step 1: Write the failing test**

Create `web-dashboard/src/services/__tests__/franchisee.service.test.ts`:

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { franchiseeService } from '../franchisee.service'
import { apiClient } from '../api.client'

vi.mock('../api.client', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
  },
}))

describe('franchiseeService', () => {
  beforeEach(() => vi.clearAllMocks())

  it('list calls GET /franchisees with params', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: { data: [], total: 0, offset: 0, limit: 20 } })
    await franchiseeService.list({ offset: 0, limit: 20 })
    expect(apiClient.get).toHaveBeenCalledWith('/franchisees', { params: { offset: 0, limit: 20 } })
  })

  it('getById calls GET /franchisees/:id', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: { id: 'abc' } })
    await franchiseeService.getById('abc')
    expect(apiClient.get).toHaveBeenCalledWith('/franchisees/abc')
  })

  it('create calls POST /franchisees', async () => {
    vi.mocked(apiClient.post).mockResolvedValue({})
    await franchiseeService.create({ name: 'PT X', branch_name: 'Branch A', location: 'Jkt', contact: '', status: 'active' })
    expect(apiClient.post).toHaveBeenCalledWith('/franchisees', expect.objectContaining({ name: 'PT X' }))
  })

  it('update calls PUT /franchisees/:id', async () => {
    vi.mocked(apiClient.put).mockResolvedValue({})
    await franchiseeService.update('abc', { name: 'PT Y', branch_name: 'Branch B', location: 'Sby', contact: '', status: 'inactive' })
    expect(apiClient.put).toHaveBeenCalledWith('/franchisees/abc', expect.objectContaining({ name: 'PT Y' }))
  })
})
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd web-dashboard && npx vitest run src/services/__tests__/franchisee.service.test.ts
```

Expected: `Cannot find module '../franchisee.service'`

- [ ] **Step 3: Create franchisee.service.ts**

```typescript
import { apiClient } from './api.client'

export interface Franchisee {
  id: string
  name: string
  branch_name: string
  location: string
  contact: string
  status: 'active' | 'inactive' | 'terminated'
  created_at: string
  updated_at?: string
  [key: string]: unknown
}

export interface FranchiseAgreement {
  id: string
  franchisee_id: string
  buy_in_fee: number
  monthly_royalty: number
  revenue_royalty_pct: number
  start_date: string
  end_date?: string
  status: string
  created_at: string
  [key: string]: unknown
}

export interface RoyaltyPayment {
  id: string
  period: string
  gross_revenue: number
  monthly_royalty: number
  revenue_royalty: number
  total_royalty: number
  status: 'unpaid' | 'overdue' | 'paid'
  paid_at?: string
  created_at: string
  [key: string]: unknown
}

export interface OtherRevenue {
  id: string
  label: string
  amount: number
  revenue_date: string
  created_at: string
  [key: string]: unknown
}

export interface CreateFranchiseePayload {
  name: string
  branch_name: string
  location: string
  contact: string
  status: string
}

export interface ListParams {
  offset?: number
  limit?: number
  status?: string
  search?: string
}

function extractList<T>(res: unknown): { data: T[]; total: number; offset: number; limit: number } {
  const outer = (res as { data?: unknown })?.data ?? res
  if (Array.isArray(outer)) return { data: outer as T[], total: (outer as T[]).length, offset: 0, limit: (outer as T[]).length }
  const inner = (outer as { data?: unknown })?.data
  if (Array.isArray(inner)) {
    const o = outer as { data: T[]; total: number; offset: number; limit: number }
    return { data: o.data, total: o.total, offset: o.offset, limit: o.limit }
  }
  return { data: [], total: 0, offset: 0, limit: 20 }
}

function extractSingle<T>(res: unknown): T {
  return ((res as { data?: unknown })?.data ?? res) as T
}

export const franchiseeService = {
  async list(params?: ListParams) {
    const res = await apiClient.get('/franchisees', { params })
    return extractList<Franchisee>(res)
  },

  async getById(id: string): Promise<Franchisee> {
    const res = await apiClient.get(`/franchisees/${id}`)
    return extractSingle<Franchisee>(res)
  },

  async create(payload: CreateFranchiseePayload): Promise<void> {
    await apiClient.post('/franchisees', payload)
  },

  async update(id: string, payload: CreateFranchiseePayload): Promise<void> {
    await apiClient.put(`/franchisees/${id}`, payload)
  },

  async getAgreement(franchiseeId: string): Promise<FranchiseAgreement> {
    const res = await apiClient.get(`/franchisees/${franchiseeId}/agreement`)
    return extractSingle<FranchiseAgreement>(res)
  },

  async createAgreement(franchiseeId: string, payload: Omit<FranchiseAgreement, 'id' | 'franchisee_id' | 'created_at'>): Promise<void> {
    await apiClient.post(`/franchisees/${franchiseeId}/agreement`, payload)
  },

  async updateAgreement(franchiseeId: string, agrId: string, payload: Omit<FranchiseAgreement, 'id' | 'franchisee_id' | 'created_at'>): Promise<void> {
    await apiClient.put(`/franchisees/${franchiseeId}/agreement/${agrId}`, payload)
  },

  async listRoyaltyPayments(franchiseeId: string, period?: string): Promise<RoyaltyPayment[]> {
    const res = await apiClient.get(`/franchisees/${franchiseeId}/royalty-payments`, { params: period ? { period } : {} })
    const result = extractSingle<{ data: RoyaltyPayment[] }>(res)
    return result?.data ?? []
  },

  async createRoyaltyPayment(franchiseeId: string, payload: { period: string; gross_revenue: number }): Promise<void> {
    await apiClient.post(`/franchisees/${franchiseeId}/royalty-payments`, payload)
  },

  async markRoyaltyPaid(franchiseeId: string, rpId: string): Promise<void> {
    await apiClient.put(`/franchisees/${franchiseeId}/royalty-payments/${rpId}/mark-paid`, {})
  },

  async listOtherRevenue(franchiseeId: string, period?: string): Promise<OtherRevenue[]> {
    const res = await apiClient.get(`/franchisees/${franchiseeId}/other-revenue`, { params: period ? { period } : {} })
    const result = extractSingle<{ data: OtherRevenue[] }>(res)
    return result?.data ?? []
  },

  async createOtherRevenue(franchiseeId: string, payload: { label: string; amount: number; revenue_date: string }): Promise<void> {
    await apiClient.post(`/franchisees/${franchiseeId}/other-revenue`, payload)
  },

  async updateOtherRevenue(franchiseeId: string, revId: string, payload: { label: string; amount: number; revenue_date: string }): Promise<void> {
    await apiClient.put(`/franchisees/${franchiseeId}/other-revenue/${revId}`, payload)
  },

  async deleteOtherRevenue(franchiseeId: string, revId: string): Promise<void> {
    await apiClient.delete(`/franchisees/${franchiseeId}/other-revenue/${revId}`)
  },
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd web-dashboard && npx vitest run src/services/__tests__/franchisee.service.test.ts
```

Expected: all 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/services/franchisee.service.ts web-dashboard/src/services/__tests__/franchisee.service.test.ts
git commit -m "feat(franchisee): add franchisee service"
```

---

## Task 2: Nav Item + Route Registration

**Files:**
- Modify: `web-dashboard/src/layouts/AppSidebar/navItems.ts`
- Modify: `web-dashboard/src/app/routes.tsx`

- [ ] **Step 1: Add franchisees nav item to navItems.ts**

In `navItems.ts`, add `Store` to the lucide-react import at the top of the file.

Then find this block (around line 167):

```typescript
// ─── All nav items ──────────────────────────────────────────────────────────────

const ALL_ITEMS: NavItem[] = [
```

Add a named constant BEFORE `ALL_ITEMS` declaration:

```typescript
const FRANCHISEE_ITEM: NavItem = {
  key: 'franchisees',
  label: 'Franchisee',
  icon: Store,
  path: '/pengembangan/franchisees',
  hasAccess: (ctx) => hasRole(ctx, 'director'),
}
```

Then find the Pengembangan section (around line 501):

```typescript
  {
    key: 'pengembangan',
    label: 'Pengembangan',
    icon: Rocket,
    items: [ALL_ITEMS[9], ...ALL_ITEMS.slice(16, 18)], // Lokasi, Proyek, Business Dev
  },
```

Update it to:

```typescript
  {
    key: 'pengembangan',
    label: 'Pengembangan',
    icon: Rocket,
    items: [ALL_ITEMS[9], ...ALL_ITEMS.slice(16, 18), FRANCHISEE_ITEM], // Lokasi, Proyek, Business Dev, Franchisee
  },
```

- [ ] **Step 2: Verify TypeScript compiles**

```bash
cd web-dashboard && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 3: Add routes to routes.tsx**

Find where `FranchiseManagementPage` is imported (around line 134). Add lazy imports after it:

```typescript
const FranchiseeListPage   = lazy(() => import('@/pages/Franchisee/FranchiseeListPage'))
const FranchiseeFormPage   = lazy(() => import('@/pages/Franchisee/FranchiseeFormPage'))
const FranchiseeDetailPage = lazy(() => import('@/pages/Franchisee/FranchiseeDetailPage'))
```

Then find the route where `FranchiseManagementPage` is registered (around line 322):

```typescript
{ path: 'business-development/franchise', element: <S><FranchiseManagementPage /></S> },
```

Add after it (still inside the same parent route block):

```typescript
{ path: 'pengembangan/franchisees',         element: <S><FranchiseeListPage /></S> },
{ path: 'pengembangan/franchisees/new',     element: <S><FranchiseeFormPage /></S> },
{ path: 'pengembangan/franchisees/:id',     element: <S><FranchiseeDetailPage /></S> },
{ path: 'pengembangan/franchisees/:id/edit', element: <S><FranchiseeFormPage /></S> },
```

Note: `S` is the `<Suspense>` wrapper — check the existing route file for the exact variable name used.

- [ ] **Step 4: Verify TypeScript**

```bash
cd web-dashboard && npx tsc --noEmit
```

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/layouts/AppSidebar/navItems.ts web-dashboard/src/app/routes.tsx
git commit -m "feat(franchisee): add nav item and routes"
```

---

## Task 3: FranchiseeListPage

**Files:**
- Create: `web-dashboard/src/pages/Franchisee/FranchiseeListPage.tsx`
- Create: `web-dashboard/src/pages/Franchisee/__tests__/FranchiseeListPage.test.tsx`

- [ ] **Step 1: Write failing test**

```typescript
// web-dashboard/src/pages/Franchisee/__tests__/FranchiseeListPage.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import FranchiseeListPage from '../FranchiseeListPage'

vi.mock('@/services/franchisee.service', () => ({
  franchiseeService: {
    list: vi.fn().mockResolvedValue({ data: [], total: 0, offset: 0, limit: 20 }),
  },
}))

vi.mock('@/widgets/ListPageTemplate/ListPageTemplate', () => ({
  ListPageTemplate: ({ title }: { title: string }) => <div data-testid="list-page">{title}</div>,
}))

function wrapper({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      <MemoryRouter>{children}</MemoryRouter>
    </QueryClientProvider>
  )
}

describe('FranchiseeListPage', () => {
  it('renders list page with correct title', () => {
    render(<FranchiseeListPage />, { wrapper })
    expect(screen.getByTestId('list-page')).toHaveTextContent('Franchisee')
  })
})
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd web-dashboard && npx vitest run src/pages/Franchisee/__tests__/FranchiseeListPage.test.tsx
```

Expected: `Cannot find module '../FranchiseeListPage'`

- [ ] **Step 3: Create FranchiseeListPage.tsx**

```typescript
import { useNavigate } from 'react-router-dom'
import { Store } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef } from '@/widgets/DataTable/DataTable'
import { franchiseeService, type Franchisee } from '@/services/franchisee.service'

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:     { label: 'Aktif',       bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  inactive:   { label: 'Tidak Aktif', bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  terminated: { label: 'Dihentikan',  bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
}

const columns: ColumnDef<Franchisee>[] = [
  {
    key: 'name',
    header: 'Franchisee',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Store size={16} />
        </div>
        <div>
          <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.name}</div>
          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)' }}>{row.branch_name}</div>
        </div>
      </div>
    ),
  },
  {
    key: 'location',
    header: 'Lokasi',
    width: 200,
    render: (_v, row) => row.location || '—',
  },
  {
    key: 'status',
    header: 'Status',
    width: 130,
    align: 'center',
    render: (_v, row) => {
      const cfg = STATUS_CONFIG[row.status] ?? STATUS_CONFIG.inactive
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: cfg.bg, color: cfg.color,
        }}>
          {cfg.label}
        </span>
      )
    },
  },
]

export default function FranchiseeListPage() {
  const navigate = useNavigate()

  return (
    <ListPageTemplate<Franchisee>
      title="Franchisee"
      addLabel="Tambah Franchisee"
      onAdd={() => navigate('/pengembangan/franchisees/new')}
      queryKey="franchisees"
      fetcher={(params) => franchiseeService.list(params)}
      columns={columns}
      onRowClick={(row) => navigate(`/pengembangan/franchisees/${row.id}`)}
      searchPlaceholder="Cari franchisee..."
      exportFilename="franchisee"
      emptyTitle="Belum ada franchisee"
      emptyDescription="Tambahkan franchisee untuk mengelola cabang dan royalti."
      helpTitle="Franchisee"
      helpText="Franchisee adalah investor atau pemilik lokasi cabang VernonEdu. VernonEdu mengelola operasional penuh; franchisee mendapatkan laporan pendapatan cabang."
      // NOTE: verify exact prop name for filters by reading ListPageTemplate source before implementing
    />
  )
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd web-dashboard && npx vitest run src/pages/Franchisee/__tests__/FranchiseeListPage.test.tsx
```

Expected: 1 test passes.

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/pages/Franchisee/FranchiseeListPage.tsx web-dashboard/src/pages/Franchisee/__tests__/FranchiseeListPage.test.tsx
git commit -m "feat(franchisee): add FranchiseeListPage"
```

---

## Task 4: FranchiseeFormPage

**Files:**
- Create: `web-dashboard/src/pages/Franchisee/FranchiseeFormPage.tsx`
- Create: `web-dashboard/src/pages/Franchisee/__tests__/FranchiseeFormPage.test.tsx`

- [ ] **Step 1: Write failing test**

```typescript
// web-dashboard/src/pages/Franchisee/__tests__/FranchiseeFormPage.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import FranchiseeFormPage from '../FranchiseeFormPage'

vi.mock('@/services/franchisee.service', () => ({
  franchiseeService: {
    getById: vi.fn().mockResolvedValue({ id: '1', name: 'PT X', branch_name: 'B', location: 'L', contact: '', status: 'active' }),
    create: vi.fn().mockResolvedValue(undefined),
    update: vi.fn().mockResolvedValue(undefined),
  },
}))

vi.mock('@/widgets/FormPageTemplate', () => ({
  FormPageTemplate: ({ title }: { title: string }) => <div data-testid="form-page">{title}</div>,
  Field: () => null,
  FormGrid: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  FormColumn: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  Toggle: () => null,
}))

function wrapper({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      <MemoryRouter initialEntries={['/pengembangan/franchisees/new']}>
        <Routes>
          <Route path="/pengembangan/franchisees/new" element={children} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('FranchiseeFormPage', () => {
  it('renders Tambah Franchisee title in new mode', () => {
    render(<FranchiseeFormPage />, { wrapper })
    expect(screen.getByTestId('form-page')).toHaveTextContent('Tambah Franchisee')
  })
})
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd web-dashboard && npx vitest run src/pages/Franchisee/__tests__/FranchiseeFormPage.test.tsx
```

Expected: `Cannot find module '../FranchiseeFormPage'`

- [ ] **Step 3: Create FranchiseeFormPage.tsx**

```typescript
import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Store } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { franchiseeService } from '@/services/franchisee.service'

const STATUS_OPTIONS = [
  { value: 'active',     label: 'Aktif' },
  { value: 'inactive',   label: 'Tidak Aktif' },
  { value: 'terminated', label: 'Dihentikan' },
]

export default function FranchiseeFormPage() {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(id)

  const [name, setName]             = useState('')
  const [branchName, setBranchName] = useState('')
  const [location, setLocation]     = useState('')
  const [contact, setContact]       = useState('')
  const [status, setStatus]         = useState('active')
  const [errors, setErrors]         = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError]   = useState('')

  const { data: franchisee } = useQuery({
    queryKey: ['franchisee', id],
    queryFn: () => franchiseeService.getById(id!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (franchisee) {
      setName(franchisee.name ?? '')
      setBranchName(franchisee.branch_name ?? '')
      setLocation(franchisee.location ?? '')
      setContact(franchisee.contact ?? '')
      setStatus(franchisee.status ?? 'active')
    }
  }, [franchisee])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama franchisee wajib diisi'
    if (!branchName.trim()) e.branchName = 'Nama branch wajib diisi'
    if (!status) e.status = 'Status wajib dipilih'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return
    setIsSubmitting(true)
    setServerError('')
    try {
      const payload = { name: name.trim(), branch_name: branchName.trim(), location: location.trim(), contact: contact.trim(), status }
      if (isEdit) {
        await franchiseeService.update(id!, payload)
        await queryClient.invalidateQueries({ queryKey: ['franchisee', id] })
        toast.success('Franchisee berhasil diperbarui')
        navigate(`/pengembangan/franchisees/${id}`)
      } else {
        await franchiseeService.create(payload)
        await queryClient.invalidateQueries({ queryKey: ['franchisees'] })
        toast.success('Franchisee berhasil ditambahkan')
        navigate('/pengembangan/franchisees')
      }
    } catch {
      setServerError('Terjadi kesalahan, coba lagi')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Franchisee' : 'Tambah Franchisee'}
      subtitle={isEdit ? franchisee?.name : 'Data franchisee baru'}
      icon={<Store size={20} />}
      onSubmit={handleSubmit}
      onCancel={() => isEdit ? navigate(`/pengembangan/franchisees/${id}`) : navigate('/pengembangan/franchisees')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    >
      <FormGrid>
        <FormColumn>
          <Field
            label="Nama Franchisee / Investor"
            required
            error={errors.name}
          >
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. PT Maju Jaya"
            />
          </Field>
          <Field
            label="Nama Branch"
            required
            error={errors.branchName}
          >
            <input
              value={branchName}
              onChange={(e) => setBranchName(e.target.value)}
              placeholder="e.g. Surabaya Branch"
            />
          </Field>
        </FormColumn>
        <FormColumn>
          <Field label="Lokasi">
            <input
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              placeholder="e.g. Surabaya, Jawa Timur"
            />
          </Field>
          <Field label="Kontak">
            <input
              value={contact}
              onChange={(e) => setContact(e.target.value)}
              placeholder="e.g. 08123456789"
            />
          </Field>
          <Field label="Status" required error={errors.status}>
            <select value={status} onChange={(e) => setStatus(e.target.value)}>
              {STATUS_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>{opt.label}</option>
              ))}
            </select>
          </Field>
        </FormColumn>
      </FormGrid>
    </FormPageTemplate>
  )
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd web-dashboard && npx vitest run src/pages/Franchisee/__tests__/FranchiseeFormPage.test.tsx
```

Expected: 1 test passes.

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/pages/Franchisee/FranchiseeFormPage.tsx web-dashboard/src/pages/Franchisee/__tests__/FranchiseeFormPage.test.tsx
git commit -m "feat(franchisee): add FranchiseeFormPage"
```

---

## Task 5: FranchiseeDetailPage

**Files:**
- Create: `web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx`

- [ ] **Step 1: Create FranchiseeDetailPage.tsx**

```typescript
import { useParams, useNavigate } from 'react-router-dom'
import { Store, Pencil } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { franchiseeService } from '@/services/franchisee.service'
import type { Franchisee, FranchiseAgreement, RoyaltyPayment, OtherRevenue } from '@/services/franchisee.service'

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:     { label: 'Aktif',       bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  inactive:   { label: 'Tidak Aktif', bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  terminated: { label: 'Dihentikan',  bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
}

const ROYALTY_STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  unpaid:  { label: 'Belum Bayar', bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  overdue: { label: 'Terlambat',   bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
  paid:    { label: 'Lunas',       bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
}

function InfoRow({ label, value }: { label: string; value?: string | null }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: 'var(--space-2) 0', borderBottom: '1px solid var(--color-border)' }}>
      <span style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>{label}</span>
      <span style={{ fontWeight: 500, fontSize: 'var(--font-sm)' }}>{value || '—'}</span>
    </div>
  )
}

function StatusBadge({ status, config }: { status: string; config: Record<string, { label: string; bg: string; color: string }> }) {
  const cfg = config[status] ?? config.inactive ?? { label: status, bg: 'var(--color-surface-alt)', color: 'var(--color-text-secondary)' }
  return (
    <span style={{
      display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
      fontSize: 'var(--font-xs)', fontWeight: 600,
      background: cfg.bg, color: cfg.color,
    }}>
      {cfg.label}
    </span>
  )
}

function formatCurrency(n?: number) {
  if (n == null) return '—'
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(n)
}

function formatDate(s?: string | null) {
  if (!s) return '—'
  try {
    return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(s))
  } catch {
    return s
  }
}

function InfoSection({ franchisee }: { franchisee: Franchisee }) {
  return (
    <div>
      <InfoRow label="Nama" value={franchisee.name} />
      <InfoRow label="Nama Branch" value={franchisee.branch_name} />
      <InfoRow label="Lokasi" value={franchisee.location} />
      <InfoRow label="Kontak" value={franchisee.contact} />
      <div style={{ display: 'flex', justifyContent: 'space-between', padding: 'var(--space-2) 0', borderBottom: '1px solid var(--color-border)' }}>
        <span style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>Status</span>
        <StatusBadge status={franchisee.status} config={STATUS_CONFIG} />
      </div>
      <InfoRow label="Dibuat" value={formatDate(franchisee.created_at)} />
    </div>
  )
}

function AgreementSection({ franchiseeId }: { franchiseeId: string }) {
  const { data: agreement, isLoading } = useQuery<FranchiseAgreement>({
    queryKey: ['franchisee-agreement', franchiseeId],
    queryFn: () => franchiseeService.getAgreement(franchiseeId),
    retry: false,
  })

  if (isLoading) return <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Memuat...</div>
  if (!agreement) return <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Belum ada perjanjian.</div>

  return (
    <div>
      <InfoRow label="Buy-in Fee" value={formatCurrency(agreement.buy_in_fee)} />
      <InfoRow label="Royalti Bulanan (tetap)" value={formatCurrency(agreement.monthly_royalty)} />
      <InfoRow label="Royalti Pendapatan" value={`${agreement.revenue_royalty_pct}%`} />
      <InfoRow label="Tanggal Mulai" value={formatDate(agreement.start_date)} />
      <InfoRow label="Tanggal Berakhir" value={formatDate(agreement.end_date)} />
      <div style={{ display: 'flex', justifyContent: 'space-between', padding: 'var(--space-2) 0', borderBottom: '1px solid var(--color-border)' }}>
        <span style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>Status</span>
        <StatusBadge status={agreement.status} config={STATUS_CONFIG} />
      </div>
    </div>
  )
}

function RoyaltySection({ franchiseeId }: { franchiseeId: string }) {
  const { data: payments = [], isLoading } = useQuery<RoyaltyPayment[]>({
    queryKey: ['franchisee-royalty', franchiseeId],
    queryFn: () => franchiseeService.listRoyaltyPayments(franchiseeId),
  })

  if (isLoading) return <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Memuat...</div>
  if (payments.length === 0) return <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Belum ada catatan royalti.</div>

  return (
    <div style={{ overflowX: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 'var(--font-sm)' }}>
        <thead>
          <tr style={{ borderBottom: '2px solid var(--color-border)' }}>
            {['Periode', 'Gross Revenue', 'Royalti Bulanan', 'Royalti Revenue', 'Total', 'Status', 'Dibayar'].map(h => (
              <th key={h} style={{ padding: 'var(--space-2)', textAlign: 'left', color: 'var(--color-text-secondary)', fontWeight: 600 }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {payments.map((p) => (
            <tr key={p.id} style={{ borderBottom: '1px solid var(--color-border)' }}>
              <td style={{ padding: 'var(--space-2)', fontWeight: 600 }}>{p.period}</td>
              <td style={{ padding: 'var(--space-2)' }}>{formatCurrency(p.gross_revenue)}</td>
              <td style={{ padding: 'var(--space-2)' }}>{formatCurrency(p.monthly_royalty)}</td>
              <td style={{ padding: 'var(--space-2)' }}>{formatCurrency(p.revenue_royalty)}</td>
              <td style={{ padding: 'var(--space-2)', fontWeight: 600 }}>{formatCurrency(p.total_royalty)}</td>
              <td style={{ padding: 'var(--space-2)' }}><StatusBadge status={p.status} config={ROYALTY_STATUS_CONFIG} /></td>
              <td style={{ padding: 'var(--space-2)', color: 'var(--color-text-tertiary)' }}>{formatDate(p.paid_at)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function OtherRevenueSection({ franchiseeId }: { franchiseeId: string }) {
  const { data: revenues = [], isLoading } = useQuery<OtherRevenue[]>({
    queryKey: ['franchisee-other-revenue', franchiseeId],
    queryFn: () => franchiseeService.listOtherRevenue(franchiseeId),
  })

  if (isLoading) return <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Memuat...</div>
  if (revenues.length === 0) return <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Belum ada pendapatan lain.</div>

  return (
    <div style={{ overflowX: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 'var(--font-sm)' }}>
        <thead>
          <tr style={{ borderBottom: '2px solid var(--color-border)' }}>
            {['Keterangan', 'Jumlah', 'Tanggal'].map(h => (
              <th key={h} style={{ padding: 'var(--space-2)', textAlign: 'left', color: 'var(--color-text-secondary)', fontWeight: 600 }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {revenues.map((r) => (
            <tr key={r.id} style={{ borderBottom: '1px solid var(--color-border)' }}>
              <td style={{ padding: 'var(--space-2)', fontWeight: 500 }}>{r.label}</td>
              <td style={{ padding: 'var(--space-2)' }}>{formatCurrency(r.amount)}</td>
              <td style={{ padding: 'var(--space-2)', color: 'var(--color-text-tertiary)' }}>{formatDate(r.revenue_date)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export default function FranchiseeDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()

  const { data: franchisee, isLoading, isError } = useQuery<Franchisee>({
    queryKey: ['franchisee', id],
    queryFn: () => franchiseeService.getById(id!),
    enabled: Boolean(id),
  })

  const actions: DetailPageAction[] = [
    {
      label: 'Edit',
      icon: <Pencil size={14} />,
      variant: 'primary',
      onClick: () => navigate(`/pengembangan/franchisees/${id}/edit`),
    },
  ]

  const sections = [
    {
      key: 'info',
      label: 'Info',
      content: franchisee ? <InfoSection franchisee={franchisee} /> : null,
    },
    {
      key: 'agreement',
      label: 'Perjanjian',
      content: id ? <AgreementSection franchiseeId={id} /> : null,
    },
    {
      key: 'royalty',
      label: 'Royalty Payments',
      content: id ? <RoyaltySection franchiseeId={id} /> : null,
    },
    {
      key: 'other-revenue',
      label: 'Pendapatan Lain',
      content: id ? <OtherRevenueSection franchiseeId={id} /> : null,
    },
  ]

  return (
    <DetailPageTemplate
      title={franchisee?.name ?? (isLoading ? 'Memuat...' : 'Franchisee')}
      subtitle={franchisee?.branch_name}
      icon={<Store size={20} />}
      isLoading={isLoading}
      isError={isError}
      actions={actions}
      sections={sections}
    />
  )
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd web-dashboard && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx
git commit -m "feat(franchisee): add FranchiseeDetailPage"
```

---

## Task 6: Full Test Suite + Lint

- [ ] **Step 1: Run all franchisee tests**

```bash
cd web-dashboard && npx vitest run src/pages/Franchisee/ src/services/__tests__/franchisee.service.test.ts
```

Expected: all tests pass.

- [ ] **Step 2: Run TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 3: Run linter**

```bash
cd web-dashboard && npm run lint -- --max-warnings=0
```

Fix any lint errors before proceeding.

- [ ] **Step 4: Final commit**

```bash
git add -p
git commit -m "test(franchisee): add full test suite and verify lint"
```
