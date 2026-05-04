import { apiClient } from './api.client'

export const financeAnalysisService = {
  getRatios: (params: { period: string; branch_id?: string; comparison?: string }) =>
    apiClient.get<any>(`/finance/analysis/ratios${buildQS(params)}`).then(r => (r as any).data ?? r),

  getRevenue: (params: { period: string; branch_id?: string; group_by?: string }) =>
    apiClient.get<any>(`/finance/analysis/revenue${buildQS(params)}`).then(r => (r as any).data ?? r),

  getCosts: (params: { period: string; branch_id?: string; group_by?: string }) =>
    apiClient.get<any>(`/finance/analysis/costs${buildQS(params)}`).then(r => (r as any).data ?? r),

  getBatchProfit: (params: { period: string; branch_id?: string; sort?: string; limit?: number }) =>
    apiClient.get<any>(`/finance/analysis/batch-profit${buildQS(params)}`).then(r => (r as any).data ?? r),

  getCashForecast: (params: { months: number; branch_id?: string }) =>
    apiClient.get<any>(`/finance/analysis/cash-forecast${buildQS(params)}`).then(r => (r as any).data ?? r),

  getAlerts: () =>
    apiClient.get<any>('/finance/analysis/alerts').then(r => (r as any).data ?? r),

  getSuggestions: () =>
    apiClient.get<any>('/finance/analysis/suggestions').then(r => (r as any).data ?? r),
}

function buildQS(params?: Record<string, any>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') q.set(k, String(v))
  })
  const s = q.toString()
  return s ? `?${s}` : ''
}
