import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const invoiceService = {
  getStats: () =>
    apiClient.get<any>('/finance/invoices/stats').then((r: any) => r?.data ?? r),

  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/finance/invoices${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getDetail: (id: string) =>
    apiClient.get<any>(`/finance/invoices/${id}`).then((r: any) => r?.data ?? r),

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
