import { apiClient } from './api.client'

export const courseVersionService = {
  getById: (versionId: string) =>
    apiClient.get<any>(`/curriculum/versions/${versionId}`).then(r => (r as any).data ?? r),

  promote: (versionId: string, targetStatus: string) =>
    apiClient.post<any>(`/curriculum/versions/${versionId}/promote`, { target_status: targetStatus }),

  approve: (versionId: string) =>
    apiClient.post<any>(`/curriculum/versions/${versionId}/approve`, {}),

  reject: (versionId: string, reason: string) =>
    apiClient.post<any>(`/curriculum/versions/${versionId}/reject`, { reason }),

  getPending: () =>
    apiClient.get<any>('/curriculum/versions/pending').then(r => (r as any).data ?? r),

  getModules: (versionId: string) =>
    apiClient.get<any>(`/curriculum/versions/${versionId}/modules`).then(r => (r as any).data ?? r),

  createModule: (versionId: string, data: any) =>
    apiClient.post<any>(`/curriculum/versions/${versionId}/modules`, data),

  getInternshipConfig: (versionId: string) =>
    apiClient.get<any>(`/curriculum/versions/${versionId}/internship`).then(r => (r as any).data ?? r),

  upsertInternshipConfig: (versionId: string, data: any) =>
    apiClient.put<any>(`/curriculum/versions/${versionId}/internship`, data),

  getCharacterTestConfig: (versionId: string) =>
    apiClient.get<any>(`/curriculum/versions/${versionId}/character-test`).then(r => (r as any).data ?? r),

  upsertCharacterTestConfig: (versionId: string, data: any) =>
    apiClient.put<any>(`/curriculum/versions/${versionId}/character-test`, data),
}
