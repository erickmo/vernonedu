import { apiClient } from './api.client'
import type { PaginatedResponse } from '@/types/api.types'

export type SortTuple = [string, 1 | -1]
export type FilterTuple = [string, string, unknown]

export interface ListParams {
  limit?: number
  offset?: number
  sort?: SortTuple[]
  filters?: FilterTuple[]
  groupby?: string[]
  search?: string
  [key: string]: unknown
}

/**
 * Build URL query string from ListParams.
 * Arrays (sort, filters) are JSON-stringified.
 * Zero values (limit=0, offset=0) are included.
 */
export function buildQueryString(params?: ListParams | Record<string, unknown>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') {
      q.set(k, Array.isArray(v) ? JSON.stringify(v) : String(v))
    }
  })
  const str = q.toString()
  return str ? `?${str}` : ''
}

/**
 * Extract PaginatedResponse from Go API list response.
 * API shape: { data: T[], total: number, offset: number, limit: number }
 */
export function extractPaginated<T>(
  raw: unknown,
  fallback: T[] = [],
): PaginatedResponse<T> {
  const r = raw as Record<string, unknown>
  const items = Array.isArray(r?.data) ? (r.data as T[]) : fallback
  return {
    items,
    total: (r?.total as number) ?? items.length,
    limit: (r?.limit as number) ?? 9999,
    offset: (r?.offset as number) ?? 0,
  }
}

export function createEntityService<T, TApi = T>(
  basePath: string,
  transform?: (raw: TApi) => T,
) {
  return {
    list: async (params?: ListParams): Promise<PaginatedResponse<T>> => {
      const raw = await apiClient.get<unknown>(`${basePath}${buildQueryString(params)}`)
      const result = extractPaginated<TApi>(raw)
      return {
        ...result,
        items: transform ? result.items.map(transform) : (result.items as unknown as T[]),
      }
    },

    getById: async (id: string): Promise<T> => {
      const raw = await apiClient.get<Record<string, unknown>>(`${basePath}/${id}`)
      const item = (raw?.data ?? raw) as TApi
      return transform ? transform(item) : (item as unknown as T)
    },

    create: (data: Partial<T>): Promise<T> =>
      apiClient.post<T>(basePath, data),

    update: (id: string, data: Partial<T>): Promise<T> =>
      apiClient.put<T>(`${basePath}/${id}`, data),

    delete: (id: string): Promise<void> =>
      apiClient.delete<void>(`${basePath}/${id}`),
  }
}
