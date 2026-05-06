import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const courseService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/curriculum/courses${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string) =>
    apiClient.get<any>(`/curriculum/courses/${id}`).then((r: any) => r?.data ?? r),

  create: (data: any) =>
    apiClient.post<any>('/curriculum/courses', data),

  update: (id: string, data: any) =>
    apiClient.put<any>(`/curriculum/courses/${id}`, data),

  delete: (id: string) =>
    apiClient.delete<void>(`/curriculum/courses/${id}`),

  archive: (id: string) =>
    apiClient.post<any>(`/curriculum/courses/${id}/archive`, {}),
}
