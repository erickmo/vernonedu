import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const partnerService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`partners${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string) =>
    apiClient.get<any>(`partners/${id}`).then((r: any) => r?.data ?? r),

  create: (data: { name: string; address?: string; phone?: string; group_id?: string; is_active: boolean }) =>
    apiClient.post<any>('partners', data),

  update: (id: string, data: unknown) =>
    apiClient.put<any>(`partners/${id}`, data),

  addMOU: (id: string, data: any) =>
    apiClient.post<any>(`partners/${id}/mou`, data),

  delete: (id: string) =>
    apiClient.delete<any>(`partners/${id}`),
}
