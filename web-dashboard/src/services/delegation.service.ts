import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const delegationService = {
  list: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/delegations${qs}`).then(r => (r as any).data ?? r)
  },
}

function buildQS(params?: Record<string, any>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') q.set(k, Array.isArray(v) ? JSON.stringify(v) : String(v))
  })
  const s = q.toString()
  return s ? `?${s}` : ''
}
