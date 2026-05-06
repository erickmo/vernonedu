import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import FranchiseeDetailPage from '../FranchiseeDetailPage'

vi.mock('@/services/franchisee.service', () => ({
  franchiseeService: {
    getById: vi.fn().mockResolvedValue({
      id: 'f1', name: 'PT Edu Maju', branch_name: 'Cabang Jakarta', location: 'Jakarta Selatan',
      contact: '08111222333', status: 'active', created_at: '2026-01-01',
    }),
    getAgreement: vi.fn().mockResolvedValue(null),
    listRoyaltyPayments: vi.fn().mockResolvedValue({ items: [], total: 0 }),
    listOtherRevenue: vi.fn().mockResolvedValue({ items: [], total: 0 }),
    createAgreement: vi.fn().mockResolvedValue({
      data: {
        id: 'a1', franchisee_id: 'f1', buy_in_fee: 50000000, monthly_royalty: 5000000,
        revenue_royalty_pct: 5, start_date: '2026-01-01', end_date: '2027-01-01',
        status: 'active', created_at: '2026-01-01',
      },
    }),
    updateAgreement: vi.fn().mockResolvedValue({
      data: {
        id: 'a1', franchisee_id: 'f1', buy_in_fee: 50000000, monthly_royalty: 5000000,
        revenue_royalty_pct: 5, start_date: '2026-01-01', end_date: '2027-01-01',
        status: 'active', created_at: '2026-01-01',
      },
    }),
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
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  DetailPageTemplate: ({ sections }: { sections?: any[] }) => (
    <div data-testid="detail-page">
      {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
      {sections?.flatMap((s: any) => s.tabs.map((t: any) => <div key={t.id}>{t.content}</div>))}
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
