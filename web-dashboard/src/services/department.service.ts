import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const departmentService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/departments${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string) =>
    apiClient.get<any>(`/departments/${id}`).then((r: any) => r?.data ?? r),

  create: (data: any) =>
    apiClient.post<any>('/departments', data),

  update: (id: string, data: any) =>
    apiClient.put<any>(`/departments/${id}`, data),

  delete: (id: string) =>
    apiClient.delete<void>(`/departments/${id}`),

  assignLeader: (id: string, leaderId: string) =>
    apiClient.put(`/departments/${id}/leader`, { leader_id: leaderId }),

  getSummaries: () =>
    apiClient.get<any>('/departments/summaries').then((r: any) => r?.data ?? r),

  getBatches: (id: string) =>
    apiClient.get<any>(`/departments/${id}/batches`).then((r: any) => {
      const d = r?.data ?? r
      return Array.isArray(d) ? d : d?.items ?? []
    }),

  getCourses: (id: string) =>
    apiClient.get<any>(`/departments/${id}/courses`).then((r: any) => {
      const d = r?.data ?? r
      return Array.isArray(d) ? d : d?.items ?? []
    }),

  getStudents: (id: string, params?: ListParams) =>
    apiClient.get<any>(`/departments/${id}/students${buildQueryString(params)}`).then((r: any) => {
      const d = r?.data ?? r
      return Array.isArray(d) ? d : d?.items ?? []
    }),

  getTalentPool: (id: string) =>
    apiClient.get<any>(`/departments/${id}/talentpool`).then((r: any) => {
      const d = r?.data ?? r
      return Array.isArray(d) ? d : d?.items ?? []
    }),
}
