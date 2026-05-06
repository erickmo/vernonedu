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

export const leadService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> => {
    const qs = buildQS(params)
    return apiClient.get<any>(`leads${qs}`).then(r => toPaginated(unwrap(r), []))
  },

  getById: (id: string) =>
    apiClient.get<any>(`leads/${id}`).then(r => unwrap(r)),

  create: (data: {
    name: string
    phone: string
    email?: string
    source_id?: string
    notes?: string
  }) => apiClient.post<any>('leads', data),

  update: (id: string, data: {
    name: string
    phone: string
    email?: string
    source_id?: string
    status?: string
    notes?: string
  }) => apiClient.put<any>(`leads/${id}`, data),

  delete: (id: string) =>
    apiClient.delete(`leads/${id}`),

  getCrmLogs: (id: string) =>
    apiClient.get<any>(`leads/${id}/crm-logs`).then(r => unwrap(r)),

  addCrmLog: (id: string, data: any) =>
    apiClient.post<any>(`leads/${id}/crm-logs`, data),

  convertToStudent: (id: string) =>
    apiClient.post<any>(`leads/${id}/convert`, {}),

  addInterest: (leadId: string, data: { entity_type: string; entity_id: string }) =>
    apiClient.post<any>(`leads/${leadId}/interests`, data),

  removeInterest: (leadId: string, interestId: string) =>
    apiClient.delete(`leads/${leadId}/interests/${interestId}`),
}
