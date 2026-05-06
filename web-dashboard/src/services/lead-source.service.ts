import { apiClient } from './api.client'
import { buildQueryString } from './createEntityService'
import type { ListParams, PaginatedResponse } from './createEntityService'

export interface LeadSource {
  id: string
  name: string
  is_active: boolean
}

export const leadSourceService = {
  list: (params?: ListParams): Promise<PaginatedResponse<LeadSource>> =>
    apiClient.get<any>(`/settings/lead-sources${buildQueryString(params)}`).then((r: any) => {
      const items: LeadSource[] = Array.isArray(r) ? r : (r?.data ?? [])
      return { items, total: items.length, limit: 9999, offset: 0 }
    }),

  create: (data: { name: string }) =>
    apiClient.post('settings/lead-sources', data),

  update: (id: string, data: { name: string; is_active: boolean }) =>
    apiClient.put(`settings/lead-sources/${id}`, data),

  delete: (id: string) =>
    apiClient.delete(`settings/lead-sources/${id}`),
}
