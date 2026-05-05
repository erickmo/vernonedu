import { apiClient } from './api.client'
import type { PaginatedResponse } from '@/types/api.types'
import type { ListParams } from './createEntityService'

export const courseService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get(`/curriculum/courses${buildQS(params)}`).then(r => (r as any).data ?? r),

  getById: (id: string) =>
    apiClient.get<any>(`/curriculum/courses/${id}`).then(r => (r as any).data ?? r),

  create: (data: any) =>
    apiClient.post<any>('/curriculum/courses', data),

  update: (id: string, data: any) =>
    apiClient.put<any>(`/curriculum/courses/${id}`, data),

  delete: (id: string) =>
    apiClient.delete<void>(`/curriculum/courses/${id}`),

  archive: (id: string) =>
    apiClient.post<any>(`/curriculum/courses/${id}/archive`, {}),
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
