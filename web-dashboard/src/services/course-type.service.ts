import { apiClient } from './api.client'

export const courseTypeService = {
  getById: (typeId: string) =>
    apiClient.get<any>(`/curriculum/types/${typeId}`).then(r => (r as any).data ?? r),

  update: (typeId: string, data: any) =>
    apiClient.put<any>(`/curriculum/types/${typeId}`, data),

  toggle: (typeId: string) =>
    apiClient.post<any>(`/curriculum/types/${typeId}/toggle`, {}),

  getVersions: (typeId: string) =>
    apiClient.get<any>(`/curriculum/types/${typeId}/versions`).then(r => (r as any).data ?? r),

  createVersion: (typeId: string, data: any) =>
    apiClient.post<any>(`/curriculum/types/${typeId}/versions`, data),
}
