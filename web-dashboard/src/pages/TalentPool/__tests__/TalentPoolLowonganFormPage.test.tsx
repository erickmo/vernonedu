import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import TalentPoolLowonganFormPage from '../TalentPoolLowonganFormPage'

vi.mock('@/services/jobvacancy.service', () => ({
  jobVacancyService: {
    getById: vi.fn().mockResolvedValue({
      id: '1', title: 'Frontend Dev', partner_id: 'p1', status: 'draft',
    }),
    create: vi.fn().mockResolvedValue(undefined),
    update: vi.fn().mockResolvedValue(undefined),
  },
}))

vi.mock('@/services/partner.service', () => ({
  partnerService: {
    list: vi.fn().mockResolvedValue({ items: [], total: 0 }),
  },
}))

vi.mock('@/services/api.client', () => ({
  apiClient: {
    get: vi.fn().mockResolvedValue({ data: { data: [], total: 0 } }),
  },
}))

vi.mock('@/widgets/FormPageTemplate', () => ({
  FormPageTemplate: ({ title, tabs }: any) => (
    <div data-testid="form-page">
      <div data-testid="form-title">{title}</div>
      {tabs?.map((t: any) => <div key={t.id}>{t.content}</div>)}
    </div>
  ),
  Field: ({ label, children }: any) => <div><label>{label}</label>{children}</div>,
  FieldRow: ({ children }: any) => <div>{children}</div>,
  FieldSection: ({ title, children }: any) => (
    <div data-testid={`section-${title}`}><h2>{title}</h2>{children}</div>
  ),
  FormGrid: ({ children }: any) => <div>{children}</div>,
  FormColumn: ({ children }: any) => <div>{children}</div>,
}))

vi.mock('@/widgets/SearchableSelect/SearchableSelect', () => ({
  SearchableSelect: ({ placeholder }: any) => <button>{placeholder}</button>,
}))

vi.mock('@/widgets/DatePicker/DatePicker', () => ({
  DatePicker: () => <button>Pilih tanggal</button>,
}))

vi.mock('@/widgets/TagInput/TagInput', () => ({
  TagInput: () => <div data-testid="tag-input" />,
}))

function wrapper({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      <MemoryRouter initialEntries={['/talentpool/lowongan/new']}>
        <Routes>
          <Route path="/talentpool/lowongan/new" element={children} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('TalentPoolLowonganFormPage', () => {
  it('renders Tambah Lowongan title in create mode', () => {
    render(<TalentPoolLowonganFormPage />, { wrapper })
    expect(screen.getByTestId('form-title').textContent).toBe('Tambah Lowongan')
  })

  it('renders Informasi Dasar section', () => {
    render(<TalentPoolLowonganFormPage />, { wrapper })
    expect(screen.getByTestId('section-Informasi Dasar')).toBeTruthy()
  })

  it('renders Detail Pekerjaan section', () => {
    render(<TalentPoolLowonganFormPage />, { wrapper })
    expect(screen.getByTestId('section-Detail Pekerjaan')).toBeTruthy()
  })

  it('renders Kompensasi section', () => {
    render(<TalentPoolLowonganFormPage />, { wrapper })
    expect(screen.getByTestId('section-Kompensasi')).toBeTruthy()
  })

  it('renders Kualifikasi section', () => {
    render(<TalentPoolLowonganFormPage />, { wrapper })
    expect(screen.getByTestId('section-Kualifikasi')).toBeTruthy()
  })

  it('uses TagInput for skill dibutuhkan', () => {
    render(<TalentPoolLowonganFormPage />, { wrapper })
    expect(screen.getByTestId('tag-input')).toBeTruthy()
  })
})
