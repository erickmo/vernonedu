import { describe, it, expect, vi, beforeEach } from 'vitest'
import { franchiseeService } from '../franchisee.service'
import { apiClient } from '../api.client'

vi.mock('../api.client', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
  },
}))

describe('franchiseeService', () => {
  beforeEach(() => vi.clearAllMocks())

  it('list calls GET /franchisees with params', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({
      data: { data: [], total: 0, offset: 0, limit: 20 },
    })
    await franchiseeService.list({ offset: 0, limit: 20 })
    expect(apiClient.get).toHaveBeenCalledWith('/franchisees?offset=0&limit=20')
  })

  it('getById calls GET /franchisees/:id', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: { id: 'abc' } })
    await franchiseeService.getById('abc')
    expect(apiClient.get).toHaveBeenCalledWith('/franchisees/abc')
  })

  it('create calls POST /franchisees', async () => {
    vi.mocked(apiClient.post).mockResolvedValue({})
    const payload = { name: 'PT X', branch_name: 'Branch A', location: 'Jkt', contact: '', status: 'active' }
    await franchiseeService.create(payload)
    expect(apiClient.post).toHaveBeenCalledWith('/franchisees', expect.objectContaining({ name: 'PT X' }))
  })

  it('update calls PUT /franchisees/:id', async () => {
    vi.mocked(apiClient.put).mockResolvedValue({})
    const payload = { name: 'PT Y', branch_name: 'Branch B', location: 'Sby', contact: '', status: 'inactive' }
    await franchiseeService.update('abc', payload)
    expect(apiClient.put).toHaveBeenCalledWith('/franchisees/abc', expect.objectContaining({ name: 'PT Y' }))
  })
})
