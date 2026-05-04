import { apiClient } from './api.client'

export const okrService = {
  list: (level?: string) => {
    const qs = level ? `?level=${level}` : ''
    return apiClient.get<any>(`/okr${qs}`).then(r => (r as any).data ?? r)
  },
}
