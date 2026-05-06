import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'
import type { MOU, MOUPayload, ExpiringMOU, Partner } from '@/types/partner.types'

function extractList<T>(r: unknown): T[] {
  const outer = (r as any)?.data ?? r
  return Array.isArray(outer) ? outer : (outer?.data ?? outer?.items ?? [])
}

export const partnerService = {
  list: (params?: ListParams): Promise<PaginatedResponse<Partner>> =>
    apiClient.get<unknown>(`partners${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string): Promise<Partner> =>
    apiClient.get<unknown>(`partners/${id}`).then((r) => ((r as Record<string, unknown>)?.data ?? r) as Partner),

  create: (data: Pick<Partner, 'name'> & Partial<Pick<Partner, 'address' | 'phone' | 'group_id' | 'is_active'>>) =>
    apiClient.post<unknown>('partners', data),

  update: (id: string, data: Partial<Partner>) =>
    apiClient.put<unknown>(`partners/${id}`, data),

  delete: (id: string) =>
    apiClient.delete<unknown>(`partners/${id}`),

  listMOUs: (partnerId: string): Promise<MOU[]> =>
    apiClient.get<unknown>(`partners/${partnerId}/mous`).then(extractList<MOU>),

  addMOU: (partnerId: string, data: MOUPayload): Promise<unknown> =>
    apiClient.post<unknown>(`partners/${partnerId}/mou`, data), // POST /mou singular — backend route is /mou not /mous

  updateMOU: (mouId: string, data: MOUPayload): Promise<unknown> =>
    apiClient.put<unknown>(`mous/${mouId}`, data),

  deleteMOU: (mouId: string): Promise<unknown> =>
    apiClient.delete<unknown>(`mous/${mouId}`),

  listExpiringMOUs: (withinMonths = 3): Promise<ExpiringMOU[]> =>
    apiClient.get<unknown>(`mous/expiring?within_months=${withinMonths}`).then(extractList<ExpiringMOU>),
}
