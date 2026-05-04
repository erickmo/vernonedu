import { apiClient } from './api.client'
import type { PaginatedResponse } from '@/types/api.types'

export interface User {
  id: string
  name: string
  email: string
  roles: string[]
}

const BASE = '/users'

export const userService = {
  list: async (params?: { offset?: number; limit?: number; role?: string }) => {
    const query = new URLSearchParams()
    if (params?.offset) query.set('offset', String(params.offset))
    if (params?.limit) query.set('limit', String(params.limit))
    if (params?.role) query.set('role', params.role)
    const qs = query.toString()
    const response = await apiClient.get<{
      data: {
        data: Omit<User, 'is_active' | 'created_at' | 'updated_at'>[]
        total: number
        offset: number
        limit: number
      }
    }>(
      `${BASE}${qs ? `?${qs}` : ''}`
    )
    return {
      data: response.data.data,
      total: response.data.total,
    }
  },

  get: async (id: string) => {
    return apiClient.get<User>(`${BASE}/${id}`)
  },

  create: async (data: Omit<User, 'id'>) => {
    return apiClient.post<User>(BASE, data)
  },

  update: async (id: string, data: Partial<User>) => {
    return apiClient.put<User>(`${BASE}/${id}`, data)
  },

  delete: async (id: string) => {
    return apiClient.delete(`${BASE}/${id}`)
  },
}
