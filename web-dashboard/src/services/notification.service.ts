import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export interface Notification {
  id: string
  title: string
  body?: string
  type?: string
  is_read?: boolean
  created_at?: number
  [key: string]: unknown
}

export const notificationService = {
  list: (params?: ListParams): Promise<PaginatedResponse<Notification>> =>
    apiClient.get<unknown>(`/notifications${buildQueryString(params)}`).then(r => extractPaginated<Notification>(r)),

  markRead: (id: string) =>
    apiClient.put<any>(`/notifications/${id}/read`, {}),

  markAllRead: () =>
    apiClient.put<any>('/notifications/read-all', {}),
}
