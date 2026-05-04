import { apiClient } from './api.client'
import type { PaginatedResponse } from '@/types/api.types'

export interface CourseModule {
  id: string
  version_id: string
  title: string
  description: string
  tools: string[]
  requirements: string[]
  order: number
}

export const courseModuleService = {
  list: async (versionId: string, _params?: any): Promise<PaginatedResponse<CourseModule>> => {
    const r = await apiClient.get<any>(`/curriculum/versions/${versionId}/modules`)
    const raw = (r as any).data ?? r
    const items: CourseModule[] = Array.isArray(raw) ? raw : (raw.items ?? [])
    return { items, total: items.length, offset: 0, limit: 9999 }
  },

  create: (versionId: string, data: any) =>
    apiClient.post<any>(`/curriculum/versions/${versionId}/modules`, data),

  update: (moduleId: string, data: any) =>
    apiClient.put<any>(`/curriculum/modules/${moduleId}`, data),

  delete: (moduleId: string) =>
    apiClient.delete(`/curriculum/modules/${moduleId}`),
}
