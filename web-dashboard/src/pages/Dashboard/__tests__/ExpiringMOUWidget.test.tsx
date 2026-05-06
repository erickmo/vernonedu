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
