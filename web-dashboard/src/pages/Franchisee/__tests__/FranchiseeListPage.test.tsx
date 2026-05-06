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
