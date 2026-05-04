import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const talentPoolService = {
  list: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/talentpool${qs}`).then(r => (r as any).data ?? r)
  },

  getById: (id: string) =>
    apiClient.get<any>(`/talentpool/${id}`).then(r => (r as any).data ?? r),

  updateStatus: (id: string, status: string) =>
    apiClient.put<any>(`/talentpool/${id}/status`, { status }),
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
