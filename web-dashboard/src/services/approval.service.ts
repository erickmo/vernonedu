import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export interface Approval {
  id: string
  type: string
  subject: string
  description?: string
  status: 'pending' | 'approved' | 'rejected' | 'cancelled'
  requester_id: string
  requester_name?: string
  approver_id?: string
  created_at?: number
  updated_at?: number
  [key: string]: unknown
}

export const approvalService = {
  list: (params?: ListParams): Promise<PaginatedResponse<Approval>> =>
    apiClient.get<unknown>(`/approvals${buildQueryString({ ...params, status: 'pending' })}`).then(r => extractPaginated<Approval>(r)),

  approve: (id: string, note?: string) =>
    apiClient.put<any>(`/approvals/${id}/approve`, { note }),

  reject: (id: string, note?: string) =>
    apiClient.put<any>(`/approvals/${id}/reject`, { note }),

  cancel: (id: string) =>
    apiClient.put<any>(`/approvals/${id}/cancel`, {}),
}
