import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const leadService = {
  list: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/leads${qs}`).then(r => (r as any).data ?? r)
  },

  getById: (id: string) =>
    apiClient.get<any>(`/leads/${id}`).then(r => (r as any).data ?? r),

  create: (data: any) =>
    apiClient.post<any>('/leads', data),

  update: (id: string, data: any) =>
    apiClient.put<any>(`/leads/${id}`, data),

  delete: (id: string) =>
    apiClient.delete(`/leads/${id}`),

  getCrmLogs: (id: string) =>
    apiClient.get<any>(`/leads/${id}/crm-logs`).then(r => (r as any).data ?? r),

  addCrmLog: (id: string, data: any) =>
    apiClient.post<any>(`/leads/${id}/crm-logs`, data),

  convertToStudent: (id: string) =>
    apiClient.post<any>(`/leads/${id}/convert`, {}),
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
