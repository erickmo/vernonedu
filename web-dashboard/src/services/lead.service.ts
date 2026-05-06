import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

function buildQS(params?: Record<string, unknown>): string {
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

export const leadService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<any>(`/leads${buildQS(params as Record<string, unknown>)}`).then((r: any) => ({
      items: Array.isArray(r?.data) ? r.data : [],
      total: r?.total ?? 0,
      limit: r?.limit ?? (params?.limit ?? 25),
      offset: r?.offset ?? 0,
    })),

  getById: (id: string) =>
    apiClient.get<any>(`/leads/${id}`).then((r: any) => r?.data ?? r),

  create: (data: {
    name: string
    phone: string
    email?: string
    source_id?: string
    notes?: string
  }) => apiClient.post<any>('/leads', data),

  update: (id: string, data: {
    name: string
    phone: string
    email?: string
    source_id?: string
    status?: string
    notes?: string
  }) => apiClient.put<any>(`/leads/${id}`, data),

  delete: (id: string) =>
    apiClient.delete(`/leads/${id}`),

  getCrmLogs: (id: string) =>
    apiClient.get<any>(`/leads/${id}/crm-logs`).then((r: any) => r?.data ?? r),

  addCrmLog: (id: string, data: any) =>
    apiClient.post<any>(`/leads/${id}/crm-logs`, data),

  convertToStudent: (id: string) =>
    apiClient.post<any>(`/leads/${id}/convert`, {}),

  addInterest: (leadId: string, data: { entity_type: string; entity_id: string }) =>
    apiClient.post<any>(`/leads/${leadId}/interests`, data),

  removeInterest: (leadId: string, interestId: string) =>
    apiClient.delete(`/leads/${leadId}/interests/${interestId}`),
}
