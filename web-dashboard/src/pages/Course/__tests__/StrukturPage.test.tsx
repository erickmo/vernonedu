import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import StrukturPage from '../StrukturPage'
import { departmentService } from '@/services/department.service'
import { courseBatchService } from '@/services/course-batch.service'
import { useAuthStore } from '@/stores/auth.store'

vi.mock('@/services/department.service')
vi.mock('@/services/course-batch.service')
vi.mock('@/stores/auth.store')

const mockDepts = {
  items: [
    { id: 'd1', name: 'Dept Digital' },
    { id: 'd2', name: 'Dept Bisnis' },
  ],
  total: 2, limit: 100, offset: 0,
}

const mockCourses = [{ id: 'c1', name: 'Web Dev' }, { id: 'c2', name: 'UI/UX' }]

const mockBatches = {
  data: {
    data: [
      { id: 'b1', name: 'Batch Jun 2026', status: 'active', student_count: 18, session_done: 4, session_total: 10 },
      { id: 'b2', name: 'Batch Jan 2026', status: 'completed', student_count: 12, session_done: 10, session_total: 10 },
    ],
  },
}

function renderPage(roles: string[] = ['education_leader'], depts = mockDepts) {
  vi.mocked(useAuthStore).mockReturnValue({ user: { id: 'u1', name: 'Test', email: 'x@x.com', roles } } as any)
  vi.mocked(departmentService.list).mockResolvedValue(depts as any)
  vi.mocked(departmentService.getCourses).mockResolvedValue(mockCourses as any)
  vi.mocked(courseBatchService.list).mockResolvedValue(mockBatches as any)
  return render(<MemoryRouter><StrukturPage /></MemoryRouter>)
}

describe('StrukturPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('renders page title', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByText('Struktur Pendidikan')).toBeInTheDocument())
  })

  it('shows dept cards after loading', async () => {
    renderPage()
    await waitFor(() => {
      expect(screen.getByText('Dept Digital')).toBeInTheDocument()
      expect(screen.getByText('Dept Bisnis')).toBeInTheDocument()
    })
  })

  it('shows course names inside expanded dept', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByText('Web Dev')).toBeInTheDocument())
  })

  it('shows batch info', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByText('Batch Jun 2026')).toBeInTheDocument())
  })

  it('shows Add Dept button for education_leader', async () => {
    renderPage(['education_leader'])
    await waitFor(() => expect(screen.getByText('+ Tambah Departemen')).toBeInTheDocument())
  })

  it('hides Add Dept button for facilitator', async () => {
    renderPage(['facilitator'])
    await waitFor(() => expect(screen.queryByText('+ Tambah Departemen')).not.toBeInTheDocument())
  })

  it('shows Add Batch button for course_owner', async () => {
    renderPage(['course_owner'])
    await waitFor(() => expect(screen.getAllByText('+ Batch').length).toBeGreaterThan(0))
  })

  it('hides Add Batch button for facilitator', async () => {
    renderPage(['facilitator'])
    await waitFor(() => expect(screen.queryByText('+ Batch')).not.toBeInTheDocument())
  })

  it('toggles to tree view when Tree button clicked', async () => {
    renderPage()
    await waitFor(() => screen.getByText('≡ Tree'))
    await userEvent.click(screen.getByText('≡ Tree'))
    expect(localStorage.getItem('struktur_view')).toBe('tree')
  })

  it('shows empty state when no depts', async () => {
    renderPage(['education_leader'], { items: [], total: 0, limit: 100, offset: 0 })
    await waitFor(() => expect(screen.getByText(/Belum ada departemen/)).toBeInTheDocument())
  })
})
