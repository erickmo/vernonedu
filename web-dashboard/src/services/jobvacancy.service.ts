import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const jobVacancyService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`talentpool/vacancies${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string) =>
    apiClient.get<any>(`talentpool/vacancies/${id}`).then((r: any) => r?.data ?? r),

  create: (data: Record<string, unknown>) =>
    apiClient.post<any>('talentpool/vacancies', data),

  update: (id: string, data: Record<string, unknown>) =>
    apiClient.put<any>(`talentpool/vacancies/${id}`, data),

  changeStatus: (id: string, status: string) =>
    apiClient.patch<any>(`talentpool/vacancies/${id}/status`, { status }),

  delete: (id: string) =>
    apiClient.delete(`talentpool/vacancies/${id}`),
}
