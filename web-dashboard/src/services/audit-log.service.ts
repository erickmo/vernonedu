import { apiClient } from '@/services/api.client'
import type { AuditLog, AuditLogFilters } from '@/types/audit-log.types'

// ─── Paginated response (inline — not yet in api.types) ───────────────────────

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

// ─── Service ──────────────────────────────────────────────────────────────────

export const auditLogService = {
  list: (filters: AuditLogFilters) => {
    const params = new URLSearchParams()
    Object.entries(filters).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') params.set(k, String(v))
    })
    const qs = params.toString()
    return apiClient.get<PaginatedResponse<AuditLog>>(`/api/audit-logs${qs ? `?${qs}` : ''}`)
  },
}
