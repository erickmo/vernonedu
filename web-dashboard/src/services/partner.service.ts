import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const partnerService = {
  list: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/partners${qs}`).then(r => (r as any).data ?? r)
  },

  getDetail: (id: string) =>
    apiClient.get<any>(`/partners/${id}`).then(r => (r as any).data ?? r),

  addMOU: (id: string, data: any) =>
    apiClient.post<any>(`/partners/${id}/mou`, data),
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
