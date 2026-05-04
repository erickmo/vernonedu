import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export interface Notification {
  id: string
  title: string
  body?: string
  type?: string
  is_read?: boolean
  created_at?: number
  [key: string]: unknown
}

function buildQS(params?: Record<string, unknown>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') q.set(k, String(v))
  })
  const s = q.toString()
  return s ? `?${s}` : ''
}

export const notificationService = {
  list: async (params?: ListParams): Promise<PaginatedResponse<Notification>> => {
    const qs = buildQS(params as Record<string, unknown>)
    const r = await apiClient.get<any>(`/notifications${qs}`)
    const raw = (r as any).data ?? r
    const items = Array.isArray(raw.items) ? raw.items : (Array.isArray(raw) ? raw : [])
    return { items, total: raw.total ?? items.length, offset: raw.offset ?? 0, limit: raw.limit ?? 100 }
  },

  markRead: (id: string) =>
    apiClient.put<any>(`/notifications/${id}/read`, {}),

  markAllRead: () =>
    apiClient.put<any>('/notifications/read-all', {}),
}
