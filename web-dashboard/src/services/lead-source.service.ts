import { apiClient } from './api.client'

export interface LeadSource {
  id: string
  name: string
  is_active: boolean
}

export const leadSourceService = {
  list: (): Promise<LeadSource[]> =>
    apiClient.get<any>('settings/lead-sources').then((r: any) => r?.data ?? r ?? []),

  create: (data: { name: string }) =>
    apiClient.post('settings/lead-sources', data),

  update: (id: string, data: { name: string; is_active: boolean }) =>
    apiClient.put(`settings/lead-sources/${id}`, data),

  delete: (id: string) =>
    apiClient.delete(`settings/lead-sources/${id}`),
}
