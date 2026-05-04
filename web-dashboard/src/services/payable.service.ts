import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const payableService = {
  getStats: () =>
    apiClient.get<any>('/finance/payables/stats').then(r => (r as any).data ?? r),

  list: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/finance/payables${qs}`).then(r => (r as any).data ?? r)
  },

  getById: (id: string) =>
    apiClient.get<any>(`/finance/payables/${id}`).then(r => (r as any).data ?? r),

  markAsPaid: (id: string) =>
    apiClient.put<any>(`/finance/payables/${id}/pay`, {}),
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
