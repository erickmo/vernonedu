import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export interface Approval {
  id: string
  type: string
  subject: string
  description?: string
  status: 'pending' | 'approved' | 'rejected' | 'cancelled'
  requester_id: string
  requester_name?: string
  approver_id?: string
  created_at?: number
  updated_at?: number
  [key: string]: unknown
}

function buildQS(params?: Record<string, unknown>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') q.set(k, Array.isArray(v) ? JSON.stringify(v) : String(v))
  })
  const s = q.toString()
  return s ? `?${s}` : ''
}

export const approvalService = {
  list: async (params?: ListParams): Promise<PaginatedResponse<Approval>> => {
    const qs = buildQS({ ...params, status: 'pending' })
    const r = await apiClient.get<any>(`/approvals${qs}`)
    const raw = (r as any).data ?? r
    return {
      items: Array.isArray(raw.items) ? raw.items : (Array.isArray(raw) ? raw : []),
      total: raw.total ?? 0,
      offset: raw.offset ?? 0,
      limit: raw.limit ?? 100,
    }
  },
  approve: (id: string, note?: string) =>
    apiClient.put<any>(`/approvals/${id}/approve`, { note }),
  reject: (id: string, note?: string) =>
    apiClient.put<any>(`/approvals/${id}/reject`, { note }),
  cancel: (id: string) =>
    apiClient.put<any>(`/approvals/${id}/cancel`, {}),
}
