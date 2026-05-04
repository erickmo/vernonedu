import { apiClient } from './api.client'
import type { LoginRequest, LoginResponse } from '@/types/auth.types'

export const authService = {
  login: (body: LoginRequest): Promise<LoginResponse> =>
    apiClient.post<LoginResponse>('/auth/login', body),

  logout: (): Promise<void> =>
    apiClient.post<void>('/auth/logout', {}),

  me: (): Promise<LoginResponse['user']> =>
    apiClient.get('/auth/me'),
}
