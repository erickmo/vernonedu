import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const enrollmentService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`enrollments${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string) =>
    apiClient.get<any>(`enrollments/${id}`).then((r: any) => r?.data ?? r),

  getSummary: () =>
    apiClient.get<any>('enrollments/summary').then((r: any) => r?.data ?? r),

  enroll: (data: { student_id: string; batch_id: string; payment_method: string }) =>
    apiClient.post<any>('enrollments', data),

  updateStatus: (id: string, status: string) =>
    apiClient.put<any>(`enrollments/${id}/status`, { status }),

  updatePaymentStatus: (id: string, paymentStatus: string) =>
    apiClient.put<any>(`enrollments/${id}/payment-status`, { payment_status: paymentStatus }),

  delete: (id: string) =>
    apiClient.delete<any>(`enrollments/${id}`),
}
