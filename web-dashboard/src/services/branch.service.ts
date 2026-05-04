import { apiClient } from './api.client'

export const branchService = {
  list: () =>
    apiClient.get<any>('/branches').then(r => (r as any).data ?? r),
}
