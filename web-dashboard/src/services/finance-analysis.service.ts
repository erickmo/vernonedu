import { apiClient } from './api.client'
import { buildQueryString } from './createEntityService'

export const financeAnalysisService = {
  getRatios: (params: { period: string; branch_id?: string; comparison?: string }) =>
    apiClient.get<any>(`/finance/analysis/ratios${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  getRevenue: (params: { period: string; branch_id?: string; group_by?: string }) =>
    apiClient.get<any>(`/finance/analysis/revenue${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  getCosts: (params: { period: string; branch_id?: string; group_by?: string }) =>
    apiClient.get<any>(`/finance/analysis/costs${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  getBatchProfit: (params: { period: string; branch_id?: string; sort?: string; limit?: number }) =>
    apiClient.get<any>(`/finance/analysis/batch-profit${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  getCashForecast: (params: { months: number; branch_id?: string }) =>
    apiClient.get<any>(`/finance/analysis/cash-forecast${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  getAlerts: () =>
    apiClient.get<any>('/finance/analysis/alerts').then((r: any) => r?.data ?? r),

  getSuggestions: () =>
    apiClient.get<any>('/finance/analysis/suggestions').then((r: any) => r?.data ?? r),
}
