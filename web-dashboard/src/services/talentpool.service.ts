import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

function toPaginated<T>(raw: unknown, fallback: T[]): PaginatedResponse<T> {
  const r = raw as Record<string, unknown>
  if (r && typeof r === 'object' && 'items' in r) return r as unknown as PaginatedResponse<T>
  const list = Array.isArray(raw) ? raw : fallback
  return { items: list as T[], total: list.length, limit: 9999, offset: 0 }
}

function unwrap<T>(res: unknown): T {
  const r = res as Record<string, unknown>
  return (r?.data ?? res) as T
}

function buildQS(params?: Record<string, any>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') q.set(k, Array.isArray(v) ? JSON.stringify(v) : String(v))
  })
  const s = q.toString()
  return s ? `?${s}` : ''
}

export const talentPoolService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> => {
    const qs = buildQS(params)
    return apiClient.get<any>(`talentpool${qs}`)
      .then(r => toPaginated(unwrap(r), []))
  },

  getById: (id: string) =>
    apiClient.get<any>(`talentpool/${id}`).then(r => unwrap(r)),

  updateStatus: (id: string, status: string) =>
    apiClient.put<any>(`talentpool/${id}/status`, { status }),
}
