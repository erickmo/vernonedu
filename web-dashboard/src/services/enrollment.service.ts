import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const enrollmentService = {
  list: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/enrollments${qs}`).then(r => (r as any).data ?? r)
  },

  getSummary: () =>
    apiClient.get<any>('/enrollments/summary').then(r => (r as any).data ?? r),

  enroll: (data: any) =>
    apiClient.post<any>('/enrollments', data),

  updateStatus: (id: string, status: string) =>
    apiClient.put<any>(`/enrollments/${id}/status`, { status }),

  updatePaymentStatus: (id: string, paymentStatus: string) =>
    apiClient.put<any>(`/enrollments/${id}/payment-status`, { payment_status: paymentStatus }),
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
