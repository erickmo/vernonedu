# Partner Perjanjian (MOU) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement full MOU CRUD in PartnerDetailPage, a PartnerMOUListPage monitor, and an expiring-MOU dashboard widget.

**Architecture:** Backend API is complete (no backend changes needed). Three frontend deliverables share a single `partner.service.ts` and `partner.types.ts` as foundation. PartnerDetailPage replaces a placeholder MOU tab with a real modal-driven table. PartnerMOUListPage uses `/mous/expiring` + `/partners` list to monitor status across all partners. DashboardPage gains a compact widget using the same expiring endpoint.

**Tech Stack:** React 18, TypeScript strict, TanStack React Query 5, React Router 6, CSS Modules (inline styles, no Tailwind), Vitest + React Testing Library + MSW, lucide-react icons.

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `web-dashboard/src/types/partner.types.ts` | **Create** | MOU + Partner type definitions |
| `web-dashboard/src/services/partner.service.ts` | **Edit** | Add listMOUs, updateMOU, deleteMOU, listExpiringMOUs; fix getDetail→getById |
| `web-dashboard/src/pages/BusinessDev/PartnerDetailPage.tsx` | **Edit** | Replace placeholder MOU tab with full CRUD + MOUFormModal |
| `web-dashboard/src/pages/BusinessDev/__tests__/PartnerDetailPage.test.tsx` | **Create** | Tests for MOU tab |
| `web-dashboard/src/pages/Partners/PartnerMOUListPage.tsx` | **Create** | MOU monitor page (expiring section + all-partners section) |
| `web-dashboard/src/pages/Partners/__tests__/PartnerMOUListPage.test.tsx` | **Create** | Tests for MOU list page |
| `web-dashboard/src/pages/Dashboard/DashboardPage.tsx` | **Edit** | Add ExpiringMOUWidget to sideColumn |
| `web-dashboard/src/app/routes.tsx` | **Edit** | Add route `partners/mous` before `partners/:partnerId` |
| `web-dashboard/src/layouts/AppSidebar/navItems.ts` | **Edit** | Add PARTNER_ITEMS with MOU sub-item |

---

## Task 1: Types & Service Foundation

**Files:**
- Create: `web-dashboard/src/types/partner.types.ts`
- Modify: `web-dashboard/src/services/partner.service.ts`

- [ ] **Step 1: Create partner.types.ts**

```typescript
// web-dashboard/src/types/partner.types.ts

export type MOUStatus = 'active' | 'expiring' | 'expired' | 'terminated'

export interface MOU {
  id: string
  partner_id: string
  document_number: string
  title: string
  start_date: string
  end_date?: string
  status: MOUStatus
  document_url?: string
  notes?: string
  created_at: string
  updated_at: string
}

export interface ExpiringMOU extends MOU {
  partner_name: string
}

export interface MOUPayload {
  document_number: string
  title: string
  start_date: string
  end_date?: string
  status: MOUStatus
  document_url?: string
  notes?: string
}

export interface Partner {
  id: string
  name: string
  type?: string
  contact_person?: string
  email?: string
  phone?: string
  address?: string
  mou_status?: MOUStatus | null
  group_id?: string
  is_active?: boolean
  [key: string]: unknown
}
```

- [ ] **Step 2: Replace partner.service.ts**

Replace the entire file content:

```typescript
// web-dashboard/src/services/partner.service.ts
import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'
import type { MOU, MOUPayload, ExpiringMOU, Partner } from '@/types/partner.types'

function extractList<T>(r: unknown): T[] {
  const outer = (r as any)?.data ?? r
  return Array.isArray(outer) ? outer : (outer?.data ?? outer?.items ?? [])
}

export const partnerService = {
  list: (params?: ListParams): Promise<PaginatedResponse<Partner>> =>
    apiClient.get<unknown>(`partners${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string): Promise<Partner> =>
    apiClient.get<unknown>(`partners/${id}`).then((r: any) => r?.data ?? r),

  create: (data: Pick<Partner, 'name'> & Partial<Pick<Partner, 'address' | 'phone' | 'group_id' | 'is_active'>>) =>
    apiClient.post<unknown>('partners', data),

  update: (id: string, data: Partial<Partner>) =>
    apiClient.put<unknown>(`partners/${id}`, data),

  delete: (id: string) =>
    apiClient.delete<unknown>(`partners/${id}`),

  listMOUs: (partnerId: string): Promise<MOU[]> =>
    apiClient.get<unknown>(`partners/${partnerId}/mous`).then(extractList<MOU>),

  addMOU: (partnerId: string, data: MOUPayload): Promise<unknown> =>
    apiClient.post<unknown>(`partners/${partnerId}/mou`, data),

  updateMOU: (mouId: string, data: MOUPayload): Promise<unknown> =>
    apiClient.put<unknown>(`mous/${mouId}`, data),

  deleteMOU: (mouId: string): Promise<unknown> =>
    apiClient.delete<unknown>(`mous/${mouId}`),

  listExpiringMOUs: (withinMonths = 3): Promise<ExpiringMOU[]> =>
    apiClient.get<unknown>(`mous/expiring?within_months=${withinMonths}`).then(extractList<ExpiringMOU>),
}
```

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/types/partner.types.ts web-dashboard/src/services/partner.service.ts
git commit -m "feat(partner): add MOU types and service methods"
```

---

## Task 2: PartnerDetailPage — MOU Tab (TDD)

**Files:**
- Create: `web-dashboard/src/pages/BusinessDev/__tests__/PartnerDetailPage.test.tsx`
- Modify: `web-dashboard/src/pages/BusinessDev/PartnerDetailPage.tsx`

- [ ] **Step 1: Write failing tests**

```typescript
// web-dashboard/src/pages/BusinessDev/__tests__/PartnerDetailPage.test.tsx
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import PartnerDetailPage from '../PartnerDetailPage'

vi.mock('@/services/partner.service', () => ({
  partnerService: {
    getById: vi.fn().mockResolvedValue({
      id: 'p1', name: 'PT Mitra Sejahtera', mou_status: 'active',
    }),
    listMOUs: vi.fn().mockResolvedValue([
      {
        id: 'm1', partner_id: 'p1', document_number: 'MOU/2026/001',
        title: 'Kerjasama Pelatihan', start_date: '2026-01-01',
        end_date: '2027-01-01', status: 'active',
      },
    ]),
    addMOU: vi.fn().mockResolvedValue({ data: { id: 'm2' } }),
    updateMOU: vi.fn().mockResolvedValue({ data: { id: 'm1' } }),
    deleteMOU: vi.fn().mockResolvedValue(undefined),
    delete: vi.fn().mockResolvedValue(undefined),
  },
}))

vi.mock('@/widgets/Toast/Toast', () => ({
  toast: { success: vi.fn(), error: vi.fn() },
}))

vi.mock('@/widgets/Modals/DeleteConfirmModal', () => ({
  useDeleteConfirmModal: () => vi.fn(),
}))

vi.mock('@/widgets/DetailPageTemplate/DetailPageTemplate', () => ({
  DetailPageTemplate: ({ tabs }: { tabs?: Array<{ id: string; content: React.ReactNode }> }) => (
    <div data-testid="detail-page">
      {tabs?.map(t => <div key={t.id} data-testid={`tab-${t.id}`}>{t.content}</div>)}
    </div>
  ),
}))

function wrapper({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      <MemoryRouter initialEntries={['/partners/p1']}>
        <Routes>
          <Route path="/partners/:partnerId" element={children} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('PartnerDetailPage — MOU tab', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders existing MOU in table', async () => {
    render(<PartnerDetailPage />, { wrapper })
    await waitFor(() => {
      expect(screen.getByText('MOU/2026/001')).toBeInTheDocument()
      expect(screen.getByText('Kerjasama Pelatihan')).toBeInTheDocument()
    })
  })

  it('opens create modal when "Tambah MOU" clicked', async () => {
    render(<PartnerDetailPage />, { wrapper })
    await waitFor(() => screen.getByText('Kerjasama Pelatihan'))
    await userEvent.click(screen.getByText('Tambah MOU'))
    expect(screen.getByRole('heading', { name: 'Tambah MOU' })).toBeInTheDocument()
  })

  it('submits create form and calls addMOU', async () => {
    const { partnerService } = await import('@/services/partner.service')
    render(<PartnerDetailPage />, { wrapper })
    await waitFor(() => screen.getByText('Kerjasama Pelatihan'))

    await userEvent.click(screen.getByText('Tambah MOU'))
    await userEvent.type(screen.getByLabelText('Judul'), 'MOU Baru')
    await userEvent.type(screen.getByLabelText('No. Dokumen'), 'MOU/2026/002')
    await userEvent.type(screen.getByLabelText('Tanggal Mulai'), '2026-06-01')
    // status defaults to 'active'

    await userEvent.click(screen.getByRole('button', { name: 'Simpan' }))
    await waitFor(() => expect(partnerService.addMOU).toHaveBeenCalledWith('p1', expect.objectContaining({
      title: 'MOU Baru', document_number: 'MOU/2026/002',
    })))
  })

  it('opens edit modal with pre-filled data when edit icon clicked', async () => {
    render(<PartnerDetailPage />, { wrapper })
    await waitFor(() => screen.getByText('Kerjasama Pelatihan'))
    await userEvent.click(screen.getByTestId('edit-mou-m1'))
    expect(screen.getByDisplayValue('Kerjasama Pelatihan')).toBeInTheDocument()
    expect(screen.getByDisplayValue('MOU/2026/001')).toBeInTheDocument()
  })

  it('calls deleteMOU after confirm dialog', async () => {
    const { partnerService } = await import('@/services/partner.service')
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    render(<PartnerDetailPage />, { wrapper })
    await waitFor(() => screen.getByText('Kerjasama Pelatihan'))
    await userEvent.click(screen.getByTestId('delete-mou-m1'))
    await waitFor(() => expect(partnerService.deleteMOU).toHaveBeenCalledWith('m1'))
  })
})
```

- [ ] **Step 2: Run tests — verify fail**

```bash
cd web-dashboard && npx vitest run src/pages/BusinessDev/__tests__/PartnerDetailPage.test.tsx
```

Expected: FAIL — `PartnerDetailPage` calls `partnerService.getDetail` (not `getById`) + no MOU table

- [ ] **Step 3: Rewrite PartnerDetailPage.tsx**

Replace entire file:

```tsx
// web-dashboard/src/pages/BusinessDev/PartnerDetailPage.tsx
import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import {
  Handshake, Pencil, Plus, FileText, StickyNote,
  X, Trash2, Pencil as EditIcon, ExternalLink,
} from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { partnerService } from '@/services/partner.service'
import { toast } from '@/widgets/Toast/Toast'
import { useDeleteConfirmModal } from '@/widgets/Modals/DeleteConfirmModal'
import type { MOU, MOUPayload, MOUStatus, Partner } from '@/types/partner.types'

const MOU_STATUSES: { value: MOUStatus; label: string }[] = [
  { value: 'active',     label: 'Aktif' },
  { value: 'expiring',   label: 'Segera Berakhir' },
  { value: 'expired',    label: 'Berakhir' },
  { value: 'terminated', label: 'Dihentikan' },
]

const MOU_BADGE_COLOR: Record<MOUStatus, { bg: string; color: string }> = {
  active:     { bg: 'var(--color-success-light)',  color: 'var(--color-success-dark)' },
  expiring:   { bg: 'var(--color-warning-light)',  color: 'var(--color-warning-dark)' },
  expired:    { bg: 'var(--color-error-light)',    color: 'var(--color-error-dark)' },
  terminated: { bg: 'var(--color-surface-alt)',    color: 'var(--color-text-tertiary)' },
}

const MOU_BADGE_LABEL: Record<string, string> = {
  active:     'MOU Aktif',
  expiring:   'MOU Segera Berakhir',
  expired:    'MOU Berakhir',
  terminated: 'MOU Dihentikan',
}

function StatusBadge({ status }: { status?: string | null }) {
  const s = MOU_BADGE_COLOR[(status as MOUStatus) ?? ''] ?? { bg: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' }
  const label = MOU_BADGE_LABEL[status ?? ''] ?? 'Belum Ada MOU'
  return (
    <span style={{
      display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
      fontSize: 'var(--font-xs)', fontWeight: 600, background: s.bg, color: s.color,
    }}>
      {label}
    </span>
  )
}

function InfoRow({ label, value }: { label: string; value?: string | null }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: 'var(--space-2) 0', borderBottom: '1px solid var(--color-border)' }}>
      <span style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>{label}</span>
      <span style={{ fontWeight: 500, fontSize: 'var(--font-sm)' }}>{value || '—'}</span>
    </div>
  )
}

interface MOUFormModalProps {
  partnerId: string
  mou: MOU | null
  onClose: () => void
}

function MOUFormModal({ partnerId, mou, onClose }: MOUFormModalProps) {
  const queryClient = useQueryClient()
  const isEdit = mou !== null

  const [form, setForm] = useState<MOUPayload>({
    title:           mou?.title ?? '',
    document_number: mou?.document_number ?? '',
    start_date:      mou?.start_date ?? '',
    end_date:        mou?.end_date ?? '',
    status:          mou?.status ?? 'active',
    document_url:    mou?.document_url ?? '',
    notes:           mou?.notes ?? '',
  })

  const mutation = useMutation({
    mutationFn: (payload: MOUPayload) =>
      isEdit
        ? partnerService.updateMOU(mou!.id, payload)
        : partnerService.addMOU(partnerId, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['partner-mous', partnerId] })
      toast.success(isEdit ? 'MOU berhasil diperbarui' : 'MOU berhasil ditambahkan')
      onClose()
    },
    onError: () => toast.error('Terjadi kesalahan, coba lagi'),
  })

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    const payload: MOUPayload = {
      ...form,
      end_date: form.end_date || undefined,
      document_url: form.document_url || undefined,
      notes: form.notes || undefined,
    }
    mutation.mutate(payload)
  }

  function field(id: string, label: string, el: React.ReactNode) {
    return (
      <div style={{ marginBottom: 'var(--space-3)' }}>
        <label htmlFor={id} style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 600, marginBottom: 4 }}>{label}</label>
        {el}
      </div>
    )
  }

  const inputStyle = {
    width: '100%', padding: '8px 12px', borderRadius: 'var(--radius-md)',
    border: '1px solid var(--color-border)', background: 'var(--color-surface)',
    fontSize: 'var(--font-sm)', boxSizing: 'border-box' as const,
  }

  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 400,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }} onClick={onClose}>
      <div style={{
        background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', width: 520, maxHeight: '90vh',
        overflow: 'auto',
      }} onClick={e => e.stopPropagation()}>
        <div style={{
          padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--color-border)',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'sticky', top: 0,
          background: 'var(--color-surface-elevated)',
        }}>
          <h3 role="heading" style={{ fontSize: 'var(--font-base)', fontWeight: 700 }}>
            {isEdit ? 'Edit MOU' : 'Tambah MOU'}
          </h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-tertiary)' }}>
            <X size={16} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ padding: 'var(--space-5)' }}>
          {field('title', 'Judul', (
            <input id="title" value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
              required style={inputStyle} />
          ))}
          {field('document_number', 'No. Dokumen', (
            <input id="document_number" value={form.document_number}
              onChange={e => setForm(f => ({ ...f, document_number: e.target.value }))}
              required style={inputStyle} />
          ))}
          {field('start_date', 'Tanggal Mulai', (
            <input id="start_date" type="date" value={form.start_date}
              onChange={e => setForm(f => ({ ...f, start_date: e.target.value }))}
              required style={inputStyle} />
          ))}
          {field('end_date', 'Tanggal Berakhir (opsional)', (
            <input id="end_date" type="date" value={form.end_date ?? ''}
              onChange={e => setForm(f => ({ ...f, end_date: e.target.value }))}
              style={inputStyle} />
          ))}
          {field('status', 'Status', (
            <select id="status" value={form.status}
              onChange={e => setForm(f => ({ ...f, status: e.target.value as MOUStatus }))}
              required style={inputStyle}>
              {MOU_STATUSES.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}
            </select>
          ))}
          {field('document_url', 'URL Dokumen (opsional)', (
            <input id="document_url" type="url" value={form.document_url ?? ''}
              onChange={e => setForm(f => ({ ...f, document_url: e.target.value }))}
              style={inputStyle} placeholder="https://..." />
          ))}
          {field('notes', 'Catatan (opsional)', (
            <textarea id="notes" value={form.notes ?? ''}
              onChange={e => setForm(f => ({ ...f, notes: e.target.value }))}
              rows={3} style={{ ...inputStyle, resize: 'vertical' }} />
          ))}

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-2)', marginTop: 'var(--space-4)' }}>
            <button type="button" onClick={onClose} style={{
              padding: '8px 16px', borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-border)', background: 'var(--color-surface)',
              cursor: 'pointer', fontSize: 'var(--font-sm)',
            }}>
              Batal
            </button>
            <button type="submit" disabled={mutation.isPending} style={{
              padding: '8px 16px', borderRadius: 'var(--radius-md)',
              border: 'none', background: 'var(--color-primary)', color: '#fff',
              cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 600,
              opacity: mutation.isPending ? 0.7 : 1,
            }}>
              {mutation.isPending ? 'Menyimpan...' : 'Simpan'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export default function PartnerDetailPage() {
  const { partnerId } = useParams<{ partnerId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const confirmDelete = useDeleteConfirmModal()

  const [mouModalOpen, setMouModalOpen] = useState(false)
  const [editingMOU, setEditingMOU] = useState<MOU | null>(null)

  const { data: partner, isLoading } = useQuery({
    queryKey: ['partner', partnerId],
    queryFn: () => partnerService.getById(partnerId!),
  })

  const { data: mous = [] } = useQuery({
    queryKey: ['partner-mous', partnerId],
    queryFn: () => partnerService.listMOUs(partnerId!),
    enabled: !!partnerId,
  })

  const deleteMOUMutation = useMutation({
    mutationFn: (mouId: string) => partnerService.deleteMOU(mouId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['partner-mous', partnerId] })
      toast.success('MOU berhasil dihapus')
    },
    onError: () => toast.error('Gagal menghapus MOU'),
  })

  function handleDeleteMOU(mouId: string) {
    if (!window.confirm('Yakin ingin menghapus MOU ini?')) return
    deleteMOUMutation.mutate(mouId)
  }

  function openCreate() {
    setEditingMOU(null)
    setMouModalOpen(true)
  }

  function openEdit(mou: MOU) {
    setEditingMOU(mou)
    setMouModalOpen(true)
  }

  function closeModal() {
    setMouModalOpen(false)
    setEditingMOU(null)
  }

  const p = partner as Partner | undefined

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Partner',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/partners/${partnerId}/edit`),
      variant: 'default',
    },
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: () => confirmDelete('Hapus Partner', 'Yakin ingin menghapus partner ini?', async () => {
        await partnerService.delete(partnerId!)
        toast.success('Partner berhasil dihapus')
        navigate('/partners')
      }),
      variant: 'danger' as const,
    },
  ]

  const overviewTab = (
    <div style={{ display: 'grid', gap: 'var(--space-4)' }}>
      <div style={{
        padding: 'var(--space-5)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
      }}>
        <h3 style={{ fontSize: 'var(--font-sm)', fontWeight: 700, marginBottom: 'var(--space-3)', color: 'var(--color-text-secondary)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
          Informasi Partner
        </h3>
        <InfoRow label="Nama" value={p?.name} />
        <InfoRow label="Tipe" value={p?.type as string} />
        <InfoRow label="Kontak Person" value={p?.contact_person as string} />
        <InfoRow label="Email" value={p?.email as string} />
        <InfoRow label="Telepon" value={p?.phone as string} />
        <InfoRow label="Alamat" value={p?.address as string} />
      </div>

      <div style={{
        padding: 'var(--space-5)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
          <div style={{
            width: 40, height: 40, borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary-subtle)', display: 'flex',
            alignItems: 'center', justifyContent: 'center', color: 'var(--color-primary)',
          }}>
            <Handshake size={18} />
          </div>
          <div>
            <div style={{ fontWeight: 600 }}>Status MOU</div>
            <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-secondary)', marginTop: 2 }}>
              Memorandum of Understanding
            </div>
          </div>
        </div>
        <StatusBadge status={p?.mou_status} />
      </div>
    </div>
  )

  const mouTab = (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-4)' }}>
        <span style={{ fontWeight: 600, fontSize: 'var(--font-sm)' }}>
          {mous.length} MOU tercatat
        </span>
        <button onClick={openCreate} style={{
          display: 'flex', alignItems: 'center', gap: 6, padding: '6px 14px',
          borderRadius: 'var(--radius-md)', border: 'none', background: 'var(--color-primary)',
          color: '#fff', cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 600,
        }}>
          <Plus size={14} /> Tambah MOU
        </button>
      </div>

      {mous.length === 0 ? (
        <div style={{
          padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)',
          borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-border)',
          background: 'var(--color-surface-elevated)',
        }}>
          <FileText size={32} style={{ marginBottom: 'var(--space-3)', opacity: 0.5 }} />
          <div style={{ fontWeight: 600, fontSize: 'var(--font-base)', color: 'var(--color-text-secondary)' }}>
            Belum ada MOU tercatat
          </div>
          <div style={{ fontSize: 'var(--font-sm)', marginTop: 'var(--space-1)' }}>
            Tambahkan MOU baru untuk memulai kolaborasi dengan partner ini.
          </div>
        </div>
      ) : (
        <div style={{ borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-border)', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 'var(--font-sm)' }}>
            <thead>
              <tr style={{ background: 'var(--color-surface-alt)' }}>
                {['No. Dokumen', 'Judul', 'Mulai', 'Berakhir', 'Status', 'Aksi'].map(h => (
                  <th key={h} style={{ padding: '10px 12px', textAlign: 'left', fontWeight: 600, color: 'var(--color-text-secondary)', fontSize: 'var(--font-xs)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {mous.map((mou, i) => (
                <tr key={mou.id} style={{ borderTop: i > 0 ? '1px solid var(--color-border)' : undefined }}>
                  <td style={{ padding: '10px 12px', fontFamily: 'monospace', fontSize: 'var(--font-xs)' }}>{mou.document_number}</td>
                  <td style={{ padding: '10px 12px' }}>
                    {mou.document_url ? (
                      <a href={mou.document_url} target="_blank" rel="noopener noreferrer"
                        style={{ color: 'var(--color-primary)', display: 'flex', alignItems: 'center', gap: 4 }}>
                        {mou.title} <ExternalLink size={12} />
                      </a>
                    ) : mou.title}
                  </td>
                  <td style={{ padding: '10px 12px' }}>{mou.start_date}</td>
                  <td style={{ padding: '10px 12px' }}>{mou.end_date ?? '—'}</td>
                  <td style={{ padding: '10px 12px' }}><StatusBadge status={mou.status} /></td>
                  <td style={{ padding: '10px 12px' }}>
                    <div style={{ display: 'flex', gap: 8 }}>
                      <button
                        data-testid={`edit-mou-${mou.id}`}
                        onClick={() => openEdit(mou)}
                        style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-secondary)' }}
                        title="Edit MOU"
                      >
                        <EditIcon size={14} />
                      </button>
                      <button
                        data-testid={`delete-mou-${mou.id}`}
                        onClick={() => handleDeleteMOU(mou.id)}
                        style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-error)' }}
                        title="Hapus MOU"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )

  const notesTab = (
    <div style={{
      padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)',
      borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-border)',
      background: 'var(--color-surface-elevated)',
    }}>
      <StickyNote size={32} style={{ marginBottom: 'var(--space-3)', opacity: 0.5 }} />
      <div style={{ fontWeight: 600, fontSize: 'var(--font-base)', color: 'var(--color-text-secondary)' }}>
        Belum ada catatan
      </div>
      <div style={{ fontSize: 'var(--font-sm)', marginTop: 'var(--space-1)' }}>
        Catatan kolaborasi dan komunikasi dengan partner akan tampil di sini.
      </div>
    </div>
  )

  return (
    <>
      <DetailPageTemplate
        onBack={() => navigate('/partners')}
        icon={<Handshake size={20} />}
        title={isLoading ? 'Memuat...' : (p?.name ?? 'Partner')}
        badges={<StatusBadge status={p?.mou_status} />}
        actions={actions}
        tabs={[
          { id: 'overview', label: 'Ringkasan', icon: <Handshake size={14} />, content: overviewTab },
          { id: 'mou', label: 'MOU', icon: <FileText size={14} />, content: mouTab },
          { id: 'notes', label: 'Catatan', icon: <StickyNote size={14} />, content: notesTab },
        ]}
      />

      {mouModalOpen && (
        <MOUFormModal
          partnerId={partnerId!}
          mou={editingMOU}
          onClose={closeModal}
        />
      )}
    </>
  )
}
```

- [ ] **Step 4: Run tests — verify pass**

```bash
cd web-dashboard && npx vitest run src/pages/BusinessDev/__tests__/PartnerDetailPage.test.tsx
```

Expected: PASS all 5 tests

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/pages/BusinessDev/PartnerDetailPage.tsx \
        web-dashboard/src/pages/BusinessDev/__tests__/PartnerDetailPage.test.tsx
git commit -m "feat(partner): implement MOU CRUD tab in PartnerDetailPage"
```

---

## Task 3: PartnerMOUListPage (TDD)

**Files:**
- Create: `web-dashboard/src/pages/Partners/__tests__/PartnerMOUListPage.test.tsx`
- Create: `web-dashboard/src/pages/Partners/PartnerMOUListPage.tsx`

- [ ] **Step 1: Write failing tests**

```typescript
// web-dashboard/src/pages/Partners/__tests__/PartnerMOUListPage.test.tsx
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import PartnerMOUListPage from '../PartnerMOUListPage'

vi.mock('@/services/partner.service', () => ({
  partnerService: {
    listExpiringMOUs: vi.fn().mockResolvedValue([
      {
        id: 'm1', partner_id: 'p1', partner_name: 'PT Mitra Sejahtera',
        document_number: 'MOU/2026/001', title: 'Kerjasama Pelatihan',
        start_date: '2026-01-01', end_date: '2026-07-01', status: 'expiring',
      },
    ]),
    list: vi.fn().mockResolvedValue({
      items: [
        { id: 'p1', name: 'PT Mitra Sejahtera', mou_status: 'expiring' },
        { id: 'p2', name: 'CV Edu Maju', mou_status: 'active' },
        { id: 'p3', name: 'PT Nusantara', mou_status: null },
      ],
      total: 3,
    }),
  },
}))

vi.mock('@/widgets/Toast/Toast', () => ({
  toast: { success: vi.fn(), error: vi.fn() },
}))

function wrapper({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      <MemoryRouter>
        {children}
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('PartnerMOUListPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('shows expiring MOU in section A', async () => {
    render(<PartnerMOUListPage />, { wrapper })
    await waitFor(() => {
      expect(screen.getByText('Kerjasama Pelatihan')).toBeInTheDocument()
      expect(screen.getByText('PT Mitra Sejahtera')).toBeInTheDocument()
    })
  })

  it('shows all partners in section B', async () => {
    render(<PartnerMOUListPage />, { wrapper })
    await waitFor(() => {
      expect(screen.getAllByText('PT Mitra Sejahtera')).toBeTruthy()
      expect(screen.getByText('CV Edu Maju')).toBeInTheDocument()
      expect(screen.getByText('PT Nusantara')).toBeInTheDocument()
    })
  })

  it('filters partners by MOU status', async () => {
    render(<PartnerMOUListPage />, { wrapper })
    await waitFor(() => screen.getByText('CV Edu Maju'))

    await userEvent.selectOptions(screen.getByLabelText('Filter Status MOU'), 'active')
    expect(screen.getByText('CV Edu Maju')).toBeInTheDocument()
    expect(screen.queryByText('PT Nusantara')).not.toBeInTheDocument()
  })

  it('shows empty state when no expiring MOUs', async () => {
    const { partnerService } = await import('@/services/partner.service')
    vi.mocked(partnerService.listExpiringMOUs).mockResolvedValue([])
    render(<PartnerMOUListPage />, { wrapper })
    await waitFor(() => {
      expect(screen.getByText(/tidak ada mou yang akan berakhir/i)).toBeInTheDocument()
    })
  })
})
```

- [ ] **Step 2: Run tests — verify fail**

```bash
cd web-dashboard && npx vitest run src/pages/Partners/__tests__/PartnerMOUListPage.test.tsx
```

Expected: FAIL — module not found

- [ ] **Step 3: Create PartnerMOUListPage.tsx**

```tsx
// web-dashboard/src/pages/Partners/PartnerMOUListPage.tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { AlertCircle, ArrowRight, Handshake } from 'lucide-react'
import { PageHeader } from '@/layouts/PageHeader/PageHeader'
import { partnerService } from '@/services/partner.service'
import type { ExpiringMOU, MOUStatus, Partner } from '@/types/partner.types'

const MOU_BADGE_COLOR: Record<string, { bg: string; color: string }> = {
  active:     { bg: 'var(--color-success-light)',  color: 'var(--color-success-dark)' },
  expiring:   { bg: 'var(--color-warning-light)',  color: 'var(--color-warning-dark)' },
  expired:    { bg: 'var(--color-error-light)',    color: 'var(--color-error-dark)' },
  terminated: { bg: 'var(--color-surface-alt)',    color: 'var(--color-text-tertiary)' },
}

const MOU_BADGE_LABEL: Record<string, string> = {
  active:     'Aktif',
  expiring:   'Segera Berakhir',
  expired:    'Berakhir',
  terminated: 'Dihentikan',
}

const STATUS_OPTIONS = [
  { value: '', label: 'Semua Status' },
  { value: 'active', label: 'Aktif' },
  { value: 'expiring', label: 'Segera Berakhir' },
  { value: 'expired', label: 'Berakhir' },
  { value: 'terminated', label: 'Dihentikan' },
  { value: 'none', label: 'Belum Ada MOU' },
]

function StatusBadge({ status }: { status?: string | null }) {
  const s = MOU_BADGE_COLOR[status ?? ''] ?? { bg: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' }
  const label = MOU_BADGE_LABEL[status ?? ''] ?? 'Belum Ada MOU'
  return (
    <span style={{
      display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
      fontSize: 'var(--font-xs)', fontWeight: 600, background: s.bg, color: s.color,
    }}>
      {label}
    </span>
  )
}

function daysUntil(dateStr: string): number {
  return Math.ceil((new Date(dateStr).getTime() - Date.now()) / 86_400_000)
}

const cardStyle = {
  padding: 'var(--space-5)', borderRadius: 'var(--radius-lg)',
  border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
  marginBottom: 'var(--space-6)',
}

const tableStyle: React.CSSProperties = {
  width: '100%', borderCollapse: 'collapse', fontSize: 'var(--font-sm)',
}

const thStyle: React.CSSProperties = {
  padding: '10px 12px', textAlign: 'left', fontWeight: 600,
  color: 'var(--color-text-secondary)', fontSize: 'var(--font-xs)',
  textTransform: 'uppercase', letterSpacing: '0.5px',
  background: 'var(--color-surface-alt)',
}

const tdStyle: React.CSSProperties = { padding: '10px 12px' }

export default function PartnerMOUListPage() {
  const navigate = useNavigate()
  const [statusFilter, setStatusFilter] = useState<string>('')

  const { data: expiringMOUs = [], isLoading: loadingExpiring } = useQuery({
    queryKey: ['mous-expiring', 3],
    queryFn: () => partnerService.listExpiringMOUs(3),
  })

  const { data: partnersData } = useQuery({
    queryKey: ['partners-all'],
    queryFn: () => partnerService.list({ limit: 200 }),
  })

  const allPartners: Partner[] = partnersData?.items ?? []

  const filteredPartners = allPartners.filter(p => {
    if (!statusFilter) return true
    if (statusFilter === 'none') return !p.mou_status
    return p.mou_status === statusFilter
  })

  return (
    <div>
      <PageHeader title="Perjanjian MOU" subtitle="Monitor status MOU semua partner" />

      {/* Section A — Expiring */}
      <div style={cardStyle}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', marginBottom: 'var(--space-4)' }}>
          <AlertCircle size={16} style={{ color: 'var(--color-warning-dark)' }} />
          <h2 style={{ fontWeight: 700, fontSize: 'var(--font-base)' }}>
            MOU Segera Berakhir (3 bulan ke depan)
          </h2>
        </div>

        {loadingExpiring ? (
          <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Memuat...</p>
        ) : expiringMOUs.length === 0 ? (
          <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)', padding: 'var(--space-4) 0' }}>
            Tidak ada MOU yang akan berakhir dalam 3 bulan ke depan.
          </p>
        ) : (
          <div style={{ borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', overflow: 'hidden' }}>
            <table style={tableStyle}>
              <thead>
                <tr>
                  {['Partner', 'Judul', 'No. Dokumen', 'Berakhir', 'Sisa Hari', 'Status', ''].map(h => (
                    <th key={h} style={thStyle}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {expiringMOUs.map((mou: ExpiringMOU, i: number) => {
                  const days = mou.end_date ? daysUntil(mou.end_date) : null
                  return (
                    <tr key={mou.id} style={{ borderTop: i > 0 ? '1px solid var(--color-border)' : undefined }}>
                      <td style={tdStyle}>{mou.partner_name}</td>
                      <td style={tdStyle}>{mou.title}</td>
                      <td style={{ ...tdStyle, fontFamily: 'monospace', fontSize: 'var(--font-xs)' }}>{mou.document_number}</td>
                      <td style={tdStyle}>{mou.end_date ?? '—'}</td>
                      <td style={tdStyle}>
                        {days !== null ? (
                          <span style={{
                            padding: '2px 8px', borderRadius: 'var(--radius-full)',
                            background: days <= 30 ? 'var(--color-error-light)' : 'var(--color-warning-light)',
                            color: days <= 30 ? 'var(--color-error-dark)' : 'var(--color-warning-dark)',
                            fontSize: 'var(--font-xs)', fontWeight: 600,
                          }}>
                            {days} hari lagi
                          </span>
                        ) : '—'}
                      </td>
                      <td style={tdStyle}><StatusBadge status={mou.status} /></td>
                      <td style={tdStyle}>
                        <button onClick={() => navigate(`/partners/${mou.partner_id}`)}
                          style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-primary)', display: 'flex', alignItems: 'center', gap: 4, fontSize: 'var(--font-xs)' }}>
                          Detail <ArrowRight size={12} />
                        </button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Section B — All Partners */}
      <div style={cardStyle}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-4)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
            <Handshake size={16} />
            <h2 style={{ fontWeight: 700, fontSize: 'var(--font-base)' }}>Semua Partner</h2>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
            <label htmlFor="status-filter" style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
              Filter Status MOU
            </label>
            <select
              id="status-filter"
              aria-label="Filter Status MOU"
              value={statusFilter}
              onChange={e => setStatusFilter(e.target.value)}
              style={{
                padding: '6px 10px', borderRadius: 'var(--radius-md)', fontSize: 'var(--font-sm)',
                border: '1px solid var(--color-border)', background: 'var(--color-surface)',
              }}
            >
              {STATUS_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
        </div>

        <div style={{ borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', overflow: 'hidden' }}>
          <table style={tableStyle}>
            <thead>
              <tr>
                {['Nama Partner', 'Status MOU', 'Aksi'].map(h => (
                  <th key={h} style={thStyle}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filteredPartners.length === 0 ? (
                <tr>
                  <td colSpan={3} style={{ ...tdStyle, textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
                    Tidak ada partner yang sesuai filter.
                  </td>
                </tr>
              ) : filteredPartners.map((partner, i) => (
                <tr key={partner.id} style={{ borderTop: i > 0 ? '1px solid var(--color-border)' : undefined }}>
                  <td style={tdStyle}>{partner.name}</td>
                  <td style={tdStyle}><StatusBadge status={partner.mou_status} /></td>
                  <td style={tdStyle}>
                    <button onClick={() => navigate(`/partners/${partner.id}`)}
                      style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-primary)', display: 'flex', alignItems: 'center', gap: 4, fontSize: 'var(--font-xs)' }}>
                      Lihat Detail <ArrowRight size={12} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Run tests — verify pass**

```bash
cd web-dashboard && npx vitest run src/pages/Partners/__tests__/PartnerMOUListPage.test.tsx
```

Expected: PASS all 4 tests

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/pages/Partners/PartnerMOUListPage.tsx \
        web-dashboard/src/pages/Partners/__tests__/PartnerMOUListPage.test.tsx
git commit -m "feat(partner): add PartnerMOUListPage monitor"
```

---

## Task 4: Dashboard Widget (TDD)

**Files:**
- Modify: `web-dashboard/src/pages/Dashboard/DashboardPage.tsx`

- [ ] **Step 1: Write failing test**

Add to a new test file:

```typescript
// web-dashboard/src/pages/Dashboard/__tests__/ExpiringMOUWidget.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import DashboardPage from '../DashboardPage'

vi.mock('@/services/partner.service', () => ({
  partnerService: {
    listExpiringMOUs: vi.fn().mockResolvedValue([
      {
        id: 'm1', partner_id: 'p1', partner_name: 'PT Mitra Sejahtera',
        title: 'Kerjasama Pelatihan', end_date: '2026-07-01', status: 'expiring',
        document_number: 'MOU/2026/001', start_date: '2026-01-01',
      },
    ]),
  },
}))

vi.mock('@/stores/auth.store', () => ({
  useAuthStore: (sel: (s: any) => any) => sel({ user: { name: 'Admin', role: 'director' } }),
}))

vi.mock('@/layouts/PageHeader/PageHeader', () => ({
  PageHeader: ({ title }: { title: string }) => <div>{title}</div>,
}))

function wrapper({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      <MemoryRouter>{children}</MemoryRouter>
    </QueryClientProvider>
  )
}

describe('DashboardPage — ExpiringMOUWidget', () => {
  it('shows expiring MOU entry', async () => {
    render(<DashboardPage />, { wrapper })
    await waitFor(() => {
      expect(screen.getByText('PT Mitra Sejahtera')).toBeInTheDocument()
      expect(screen.getByText('Kerjasama Pelatihan')).toBeInTheDocument()
    })
  })

  it('has "Lihat semua" link to /partners/mous', async () => {
    render(<DashboardPage />, { wrapper })
    await waitFor(() => screen.getByText('PT Mitra Sejahtera'))
    const link = screen.getByRole('link', { name: /lihat semua/i })
    expect(link).toHaveAttribute('href', '/partners/mous')
  })
})
```

- [ ] **Step 2: Run — verify fail**

```bash
cd web-dashboard && npx vitest run src/pages/Dashboard/__tests__/ExpiringMOUWidget.test.tsx
```

Expected: FAIL — no such elements in DashboardPage

- [ ] **Step 3: Add ExpiringMOUWidget to DashboardPage.tsx**

At the top of DashboardPage.tsx, add the import:

```tsx
import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { partnerService } from '@/services/partner.service'
import type { ExpiringMOU } from '@/types/partner.types'
```

Add the component before the `export default function DashboardPage()` line:

```tsx
function ExpiringMOUWidget() {
  const { data: mous = [], isLoading } = useQuery({
    queryKey: ['mous-expiring-widget'],
    queryFn: () => partnerService.listExpiringMOUs(3),
  })

  const shown = mous.slice(0, 5)

  return (
    <section className={styles.panel}>
      <div className={styles.panelHeader}>
        <span className={styles.panelIcon}>
          <Handshake size={18} aria-hidden="true" />
        </span>
        <div>
          <p className={styles.panelEyebrow}>Monitoring MOU</p>
          <h2 className={styles.panelTitle}>MOU Segera Berakhir</h2>
        </div>
      </div>

      {isLoading ? (
        <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-tertiary)', padding: '8px 0' }}>Memuat...</p>
      ) : shown.length === 0 ? (
        <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-tertiary)', padding: '8px 0' }}>
          Tidak ada MOU yang akan berakhir dalam 3 bulan ke depan.
        </p>
      ) : (
        <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
          {shown.map((mou: ExpiringMOU) => (
            <li key={mou.id} style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              padding: '8px 0', borderBottom: '1px solid var(--color-border)',
              fontSize: 'var(--font-sm)',
            }}>
              <div>
                <div style={{ fontWeight: 600 }}>{mou.partner_name}</div>
                <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-xs)' }}>{mou.title}</div>
              </div>
              <span style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)' }}>{mou.end_date}</span>
            </li>
          ))}
        </ul>
      )}

      <div style={{ marginTop: 'var(--space-3)', textAlign: 'right' }}>
        <Link to="/partners/mous" style={{ fontSize: 'var(--font-xs)', color: 'var(--color-primary)' }}>
          Lihat semua →
        </Link>
      </div>
    </section>
  )
}
```

Also add `Handshake` to the existing lucide-react import if not already there.

In the `DashboardPage` JSX, add `<ExpiringMOUWidget />` inside `<aside className={styles.sideColumn}>` before the closing `</aside>`:

```tsx
<aside className={styles.sideColumn} aria-label="Panduan workspace">
  <ProgressPanel />
  {/* ... existing panels ... */}
  <ExpiringMOUWidget />
</aside>
```

- [ ] **Step 4: Run tests — verify pass**

```bash
cd web-dashboard && npx vitest run src/pages/Dashboard/__tests__/ExpiringMOUWidget.test.tsx
```

Expected: PASS all 2 tests

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/pages/Dashboard/DashboardPage.tsx \
        web-dashboard/src/pages/Dashboard/__tests__/ExpiringMOUWidget.test.tsx
git commit -m "feat(dashboard): add expiring MOU widget"
```

---

## Task 5: Routes & Nav Items

**Files:**
- Modify: `web-dashboard/src/app/routes.tsx`
- Modify: `web-dashboard/src/layouts/AppSidebar/navItems.ts`

- [ ] **Step 1: Add route in routes.tsx**

Add the lazy import near other Partner imports (around line 130):

```tsx
const PartnerMOUListPage = lazy(() => import('@/pages/Partners/PartnerMOUListPage'))
```

In the routes array, add **before** `partners/:partnerId` (critical — "mous" must not be caught by `:partnerId`):

```tsx
{ path: 'partners/mous',        element: <S><PartnerMOUListPage /></S> },
{ path: 'partners/:partnerId',  element: <S><PartnerDetailPage /></S> },
```

- [ ] **Step 2: Add PARTNER_ITEMS to navItems.ts**

After the existing `Handshake` import (already present), add `ScrollText` if not imported, or reuse `FileText`.

Add after the Partner entry in `ALL_ITEMS` (around line 286), before the `finance` entry:

```typescript
// ─── Partner sub-nav items ──────────────────────────────────────────────────────

const PARTNER_ITEMS: NavItem[] = [
  {
    key: 'partners-list',
    label: 'Daftar Partner',
    icon: Handshake,
    path: '/partners',
    hasAccess: (ctx) => hasAnyRole(ctx, ['director', 'operation_leader', 'education_leader']),
  },
  {
    key: 'partners-mous',
    label: 'Perjanjian MOU',
    icon: FileText,
    path: '/partners/mous',
    hasAccess: (ctx) => hasAnyRole(ctx, ['director', 'operation_leader', 'education_leader']),
  },
]
```

Update the Marketing section in `NAV_SECTIONS` (around line 504):

```typescript
// Before:
items: ALL_ITEMS.slice(11, 14), // Marketing, CRM, Partner

// After:
items: [...ALL_ITEMS.slice(11, 13), ...PARTNER_ITEMS], // Marketing, CRM, Partner List, MOU
```

> `ALL_ITEMS.slice(11, 13)` = Marketing + CRM. `PARTNER_ITEMS` replaces the single Partner item with two sub-items.

- [ ] **Step 3: Verify TypeScript compiles**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | head -30
```

Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add web-dashboard/src/app/routes.tsx \
        web-dashboard/src/layouts/AppSidebar/navItems.ts
git commit -m "feat(partner): add /partners/mous route and MOU nav item"
```

---

## Task 6: Full Test Suite & Lint

- [ ] **Step 1: Run all tests**

```bash
cd web-dashboard && npx vitest run
```

Expected: all pass. Fix any failures before proceeding.

- [ ] **Step 2: Run TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | head -40
```

Expected: no errors

- [ ] **Step 3: Run linter**

```bash
cd web-dashboard && npx eslint src/pages/BusinessDev/PartnerDetailPage.tsx \
  src/pages/Partners/PartnerMOUListPage.tsx \
  src/pages/Dashboard/DashboardPage.tsx \
  src/services/partner.service.ts \
  src/types/partner.types.ts 2>&1 | head -40
```

Expected: no errors. Fix any reported issues.

- [ ] **Step 4: Final commit**

```bash
git add -p
git commit -m "fix(partner): address lint and type issues from MOU feature"
```

Only if there are changes. Skip this step if no changes.

---

## Verification Checklist

After all tasks complete, verify end-to-end manually:

- [ ] `/partners/:id` → MOU tab shows list, "Tambah MOU" opens modal, edit/delete work
- [ ] `/partners/mous` → Expiring section and all-partners table render, filter works
- [ ] Dashboard → "MOU Segera Berakhir" widget visible in sidebar, "Lihat semua" link navigates
- [ ] `/partners/mous` route resolves before `partners/:partnerId` (no routing conflict)
- [ ] Partner nav shows two items: "Daftar Partner" + "Perjanjian MOU"

---

**Last Updated:** 2026-05-06
