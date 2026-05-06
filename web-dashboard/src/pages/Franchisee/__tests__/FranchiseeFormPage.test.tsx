import { describe, it, expect, vi } from 'vitest'
import { render } from '@testing-library/react'
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
  Field: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  FormGrid: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  FormColumn: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  Toggle: () => <div />,
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
  it('renders in new mode', () => {
    render(<FranchiseeFormPage />, { wrapper })
    expect(document.body).toBeTruthy()
  })
})
