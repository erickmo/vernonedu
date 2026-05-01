import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

export interface NotificationTemplate {
  id: string
  key: string
  channel: 'email' | 'in_app' | 'push'
  subject?: string
  body: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export function useNotificationTemplates() {
  return useQuery({
    queryKey: ['notification-templates'],
    queryFn: () =>
      apiClient.get<NotificationTemplate[]>('/notification-templates').then((r) => r.data),
  })
}

export function useCreateNotificationTemplate() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: {
      key: string
      channel: NotificationTemplate['channel']
      subject?: string
      body: string
    }) =>
      apiClient
        .post<NotificationTemplate>('/notification-templates', input)
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notification-templates'] }),
  })
}

export function useUpdateNotificationTemplate() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, ...input }: { id: string; subject?: string; body: string; is_active?: boolean }) =>
      apiClient
        .put<NotificationTemplate>(`/notification-templates/${id}`, input)
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notification-templates'] }),
  })
}

export function useDeleteNotificationTemplate() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`/notification-templates/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notification-templates'] }),
  })
}
