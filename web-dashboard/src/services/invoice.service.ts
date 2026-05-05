import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const invoiceService = {
  getStats: () =>
    apiClient.get<any>('/finance/invoices/stats').then(r => (r as any).data ?? r),

  list: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/finance/invoices${qs}`).then(r => (r as any).data ?? r)
  },

  getDetail: (id: string) =>
    apiClient.get<any>(`/finance/invoices/${id}`).then(r => (r as any).data ?? r),

  markAsPaid: (id: string) =>
    apiClient.put<any>(`/finance/invoices/${id}/pay`, {}),

  send: (id: string) =>
    apiClient.put<any>(`/finance/invoices/${id}/send`, {}),

  cancel: (id: string, reason: string) =>
    apiClient.put<any>(`/finance/invoices/${id}/cancel`, { reason }),

  createManual: (data: any) =>
    apiClient.post<any>('/finance/invoices', data),

  delete: (id: string) =>
    apiClient.delete<any>(`/finance/invoices/${id}`),
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
