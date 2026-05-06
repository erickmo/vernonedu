import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const talentPoolService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`talentpool${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string) =>
    apiClient.get<any>(`talentpool/${id}`).then((r: any) => r?.data ?? r),

  updateStatus: (id: string, status: string) =>
    apiClient.put<any>(`talentpool/${id}/status`, { status }),
}
