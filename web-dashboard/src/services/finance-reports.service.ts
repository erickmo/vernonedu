import { apiClient } from './api.client'
import { buildQueryString } from './createEntityService'

export const financeReportsService = {
  getBalanceSheet: (params: { period: string; branch_id?: string; from_date?: string; to_date?: string }) =>
    apiClient.get<any>(`/finance/reports/balance-sheet${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  getProfitLoss: (params: { period: string; branch_id?: string; from_date?: string; to_date?: string }) =>
    apiClient.get<any>(`/finance/reports/profit-loss${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  getCashFlow: (params: { period: string; branch_id?: string; from_date?: string; to_date?: string }) =>
    apiClient.get<any>(`/finance/reports/cash-flow${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  getLedger: (params: { period: string; account_id?: string; from_date?: string; to_date?: string }) =>
    apiClient.get<any>(`/finance/reports/ledger${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  getTrialBalance: (params: { period: string; branch_id?: string; from_date?: string; to_date?: string }) =>
    apiClient.get<any>(`/finance/reports/trial-balance${buildQueryString(params)}`).then((r: any) => r?.data ?? r),
}
