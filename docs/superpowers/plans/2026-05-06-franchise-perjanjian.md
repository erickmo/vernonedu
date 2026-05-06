# Franchise Perjanjian Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add create/edit/delete actions for franchise agreements, royalty payments, and other revenue in FranchiseeDetailPage; implement FranchiseManagementPage with summary cards + franchisee table.

**Architecture:** All modals are co-located in `FranchiseeDetailPage.tsx` as inline JSX. State managed with `useState`. Mutations use plain `async/await` + `queryClient.invalidateQueries`. `FranchiseManagementPage` fetches franchisees with limit=1000 and computes summary client-side. No new service methods or backend changes needed.

**Tech Stack:** React 18, TypeScript, TanStack React Query 5, @tanstack/react-query `useQueryClient`, lucide-react icons, `@/widgets/Toast/Toast`, Vitest + React Testing Library

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx` | Modify | Add 3 modals + action buttons in section content |
| `web-dashboard/src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx` | Create | Tests for modal triggers and form interactions |
| `web-dashboard/src/pages/BusinessDev/FranchiseManagementPage.tsx` | Modify | Replace placeholder with summary cards + table |
| `web-dashboard/src/pages/BusinessDev/__tests__/FranchiseManagementPage.test.tsx` | Create | Tests for summary cards and table render |

---

## Task 1: AgreementFormModal

**Files:**
- Modify: `web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx`
- Create: `web-dashboard/src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx`

- [ ] **Step 1.1: Write failing test**

Create `web-dashboard/src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx`:

```tsx
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import FranchiseeDetailPage from '../FranchiseeDetailPage'

const mockFranchisee = {
  id: 'f1', name: 'PT Edu Maju', branch_name: 'Cabang Jakarta', location: 'Jakarta Selatan',
  contact: '08111222333', status: 'active', created_at: '2026-01-01',
}
const mockAgreement = {
  id: 'a1', franchisee_id: 'f1', buy_in_fee: 50000000, monthly_royalty: 5000000,
  revenue_royalty_pct: 5, start_date: '2026-01-01', end_date: '2027-01-01',
  status: 'active', created_at: '2026-01-01',
}

vi.mock('@/services/franchisee.service', () => ({
  franchiseeService: {
    getById: vi.fn().mockResolvedValue(mockFranchisee),
    getAgreement: vi.fn().mockResolvedValue(null),
    listRoyaltyPayments: vi.fn().mockResolvedValue({ items: [], total: 0 }),
    listOtherRevenue: vi.fn().mockResolvedValue({ items: [], total: 0 }),
    createAgreement: vi.fn().mockResolvedValue({ data: mockAgreement }),
    updateAgreement: vi.fn().mockResolvedValue({ data: mockAgreement }),
    createRoyaltyPayment: vi.fn().mockResolvedValue({ data: { id: 'r1' } }),
    markRoyaltyPaid: vi.fn().mockResolvedValue(undefined),
    createOtherRevenue: vi.fn().mockResolvedValue({ data: { id: 'o1' } }),
    updateOtherRevenue: vi.fn().mockResolvedValue({ data: { id: 'o1' } }),
    deleteOtherRevenue: vi.fn().mockResolvedValue(undefined),
  },
}))

vi.mock('@/widgets/Toast/Toast', () => ({
  toast: { success: vi.fn(), error: vi.fn() },
}))

vi.mock('@/widgets/DetailPageTemplate/DetailPageTemplate', () => ({
  DetailPageTemplate: ({ sections }: {
    sections?: { id: string; tabs: { id: string; content: React.ReactNode }[] }[]
  }) => (
    <div data-testid="detail-page">
      {sections?.flatMap(s => s.tabs.map(t => <div key={t.id}>{t.content}</div>))}
    </div>
  ),
}))

function wrapper({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      <MemoryRouter initialEntries={['/pengembangan/franchisees/f1']}>
        <Routes>
          <Route path="/pengembangan/franchisees/:id" element={children} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('FranchiseeDetailPage — AgreementFormModal', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders "Buat Perjanjian" button when no agreement', async () => {
    render(<FranchiseeDetailPage />, { wrapper })
    await waitFor(() => expect(screen.getByText('Buat Perjanjian')).toBeTruthy())
  })

  it('opens agreement modal on click', async () => {
    const user = userEvent.setup()
    render(<FranchiseeDetailPage />, { wrapper })
    await waitFor(() => screen.getByText('Buat Perjanjian'))
    await user.click(screen.getByText('Buat Perjanjian'))
    expect(screen.getAllByText('Buat Perjanjian').length).toBeGreaterThan(1)
  })
})
```

- [ ] **Step 1.2: Run test to verify it fails**

```bash
cd web-dashboard && npx vitest run src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx 2>&1 | tail -20
```

Expected: FAIL — "Buat Perjanjian" not found.

- [ ] **Step 1.3: Add state + handler + modal to FranchiseeDetailPage**

Add imports at top of `web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx`:

```tsx
import { useState } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { Store, Pencil, FileText, DollarSign, TrendingUp, Plus, Trash2, X } from 'lucide-react'
import { toast } from '@/widgets/Toast/Toast'
```

Remove the old `import { Store, Pencil, FileText, DollarSign, TrendingUp } from 'lucide-react'` line and replace with the line above.

Add inside `FranchiseeDetailPage()` function, after `const navigate = useNavigate()`:

```tsx
const queryClient = useQueryClient()

// ── Agreement modal state ──
const [agreementModalOpen, setAgreementModalOpen] = useState(false)
const [agreementForm, setAgreementForm] = useState({
  buy_in_fee: '', monthly_royalty: '', revenue_royalty_pct: '',
  start_date: '', end_date: '', status: 'active',
})
const [agreementSaving, setAgreementSaving] = useState(false)

function openAgreementModal() {
  if (agreement) {
    setAgreementForm({
      buy_in_fee: String(agreement.buy_in_fee ?? ''),
      monthly_royalty: String(agreement.monthly_royalty ?? ''),
      revenue_royalty_pct: String(agreement.revenue_royalty_pct ?? ''),
      start_date: agreement.start_date ?? '',
      end_date: agreement.end_date ?? '',
      status: agreement.status ?? 'active',
    })
  } else {
    setAgreementForm({ buy_in_fee: '', monthly_royalty: '', revenue_royalty_pct: '', start_date: '', end_date: '', status: 'active' })
  }
  setAgreementModalOpen(true)
}

async function handleAgreementSubmit() {
  setAgreementSaving(true)
  try {
    const payload = {
      buy_in_fee: Number(agreementForm.buy_in_fee),
      monthly_royalty: Number(agreementForm.monthly_royalty),
      revenue_royalty_pct: Number(agreementForm.revenue_royalty_pct),
      start_date: agreementForm.start_date,
      end_date: agreementForm.end_date || undefined,
      status: agreementForm.status,
    }
    if (agreement) {
      await franchiseeService.updateAgreement(id!, agreement.id, payload)
    } else {
      await franchiseeService.createAgreement(id!, payload)
    }
    toast.success('Perjanjian berhasil disimpan')
    await queryClient.invalidateQueries({ queryKey: ['franchisee-agreement', id] })
    setAgreementModalOpen(false)
  } catch {
    toast.error('Gagal menyimpan perjanjian')
  } finally {
    setAgreementSaving(false)
  }
}
```

Replace `AgreementContent` function with:

```tsx
function AgreementContent({ agreement, onEdit }: { agreement: FranchiseAgreement | undefined; onEdit: () => void }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 'var(--space-3)' }}>
        <button
          onClick={onEdit}
          style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '6px 12px', borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary)', color: '#fff',
            border: 'none', cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 500,
          }}
        >
          {agreement ? <><Pencil size={13} />{'Edit Perjanjian'}</> : <><Plus size={13} />{'Buat Perjanjian'}</>}
        </button>
      </div>
      {agreement ? (
        <>
          <InfoRow label="Buy-in Fee" value={formatCurrency(agreement.buy_in_fee)} />
          <InfoRow label="Royalti Bulanan" value={formatCurrency(agreement.monthly_royalty)} />
          <InfoRow label="Royalti Pendapatan" value={`${agreement.revenue_royalty_pct ?? 0}%`} />
          <InfoRow label="Tanggal Mulai" value={formatDate(agreement.start_date)} />
          <InfoRow label="Tanggal Berakhir" value={formatDate(agreement.end_date)} />
          <InfoRow label="Status" value={<StatusBadge status={agreement.status} />} />
        </>
      ) : (
        <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Belum ada perjanjian.</p>
      )}
    </div>
  )
}
```

In the `sections` array, update the agreement tab content from:
```tsx
content: <AgreementContent agreement={agreement} />,
```
to:
```tsx
content: <AgreementContent agreement={agreement} onEdit={openAgreementModal} />,
```

Add agreement modal JSX just before the closing `</DetailPageTemplate>` tag (i.e., as a sibling rendered after `<DetailPageTemplate ...>`):

```tsx
{agreementModalOpen && (
  <div
    style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 400,
      display: 'flex', alignItems: 'center', justifyContent: 'center' }}
    onClick={() => setAgreementModalOpen(false)}
  >
    <div
      style={{ background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', width: 480, overflow: 'hidden' }}
      onClick={(e) => e.stopPropagation()}
    >
      <div style={{ padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--color-border)',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h3 style={{ fontSize: 'var(--font-base)', fontWeight: 700 }}>
          {agreement ? 'Edit Perjanjian' : 'Buat Perjanjian'}
        </h3>
        <button onClick={() => setAgreementModalOpen(false)}
          style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-tertiary)' }}>
          <X size={16} />
        </button>
      </div>
      <div style={{ padding: 'var(--space-5)', display: 'flex', flexDirection: 'column', gap: 'var(--space-3)' }}>
        {([
          { label: 'Buy-in Fee (IDR)', name: 'buy_in_fee', type: 'number' },
          { label: 'Royalti Bulanan (IDR)', name: 'monthly_royalty', type: 'number' },
          { label: 'Royalti Pendapatan (%)', name: 'revenue_royalty_pct', type: 'number' },
          { label: 'Tanggal Mulai', name: 'start_date', type: 'date' },
          { label: 'Tanggal Berakhir (opsional)', name: 'end_date', type: 'date' },
        ] as const).map(({ label, name, type }) => (
          <div key={name}>
            <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 500, marginBottom: 4 }}>{label}</label>
            <input
              type={type}
              name={name}
              value={agreementForm[name]}
              onChange={(e) => setAgreementForm(f => ({ ...f, [e.target.name]: e.target.value }))}
              style={{ width: '100%', padding: '8px 10px', borderRadius: 'var(--radius-md)',
                border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
                background: 'var(--color-surface)', boxSizing: 'border-box' }}
            />
          </div>
        ))}
        <div>
          <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 500, marginBottom: 4 }}>Status</label>
          <select
            value={agreementForm.status}
            onChange={(e) => setAgreementForm(f => ({ ...f, status: e.target.value }))}
            style={{ width: '100%', padding: '8px 10px', borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)', background: 'var(--color-surface)' }}
          >
            <option value="active">Aktif</option>
            <option value="terminated">Diakhiri</option>
          </select>
        </div>
      </div>
      <div style={{ padding: 'var(--space-4) var(--space-5)', borderTop: '1px solid var(--color-border)',
        display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-2)' }}>
        <button onClick={() => setAgreementModalOpen(false)}
          style={{ padding: '8px 16px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)',
            background: 'var(--color-surface)', cursor: 'pointer', fontSize: 'var(--font-sm)' }}>
          Batal
        </button>
        <button onClick={handleAgreementSubmit} disabled={agreementSaving}
          style={{ padding: '8px 16px', borderRadius: 'var(--radius-md)', border: 'none',
            background: 'var(--color-primary)', color: '#fff', cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 500 }}>
          {agreementSaving ? 'Menyimpan...' : 'Simpan'}
        </button>
      </div>
    </div>
  </div>
)}
```

Wrap the return to use a fragment since we're adding the modal outside `<DetailPageTemplate>`:

```tsx
return (
  <>
    <DetailPageTemplate
      {/* ...all existing props... */}
    />
    {agreementModalOpen && (
      {/* ...modal JSX from above... */}
    )}
  </>
)
```

- [ ] **Step 1.4: Run test to verify it passes**

```bash
cd web-dashboard && npx vitest run src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx 2>&1 | tail -20
```

Expected: PASS — both tests pass.

- [ ] **Step 1.5: Commit**

```bash
git add web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx \
        web-dashboard/src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx
git commit -m "feat(franchise): add agreement create/edit modal to FranchiseeDetailPage"
```

---

## Task 2: RoyaltyPaymentFormModal + Tandai Lunas

**Files:**
- Modify: `web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx`
- Modify: `web-dashboard/src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx`

- [ ] **Step 2.1: Write failing tests**

Add to `FranchiseeDetailPage.test.tsx` (append inside the file, before the last `}`):

```tsx
describe('FranchiseeDetailPage — RoyaltyPaymentFormModal', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders "Tambah Pembayaran" button in royalty section', async () => {
    render(<FranchiseeDetailPage />, { wrapper })
    await waitFor(() => expect(screen.getByText('Tambah Pembayaran')).toBeTruthy())
  })

  it('opens royalty modal on click', async () => {
    const user = userEvent.setup()
    render(<FranchiseeDetailPage />, { wrapper })
    await waitFor(() => screen.getByText('Tambah Pembayaran'))
    await user.click(screen.getByText('Tambah Pembayaran'))
    expect(screen.getByText('Tambah Pembayaran Royalti')).toBeTruthy()
  })

  it('renders "Tandai Lunas" for unpaid royalty rows', async () => {
    const { franchiseeService } = await import('@/services/franchisee.service')
    vi.mocked(franchiseeService.listRoyaltyPayments).mockResolvedValueOnce({
      items: [{ id: 'r1', franchisee_id: 'f1', period: '2026-01', gross_revenue: 10000000,
        monthly_royalty: 5000000, revenue_royalty: 500000, total_royalty: 5500000,
        status: 'unpaid', created_at: '2026-01-01' }],
      total: 1, offset: 0, limit: 20,
    })
    render(<FranchiseeDetailPage />, { wrapper })
    await waitFor(() => expect(screen.getByText('Tandai Lunas')).toBeTruthy())
  })
})
```

- [ ] **Step 2.2: Run test to verify it fails**

```bash
cd web-dashboard && npx vitest run src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx 2>&1 | tail -20
```

Expected: FAIL — "Tambah Pembayaran" not found.

- [ ] **Step 2.3: Add royalty state + handlers + modal to FranchiseeDetailPage**

Add inside `FranchiseeDetailPage()` after the agreement state block:

```tsx
// ── Royalty payment modal state ──
const [royaltyModalOpen, setRoyaltyModalOpen] = useState(false)
const [royaltyForm, setRoyaltyForm] = useState({ period: '', gross_revenue: '' })
const [royaltySaving, setRoyaltySaving] = useState(false)

async function handleRoyaltySubmit() {
  setRoyaltySaving(true)
  try {
    await franchiseeService.createRoyaltyPayment(id!, {
      period: royaltyForm.period,
      gross_revenue: Number(royaltyForm.gross_revenue),
    })
    toast.success('Pembayaran royalti berhasil ditambahkan')
    await queryClient.invalidateQueries({ queryKey: ['franchisee-royalty', id] })
    setRoyaltyModalOpen(false)
    setRoyaltyForm({ period: '', gross_revenue: '' })
  } catch {
    toast.error('Gagal menambahkan pembayaran royalti')
  } finally {
    setRoyaltySaving(false)
  }
}

async function handleMarkPaid(paymentId: string) {
  try {
    await franchiseeService.markRoyaltyPaid(id!, paymentId)
    toast.success('Pembayaran berhasil ditandai lunas')
    await queryClient.invalidateQueries({ queryKey: ['franchisee-royalty', id] })
  } catch {
    toast.error('Gagal menandai pembayaran sebagai lunas')
  }
}
```

Replace `RoyaltyContent` function with:

```tsx
function RoyaltyContent({
  payments, onAdd, onMarkPaid,
}: {
  payments: RoyaltyPayment[] | undefined
  onAdd: () => void
  onMarkPaid: (id: string) => void
}) {
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 'var(--space-3)' }}>
        <button
          onClick={onAdd}
          style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '6px 12px', borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary)', color: '#fff',
            border: 'none', cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 500,
          }}
        >
          <Plus size={13} />{'Tambah Pembayaran'}
        </button>
      </div>
      {(!payments || payments.length === 0) ? (
        <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Belum ada data royalti.</p>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: 'var(--color-surface-alt)' }}>
                {['Periode', 'Pendapatan Kotor', 'Royalti Bulanan', 'Royalti Pendapatan', 'Total', 'Status', 'Dibayar', ''].map((h) => (
                  <th key={h} style={{ ...TABLE_CELL_STYLE, fontWeight: 600, color: 'var(--color-text-secondary)' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {payments.map((p) => (
                <tr key={p.id}>
                  <td style={TABLE_CELL_STYLE}>{p.period}</td>
                  <td style={TABLE_CELL_STYLE}>{formatCurrency(p.gross_revenue)}</td>
                  <td style={TABLE_CELL_STYLE}>{formatCurrency(p.monthly_royalty)}</td>
                  <td style={TABLE_CELL_STYLE}>{formatCurrency(p.revenue_royalty)}</td>
                  <td style={{ ...TABLE_CELL_STYLE, fontWeight: 600 }}>{formatCurrency(p.total_royalty)}</td>
                  <td style={TABLE_CELL_STYLE}><StatusBadge status={p.status} /></td>
                  <td style={TABLE_CELL_STYLE}>{formatDate(p.paid_at)}</td>
                  <td style={TABLE_CELL_STYLE}>
                    {p.status !== 'paid' && (
                      <button
                        onClick={() => onMarkPaid(p.id)}
                        style={{
                          padding: '4px 10px', borderRadius: 'var(--radius-md)',
                          border: '1px solid var(--color-success)', background: 'var(--color-success-light)',
                          color: 'var(--color-success-dark)', cursor: 'pointer', fontSize: 'var(--font-xs)', fontWeight: 500,
                        }}
                      >
                        Tandai Lunas
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
```

In `sections` array, update royalty tab content from:
```tsx
content: <RoyaltyContent payments={royaltyPayments} />,
```
to:
```tsx
content: <RoyaltyContent payments={royaltyPayments} onAdd={() => setRoyaltyModalOpen(true)} onMarkPaid={handleMarkPaid} />,
```

Add royalty modal JSX inside the fragment return (after agreement modal):

```tsx
{royaltyModalOpen && (
  <div
    style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 400,
      display: 'flex', alignItems: 'center', justifyContent: 'center' }}
    onClick={() => setRoyaltyModalOpen(false)}
  >
    <div
      style={{ background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', width: 440, overflow: 'hidden' }}
      onClick={(e) => e.stopPropagation()}
    >
      <div style={{ padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--color-border)',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h3 style={{ fontSize: 'var(--font-base)', fontWeight: 700 }}>Tambah Pembayaran Royalti</h3>
        <button onClick={() => setRoyaltyModalOpen(false)}
          style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-tertiary)' }}>
          <X size={16} />
        </button>
      </div>
      <div style={{ padding: 'var(--space-5)', display: 'flex', flexDirection: 'column', gap: 'var(--space-3)' }}>
        <div>
          <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 500, marginBottom: 4 }}>Periode (YYYY-MM)</label>
          <input
            type="text"
            placeholder="2026-01"
            value={royaltyForm.period}
            onChange={(e) => setRoyaltyForm(f => ({ ...f, period: e.target.value }))}
            style={{ width: '100%', padding: '8px 10px', borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
              background: 'var(--color-surface)', boxSizing: 'border-box' }}
          />
        </div>
        <div>
          <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 500, marginBottom: 4 }}>Pendapatan Kotor (IDR)</label>
          <input
            type="number"
            value={royaltyForm.gross_revenue}
            onChange={(e) => setRoyaltyForm(f => ({ ...f, gross_revenue: e.target.value }))}
            style={{ width: '100%', padding: '8px 10px', borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
              background: 'var(--color-surface)', boxSizing: 'border-box' }}
          />
        </div>
      </div>
      <div style={{ padding: 'var(--space-4) var(--space-5)', borderTop: '1px solid var(--color-border)',
        display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-2)' }}>
        <button onClick={() => setRoyaltyModalOpen(false)}
          style={{ padding: '8px 16px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)',
            background: 'var(--color-surface)', cursor: 'pointer', fontSize: 'var(--font-sm)' }}>
          Batal
        </button>
        <button onClick={handleRoyaltySubmit} disabled={royaltySaving}
          style={{ padding: '8px 16px', borderRadius: 'var(--radius-md)', border: 'none',
            background: 'var(--color-primary)', color: '#fff', cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 500 }}>
          {royaltySaving ? 'Menyimpan...' : 'Tambah'}
        </button>
      </div>
    </div>
  </div>
)}
```

- [ ] **Step 2.4: Run test to verify it passes**

```bash
cd web-dashboard && npx vitest run src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx 2>&1 | tail -20
```

Expected: PASS — all 5 tests pass.

- [ ] **Step 2.5: Commit**

```bash
git add web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx \
        web-dashboard/src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx
git commit -m "feat(franchise): add royalty payment modal and mark-paid action"
```

---

## Task 3: OtherRevenueFormModal + Edit/Delete

**Files:**
- Modify: `web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx`
- Modify: `web-dashboard/src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx`

- [ ] **Step 3.1: Write failing tests**

Append to `FranchiseeDetailPage.test.tsx`:

```tsx
describe('FranchiseeDetailPage — OtherRevenueFormModal', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders "Tambah Pendapatan" button', async () => {
    render(<FranchiseeDetailPage />, { wrapper })
    await waitFor(() => expect(screen.getByText('Tambah Pendapatan')).toBeTruthy())
  })

  it('opens other revenue modal on click', async () => {
    const user = userEvent.setup()
    render(<FranchiseeDetailPage />, { wrapper })
    await waitFor(() => screen.getByText('Tambah Pendapatan'))
    await user.click(screen.getByText('Tambah Pendapatan'))
    expect(screen.getByText('Tambah Pendapatan Lain')).toBeTruthy()
  })

  it('renders edit and delete icons for each revenue row', async () => {
    const { franchiseeService } = await import('@/services/franchisee.service')
    vi.mocked(franchiseeService.listOtherRevenue).mockResolvedValueOnce({
      items: [{ id: 'o1', franchisee_id: 'f1', label: 'Penjualan Alat', amount: 1000000, revenue_date: '2026-01-15', created_at: '2026-01-15' }],
      total: 1, offset: 0, limit: 20,
    })
    render(<FranchiseeDetailPage />, { wrapper })
    await waitFor(() => expect(screen.getByText('Penjualan Alat')).toBeTruthy())
    expect(screen.getByTestId('edit-revenue-o1')).toBeTruthy()
    expect(screen.getByTestId('delete-revenue-o1')).toBeTruthy()
  })
})
```

- [ ] **Step 3.2: Run test to verify it fails**

```bash
cd web-dashboard && npx vitest run src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx 2>&1 | tail -20
```

Expected: FAIL — "Tambah Pendapatan" not found.

- [ ] **Step 3.3: Add other revenue state + handlers + modal to FranchiseeDetailPage**

Add inside `FranchiseeDetailPage()` after royalty state block:

```tsx
// ── Other revenue modal state ──
const [otherRevenueModalOpen, setOtherRevenueModalOpen] = useState(false)
const [editingRevenue, setEditingRevenue] = useState<OtherRevenue | null>(null)
const [otherRevenueForm, setOtherRevenueForm] = useState({ label: '', amount: '', revenue_date: '' })
const [otherRevenueSaving, setOtherRevenueSaving] = useState(false)

function openOtherRevenueModal(revenue?: OtherRevenue) {
  setEditingRevenue(revenue ?? null)
  setOtherRevenueForm(revenue
    ? { label: revenue.label, amount: String(revenue.amount), revenue_date: revenue.revenue_date }
    : { label: '', amount: '', revenue_date: '' }
  )
  setOtherRevenueModalOpen(true)
}

async function handleOtherRevenueSubmit() {
  setOtherRevenueSaving(true)
  try {
    const payload = {
      label: otherRevenueForm.label,
      amount: Number(otherRevenueForm.amount),
      revenue_date: otherRevenueForm.revenue_date,
    }
    if (editingRevenue) {
      await franchiseeService.updateOtherRevenue(id!, editingRevenue.id, payload)
    } else {
      await franchiseeService.createOtherRevenue(id!, payload)
    }
    toast.success('Pendapatan berhasil disimpan')
    await queryClient.invalidateQueries({ queryKey: ['franchisee-other-revenue', id] })
    setOtherRevenueModalOpen(false)
  } catch {
    toast.error('Gagal menyimpan pendapatan')
  } finally {
    setOtherRevenueSaving(false)
  }
}

async function handleDeleteRevenue(revenueId: string) {
  if (!window.confirm('Hapus pendapatan ini?')) return
  try {
    await franchiseeService.deleteOtherRevenue(id!, revenueId)
    toast.success('Pendapatan berhasil dihapus')
    await queryClient.invalidateQueries({ queryKey: ['franchisee-other-revenue', id] })
  } catch {
    toast.error('Gagal menghapus pendapatan')
  }
}
```

Replace `OtherRevenueContent` function with:

```tsx
function OtherRevenueContent({
  revenues, onAdd, onEdit, onDelete,
}: {
  revenues: OtherRevenue[] | undefined
  onAdd: () => void
  onEdit: (revenue: OtherRevenue) => void
  onDelete: (id: string) => void
}) {
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 'var(--space-3)' }}>
        <button
          onClick={onAdd}
          style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '6px 12px', borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary)', color: '#fff',
            border: 'none', cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 500,
          }}
        >
          <Plus size={13} />{'Tambah Pendapatan'}
        </button>
      </div>
      {(!revenues || revenues.length === 0) ? (
        <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Belum ada data pendapatan lain.</p>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: 'var(--color-surface-alt)' }}>
                {['Keterangan', 'Jumlah', 'Tanggal', ''].map((h) => (
                  <th key={h} style={{ ...TABLE_CELL_STYLE, fontWeight: 600, color: 'var(--color-text-secondary)' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {revenues.map((r) => (
                <tr key={r.id}>
                  <td style={TABLE_CELL_STYLE}>{r.label}</td>
                  <td style={{ ...TABLE_CELL_STYLE, fontWeight: 600 }}>{formatCurrency(r.amount)}</td>
                  <td style={TABLE_CELL_STYLE}>{formatDate(r.revenue_date)}</td>
                  <td style={{ ...TABLE_CELL_STYLE, display: 'flex', gap: 'var(--space-1)' }}>
                    <button
                      data-testid={`edit-revenue-${r.id}`}
                      onClick={() => onEdit(r)}
                      style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-secondary)', padding: 4 }}
                    >
                      <Pencil size={14} />
                    </button>
                    <button
                      data-testid={`delete-revenue-${r.id}`}
                      onClick={() => onDelete(r.id)}
                      style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-error)', padding: 4 }}
                    >
                      <Trash2 size={14} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
```

In `sections` array, update other revenue tab content from:
```tsx
content: <OtherRevenueContent revenues={otherRevenues} />,
```
to:
```tsx
content: <OtherRevenueContent revenues={otherRevenues} onAdd={() => openOtherRevenueModal()} onEdit={openOtherRevenueModal} onDelete={handleDeleteRevenue} />,
```

Add other revenue modal JSX inside the fragment return (after royalty modal):

```tsx
{otherRevenueModalOpen && (
  <div
    style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 400,
      display: 'flex', alignItems: 'center', justifyContent: 'center' }}
    onClick={() => setOtherRevenueModalOpen(false)}
  >
    <div
      style={{ background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', width: 440, overflow: 'hidden' }}
      onClick={(e) => e.stopPropagation()}
    >
      <div style={{ padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--color-border)',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h3 style={{ fontSize: 'var(--font-base)', fontWeight: 700 }}>
          {editingRevenue ? 'Edit Pendapatan Lain' : 'Tambah Pendapatan Lain'}
        </h3>
        <button onClick={() => setOtherRevenueModalOpen(false)}
          style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-tertiary)' }}>
          <X size={16} />
        </button>
      </div>
      <div style={{ padding: 'var(--space-5)', display: 'flex', flexDirection: 'column', gap: 'var(--space-3)' }}>
        {([
          { label: 'Keterangan', name: 'label', type: 'text' },
          { label: 'Jumlah (IDR)', name: 'amount', type: 'number' },
          { label: 'Tanggal', name: 'revenue_date', type: 'date' },
        ] as const).map(({ label, name, type }) => (
          <div key={name}>
            <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 500, marginBottom: 4 }}>{label}</label>
            <input
              type={type}
              value={otherRevenueForm[name]}
              onChange={(e) => setOtherRevenueForm(f => ({ ...f, [name]: e.target.value }))}
              style={{ width: '100%', padding: '8px 10px', borderRadius: 'var(--radius-md)',
                border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
                background: 'var(--color-surface)', boxSizing: 'border-box' }}
            />
          </div>
        ))}
      </div>
      <div style={{ padding: 'var(--space-4) var(--space-5)', borderTop: '1px solid var(--color-border)',
        display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-2)' }}>
        <button onClick={() => setOtherRevenueModalOpen(false)}
          style={{ padding: '8px 16px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)',
            background: 'var(--color-surface)', cursor: 'pointer', fontSize: 'var(--font-sm)' }}>
          Batal
        </button>
        <button onClick={handleOtherRevenueSubmit} disabled={otherRevenueSaving}
          style={{ padding: '8px 16px', borderRadius: 'var(--radius-md)', border: 'none',
            background: 'var(--color-primary)', color: '#fff', cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 500 }}>
          {otherRevenueSaving ? 'Menyimpan...' : 'Simpan'}
        </button>
      </div>
    </div>
  </div>
)}
```

- [ ] **Step 3.4: Run test to verify it passes**

```bash
cd web-dashboard && npx vitest run src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx 2>&1 | tail -20
```

Expected: PASS — all 8 tests pass.

- [ ] **Step 3.5: Commit**

```bash
git add web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx \
        web-dashboard/src/pages/Franchisee/__tests__/FranchiseeDetailPage.test.tsx
git commit -m "feat(franchise): add other revenue create/edit/delete modal"
```

---

## Task 4: FranchiseManagementPage

**Files:**
- Modify: `web-dashboard/src/pages/BusinessDev/FranchiseManagementPage.tsx`
- Create: `web-dashboard/src/pages/BusinessDev/__tests__/FranchiseManagementPage.test.tsx`

- [ ] **Step 4.1: Write failing tests**

Create `web-dashboard/src/pages/BusinessDev/__tests__/FranchiseManagementPage.test.tsx`:

```tsx
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import FranchiseManagementPage from '../FranchiseManagementPage'

const mockFranchisees = [
  { id: 'f1', name: 'PT Edu Maju', branch_name: 'Cabang Jakarta', location: 'Jakarta Selatan', contact: '081', status: 'active', created_at: '2026-01-01' },
  { id: 'f2', name: 'PT Cerdas', branch_name: 'Cabang Bandung', location: 'Bandung', contact: '082', status: 'inactive', created_at: '2026-02-01' },
  { id: 'f3', name: 'PT Pintar', branch_name: 'Cabang Surabaya', location: 'Surabaya', contact: '083', status: 'terminated', created_at: '2026-03-01' },
]

vi.mock('@/services/franchisee.service', () => ({
  franchiseeService: {
    list: vi.fn().mockResolvedValue({ items: mockFranchisees, total: 3, offset: 0, limit: 1000 }),
  },
}))

function wrapper({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      <MemoryRouter>{children}</MemoryRouter>
    </QueryClientProvider>
  )
}

describe('FranchiseManagementPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders summary cards with correct counts', async () => {
    render(<FranchiseManagementPage />, { wrapper })
    await waitFor(() => {
      expect(screen.getByText('Total Franchisee')).toBeTruthy()
      expect(screen.getByText('Aktif')).toBeTruthy()
      expect(screen.getByText('Nonaktif / Diakhiri')).toBeTruthy()
    })
    // 3 total, 1 active, 2 inactive/terminated
    const cells = screen.getAllByText(/^[123]$/)
    expect(cells.length).toBeGreaterThanOrEqual(3)
  })

  it('renders franchisee rows in table', async () => {
    render(<FranchiseManagementPage />, { wrapper })
    await waitFor(() => {
      expect(screen.getByText('PT Edu Maju')).toBeTruthy()
      expect(screen.getByText('PT Cerdas')).toBeTruthy()
      expect(screen.getByText('PT Pintar')).toBeTruthy()
    })
  })

  it('filters by search input', async () => {
    const user = userEvent.setup()
    render(<FranchiseManagementPage />, { wrapper })
    await waitFor(() => screen.getByText('PT Edu Maju'))
    await user.type(screen.getByPlaceholderText('Cari nama / cabang...'), 'Bandung')
    await waitFor(() => {
      expect(screen.queryByText('PT Edu Maju')).toBeFalsy()
      expect(screen.getByText('PT Cerdas')).toBeTruthy()
    })
  })

  it('renders "Lihat Detail" button per row', async () => {
    render(<FranchiseManagementPage />, { wrapper })
    await waitFor(() => screen.getByText('PT Edu Maju'))
    const buttons = screen.getAllByText('Lihat Detail')
    expect(buttons).toHaveLength(3)
  })
})
```

- [ ] **Step 4.2: Run test to verify it fails**

```bash
cd web-dashboard && npx vitest run src/pages/BusinessDev/__tests__/FranchiseManagementPage.test.tsx 2>&1 | tail -20
```

Expected: FAIL — "Total Franchisee" not found (page is placeholder).

- [ ] **Step 4.3: Implement FranchiseManagementPage**

Replace `web-dashboard/src/pages/BusinessDev/FranchiseManagementPage.tsx` entirely with:

```tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Store, TrendingUp, AlertCircle } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { franchiseeService, type Franchisee } from '@/services/franchisee.service'

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:     { label: 'Aktif',     bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  inactive:   { label: 'Nonaktif',  bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  terminated: { label: 'Diakhiri', bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
}

const CELL: React.CSSProperties = {
  padding: 'var(--space-3) var(--space-4)', fontSize: 'var(--font-sm)',
  borderBottom: '1px solid var(--color-border)', textAlign: 'left',
}

export default function FranchiseManagementPage() {
  const navigate = useNavigate()
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')

  const { data } = useQuery({
    queryKey: ['franchisees-management'],
    queryFn: () => franchiseeService.list({ limit: 1000 }),
  })

  const all: Franchisee[] = data?.items ?? []
  const totalCount = all.length
  const activeCount = all.filter(f => f.status === 'active').length
  const inactiveCount = all.filter(f => f.status !== 'active').length

  const filtered = all.filter(f => {
    const q = search.toLowerCase()
    const matchSearch = !q || f.name.toLowerCase().includes(q) || f.branch_name.toLowerCase().includes(q)
    const matchStatus = !statusFilter || f.status === statusFilter
    return matchSearch && matchStatus
  })

  return (
    <div style={{ padding: 'var(--space-6)', maxWidth: 1200 }}>
      <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 700, marginBottom: 'var(--space-6)' }}>
        Manajemen Franchise
      </h1>

      {/* Summary cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 'var(--space-4)', marginBottom: 'var(--space-6)' }}>
        {[
          { label: 'Total Franchisee', value: totalCount, icon: <Store size={20} />, color: 'var(--color-primary)' },
          { label: 'Aktif', value: activeCount, icon: <TrendingUp size={20} />, color: 'var(--color-success)' },
          { label: 'Nonaktif / Diakhiri', value: inactiveCount, icon: <AlertCircle size={20} />, color: 'var(--color-warning)' },
        ].map(card => (
          <div key={card.label} style={{
            background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', padding: 'var(--space-4) var(--space-5)',
            display: 'flex', alignItems: 'center', gap: 'var(--space-4)',
          }}>
            <div style={{ color: card.color, flexShrink: 0 }}>{card.icon}</div>
            <div>
              <div style={{ fontSize: 'var(--font-2xl)', fontWeight: 700 }}>{card.value}</div>
              <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>{card.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Filter bar */}
      <div style={{ display: 'flex', gap: 'var(--space-3)', marginBottom: 'var(--space-4)' }}>
        <input
          placeholder="Cari nama / cabang..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          style={{ flex: 1, padding: '8px 12px', borderRadius: 'var(--radius-md)',
            border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)', background: 'var(--color-surface)' }}
        />
        <select
          value={statusFilter}
          onChange={e => setStatusFilter(e.target.value)}
          style={{ padding: '8px 12px', borderRadius: 'var(--radius-md)',
            border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)', background: 'var(--color-surface)' }}
        >
          <option value="">Semua Status</option>
          <option value="active">Aktif</option>
          <option value="inactive">Nonaktif</option>
          <option value="terminated">Diakhiri</option>
        </select>
      </div>

      {/* Table */}
      <div style={{ background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: 'var(--color-surface-alt)' }}>
              {['Nama', 'Cabang', 'Lokasi', 'Kontak', 'Status', 'Aksi'].map(h => (
                <th key={h} style={{ ...CELL, fontWeight: 600, color: 'var(--color-text-secondary)',
                  borderBottom: '1px solid var(--color-border)' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ padding: 'var(--space-8)', textAlign: 'center',
                  color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>
                  Tidak ada data franchisee.
                </td>
              </tr>
            ) : filtered.map(f => {
              const cfg = STATUS_CONFIG[f.status] ?? STATUS_CONFIG.inactive
              return (
                <tr key={f.id}>
                  <td style={{ ...CELL, fontWeight: 600 }}>{f.name}</td>
                  <td style={CELL}>{f.branch_name}</td>
                  <td style={CELL}>{f.location}</td>
                  <td style={CELL}>{f.contact}</td>
                  <td style={CELL}>
                    <span style={{ display: 'inline-block', padding: '2px 10px',
                      borderRadius: 'var(--radius-full)', fontSize: 'var(--font-xs)', fontWeight: 600,
                      background: cfg.bg, color: cfg.color }}>
                      {cfg.label}
                    </span>
                  </td>
                  <td style={CELL}>
                    <button
                      onClick={() => navigate(`/pengembangan/franchisees/${f.id}`)}
                      style={{ padding: '5px 12px', borderRadius: 'var(--radius-md)',
                        border: '1px solid var(--color-border)', background: 'var(--color-surface)',
                        cursor: 'pointer', fontSize: 'var(--font-xs)', fontWeight: 500 }}
                    >
                      Lihat Detail
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

- [ ] **Step 4.4: Run test to verify it passes**

```bash
cd web-dashboard && npx vitest run src/pages/BusinessDev/__tests__/FranchiseManagementPage.test.tsx 2>&1 | tail -20
```

Expected: PASS — all 4 tests pass.

- [ ] **Step 4.5: Run full test suite to check for regressions**

```bash
cd web-dashboard && npx vitest run 2>&1 | tail -30
```

Expected: All tests pass. If any pre-existing failures appear, confirm they existed before this branch by checking git stash.

- [ ] **Step 4.6: Commit**

```bash
git add web-dashboard/src/pages/BusinessDev/FranchiseManagementPage.tsx \
        web-dashboard/src/pages/BusinessDev/__tests__/FranchiseManagementPage.test.tsx
git commit -m "feat(franchise): implement FranchiseManagementPage with summary cards and table"
```

---

## Self-Review Checklist

- [x] Spec coverage: AgreementFormModal ✓, RoyaltyPaymentFormModal ✓, Tandai Lunas ✓, OtherRevenueFormModal ✓, edit/delete ✓, FranchiseManagementPage cards ✓, table ✓, search/filter ✓
- [x] No placeholders or TBD
- [x] Type consistency: `OtherRevenue` type imported from `franchisee.service`, used consistently in state and handlers
- [x] `franchiseeService` method names match service file: `createAgreement`, `updateAgreement`, `createRoyaltyPayment`, `markRoyaltyPaid`, `createOtherRevenue`, `updateOtherRevenue`, `deleteOtherRevenue` ✓
- [x] `invalidateQueries` query keys match `useQuery` keys: `['franchisee-agreement', id]`, `['franchisee-royalty', id]`, `['franchisee-other-revenue', id]` ✓
- [x] Fragment wrapper `<>...</>` needed in Task 1 since modals are siblings of `<DetailPageTemplate>` ✓
