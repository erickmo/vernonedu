import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

function toPaginated<T>(raw: any, fallback: T[]): PaginatedResponse<T> {
  if (raw && typeof raw === 'object' && 'items' in raw) return raw
  const list = Array.isArray(raw) ? raw : fallback
  return { items: list, total: list.length, limit: 9999, offset: 0 }
}

function buildQS(params?: Record<string, any>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') {
      q.set(k, Array.isArray(v) ? JSON.stringify(v) : String(v))
    }
  })
  const s = q.toString()
  return s ? `?${s}` : ''
}

export const departmentService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<any>(`/departments${buildQS(params)}`)
      .then(r => toPaginated((r as any).data ?? r, [])),

  getById: (id: string) =>
    apiClient.get<any>(`/departments/${id}`).then(r => (r as any).data ?? r),

  create: (data: any) =>
    apiClient.post<any>('/departments', data),

  update: (id: string, data: any) =>
    apiClient.put<any>(`/departments/${id}`, data),

  delete: (id: string) =>
    apiClient.delete<void>(`/departments/${id}`),

  assignLeader: (id: string, leaderId: string) =>
    apiClient.put(`/departments/${id}/leader`, { leader_id: leaderId }),

  getSummaries: () =>
    apiClient.get<any>('/departments/summaries').then(r => (r as any).data ?? r),

  getBatches: (id: string) =>
    apiClient.get<any>(`/departments/${id}/batches`).then(r => {
      const d = (r as any).data ?? r
      return Array.isArray(d) ? d : d?.items ?? []
    }),

  getCourses: (id: string) =>
    apiClient.get<any>(`/departments/${id}/courses`).then(r => {
      const d = (r as any).data ?? r
      return Array.isArray(d) ? d : d?.items ?? []
    }),

  getStudents: (id: string, params?: ListParams) =>
    apiClient.get<any>(`/departments/${id}/students${buildQS(params)}`).then(r => {
      const d = (r as any).data ?? r
      return Array.isArray(d) ? d : d?.items ?? []
    }),

  getTalentPool: (id: string) =>
    apiClient.get<any>(`/departments/${id}/talentpool`).then(r => {
      const d = (r as any).data ?? r
      return Array.isArray(d) ? d : d?.items ?? []
    }),
}
