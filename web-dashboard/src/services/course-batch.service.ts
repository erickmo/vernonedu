import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const courseBatchService = {
  list: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/course-batches${qs}`).then(r => (r as any).data ?? r)
  },

  getDetail: (batchId: string) =>
    apiClient.get<any>(`/course-batches/${batchId}/detail`).then(r => (r as any).data ?? r),

  create: (data: any) =>
    apiClient.post<any>('/course-batches', data),

  assignFacilitator: (batchId: string, facilitatorId: string) =>
    apiClient.put<any>(`/course-batches/${batchId}/facilitator`, { facilitator_id: facilitatorId }),
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
