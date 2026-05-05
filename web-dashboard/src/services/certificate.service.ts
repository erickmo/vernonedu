import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const certificateService = {
  list: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/certificates${qs}`).then(r => (r as any).data ?? r)
  },

  issueParticipant: (data: any) =>
    apiClient.post<any>('/certificates/participant', data),

  issueCompetency: (data: any) =>
    apiClient.post<any>('/certificates/competency', data),

  listByBatch: (batchId: string) =>
    apiClient.get<any>(`/batches/${batchId}/certificates`).then(r => (r as any).data ?? r),

  revoke: (id: string, reason: string) =>
    apiClient.post<any>(`/certificates/${id}/revoke`, { reason }),

  getTemplates: () =>
    apiClient.get<any>('/certificate-templates').then(r => (r as any).data ?? r),

  createTemplate: (data: any) =>
    apiClient.post<any>('/certificate-templates', data),

  updateTemplate: (id: string, data: any) =>
    apiClient.put<any>(`/certificate-templates/${id}`, data),
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
