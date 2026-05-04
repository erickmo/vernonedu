import { apiClient } from './api.client'

export const courseModuleService = {
  update: (moduleId: string, data: any) =>
    apiClient.put<any>(`/curriculum/modules/${moduleId}`, data),

  delete: (moduleId: string) =>
    apiClient.delete(`/curriculum/modules/${moduleId}`),
}
