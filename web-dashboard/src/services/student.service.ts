import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const studentService = {
  list: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/students${qs}`).then(r => (r as any).data ?? r)
  },

  getById: (id: string) =>
    apiClient.get<any>(`/students/${id}`).then(r => (r as any).data ?? r),

  create: (data: any) =>
    apiClient.post<any>('/students', data),

  update: (id: string, data: any) =>
    apiClient.put<any>(`/students/${id}`, data),

  delete: (id: string) =>
    apiClient.delete(`/students/${id}`),

  getEnrollmentHistory: (id: string) =>
    apiClient.get<any>(`/students/${id}/enrollment-history`).then(r => (r as any).data ?? r),

  getNotes: (id: string) =>
    apiClient.get<any>(`/students/${id}/notes`).then(r => (r as any).data ?? r),

  addNote: (id: string, data: any) =>
    apiClient.post<any>(`/students/${id}/notes`, data),

  getCrmLogs: (id: string) =>
    apiClient.get<any>(`/students/${id}/crm-logs`).then(r => (r as any).data ?? r),

  addCrmLog: (id: string, data: any) =>
    apiClient.post<any>(`/students/${id}/crm-logs`, data),

  getCertificates: (id: string) =>
    apiClient.get<any>(`/students/${id}/certificates`).then(r => (r as any).data ?? r),
}

function buildQS(params?: Record<string, any>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') q.set(k, String(v))
  })
  const s = q.toString()
  return s ? `?${s}` : ''
}
