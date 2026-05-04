import { apiClient } from './api.client'

export const notificationService = {
  list: () =>
    apiClient.get<any>('/notifications').then(r => (r as any).data ?? r),

  markRead: (id: string) =>
    apiClient.put<any>(`/notifications/${id}/read`, {}),

  markAllRead: () =>
    apiClient.put<any>('/notifications/read-all', {}),
}
