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

vi.mock('@/layouts/PageHeader/PageHeader', () => ({
  PageHeader: ({ title }: { title: string }) => <div>{title}</div>,
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
      expect(screen.getAllByText('PT Mitra Sejahtera').length).toBeGreaterThan(0)
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
