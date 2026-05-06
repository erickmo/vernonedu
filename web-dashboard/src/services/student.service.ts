import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const studentService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`students${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string) =>
    apiClient.get<any>(`students/${id}`).then((r: any) => r?.data ?? r),

  create: (data: any) =>
    apiClient.post<any>('students', data),

  update: (id: string, data: any) =>
    apiClient.put<any>(`students/${id}`, data),

  delete: (id: string) =>
    apiClient.delete(`students/${id}`),

  getEnrollmentHistory: (id: string) =>
    apiClient.get<any>(`students/${id}/enrollment-history`).then((r: any) => r?.data ?? r),

  getNotes: (id: string) =>
    apiClient.get<any>(`students/${id}/notes`).then((r: any) => r?.data ?? r),

  addNote: (id: string, data: any) =>
    apiClient.post<any>(`students/${id}/notes`, data),

  getCrmLogs: (id: string) =>
    apiClient.get<any>(`students/${id}/crm-logs`).then((r: any) => r?.data ?? r),

  addCrmLog: (id: string, data: any) =>
    apiClient.post<any>(`students/${id}/crm-logs`, data),

  getCertificates: (id: string) =>
    apiClient.get<any>(`students/${id}/certificates`).then((r: any) => r?.data ?? r),
}
