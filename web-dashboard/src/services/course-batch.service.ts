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

export const courseBatchService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> => {
    const qs = buildQS(params)
    return apiClient.get<any>(`course-batches${qs}`)
      .then(r => toPaginated(unwrap(r), []))
  },

  getById: (batchId: string) =>
    apiClient.get<any>(`course-batches/${batchId}`).then(r => unwrap(r)),

  create: (data: {
    pricing: number
    paymentMethod: string
    minStudents: number
    maxStudents: number
    [key: string]: unknown
  }) =>
    apiClient.post<any>('course-batches', data),

  update: (batchId: string, data: unknown) =>
    apiClient.put<any>(`course-batches/${batchId}`, data),

  delete: (batchId: string) =>
    apiClient.delete(`course-batches/${batchId}`),

  assignFacilitator: (batchId: string, facilitatorId: string) =>
    apiClient.put<any>(`course-batches/${batchId}/facilitator`, { facilitator_id: facilitatorId }),
}
