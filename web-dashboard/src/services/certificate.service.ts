import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const certificateService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/certificates${buildQueryString(params)}`).then(r => extractPaginated(r)),

  issueParticipant: (data: any) =>
    apiClient.post<any>('/certificates/participant', data),

  issueCompetency: (data: any) =>
    apiClient.post<any>('/certificates/competency', data),

  listByBatch: (batchId: string) =>
    apiClient.get<any>(`/batches/${batchId}/certificates`).then((r: any) => r?.data ?? r),

  revoke: (id: string, reason: string) =>
    apiClient.post<any>(`/certificates/${id}/revoke`, { reason }),

  getTemplates: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<any>(`/certificate-templates${buildQueryString(params)}`).then((r: any) => {
      const items = Array.isArray(r?.data) ? r.data : (Array.isArray(r) ? r : [])
      return { items, total: items.length, limit: 9999, offset: 0 }
    }),

  createTemplate: (data: any) =>
    apiClient.post<any>('/certificate-templates', data),

  updateTemplate: (id: string, data: any) =>
    apiClient.put<any>(`/certificate-templates/${id}`, data),
}
