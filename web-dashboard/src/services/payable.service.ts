import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const payableService = {
  getStats: () =>
    apiClient.get<any>('/finance/payables/stats').then((r: any) => r?.data ?? r),

  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/finance/payables${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string) =>
    apiClient.get<any>(`/finance/payables/${id}`).then((r: any) => r?.data ?? r),

  markAsPaid: (id: string) =>
    apiClient.put<any>(`/finance/payables/${id}/pay`, {}),

  delete: (id: string) =>
    apiClient.delete<any>(`/finance/payables/${id}`),
}
