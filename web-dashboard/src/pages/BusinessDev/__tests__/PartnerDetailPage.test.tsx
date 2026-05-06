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
