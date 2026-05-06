import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import FranchiseManagementPage from '../FranchiseManagementPage'
import { franchiseeService } from '@/services/franchisee.service'

const mockFranchisees = [
  { id: 'f1', name: 'PT Edu Maju', branch_name: 'Cabang Jakarta', location: 'Jakarta Selatan', contact: '081', status: 'active', created_at: '2026-01-01' },
  { id: 'f2', name: 'PT Cerdas', branch_name: 'Cabang Bandung', location: 'Bandung', contact: '082', status: 'inactive', created_at: '2026-02-01' },
  { id: 'f3', name: 'PT Pintar', branch_name: 'Cabang Surabaya', location: 'Surabaya', contact: '083', status: 'terminated', created_at: '2026-03-01' },
]

vi.mock('@/services/franchisee.service', () => ({
  franchiseeService: {
    list: vi.fn(),
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
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(franchiseeService.list).mockResolvedValue({ items: mockFranchisees, total: 3, offset: 0, limit: 1000 })
  })

  it('renders summary cards with correct labels', async () => {
    render(<FranchiseManagementPage />, { wrapper })
    await waitFor(() => {
      expect(screen.getByText('Total Franchisee')).toBeTruthy()
      expect(screen.getAllByText('Aktif').length).toBeGreaterThanOrEqual(1)
      expect(screen.getByText('Nonaktif / Diakhiri')).toBeTruthy()
    })
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
