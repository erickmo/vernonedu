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

export const studentService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> => {
    const qs = buildQS(params)
    return apiClient.get<any>(`students${qs}`)
      .then(r => toPaginated(unwrap(r), []))
  },

  getById: (id: string) =>
    apiClient.get<any>(`students/${id}`).then(r => unwrap(r)),

  create: (data: any) =>
    apiClient.post<any>('students', data),

  update: (id: string, data: any) =>
    apiClient.put<any>(`students/${id}`, data),

  delete: (id: string) =>
    apiClient.delete(`students/${id}`),

  getEnrollmentHistory: (id: string) =>
    apiClient.get<any>(`students/${id}/enrollment-history`).then(r => unwrap(r)),

  getNotes: (id: string) =>
    apiClient.get<any>(`students/${id}/notes`).then(r => unwrap(r)),

  addNote: (id: string, data: any) =>
    apiClient.post<any>(`students/${id}/notes`, data),

  getCrmLogs: (id: string) =>
    apiClient.get<any>(`students/${id}/crm-logs`).then(r => unwrap(r)),

  addCrmLog: (id: string, data: any) =>
    apiClient.post<any>(`students/${id}/crm-logs`, data),

  getCertificates: (id: string) =>
    apiClient.get<any>(`students/${id}/certificates`).then(r => unwrap(r)),
}
