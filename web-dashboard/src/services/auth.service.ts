import { apiClient } from './api.client'
import type { VernonEduLoginRequest, VernonEduLoginResponse, VernonEduUser } from '@/types/auth.types'

export const authService = {
  login: (body: VernonEduLoginRequest): Promise<VernonEduLoginResponse> =>
    apiClient.post<VernonEduLoginResponse>('/auth/login', body),

  me: (): Promise<{ data: VernonEduUser }> =>
    apiClient.get('/auth/me'),

  logout: (): Promise<void> =>
    apiClient.post<void>('/auth/logout', {}),
}
