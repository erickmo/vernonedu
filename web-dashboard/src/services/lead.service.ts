import { apiClient } from './api.client'
import { buildQueryString, extractPaginated } from './createEntityService'
import type { ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

function toLeadsParams(params?: ListParams): Record<string, unknown> {
  if (!params) return {}
  const { filters, ...rest } = params
  const extra: Record<string, unknown> = {}
  if (filters) {
    for (const [key, , value] of filters) {
      if (key === 'status' || key === 'source_id') extra[key] = value
    }
  }
  return { ...rest, ...extra }
}

export const leadService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/leads${buildQueryString(toLeadsParams(params))}`).then(extractPaginated),

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
