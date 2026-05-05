import { apiClient } from './api.client'

export const financeReportsService = {
  getBalanceSheet: (params: { period: string; branch_id?: string; from_date?: string; to_date?: string }) =>
    apiClient.get<any>(`/finance/reports/balance-sheet${buildQS(params)}`).then(r => (r as any).data ?? r),

  getProfitLoss: (params: { period: string; branch_id?: string; from_date?: string; to_date?: string }) =>
    apiClient.get<any>(`/finance/reports/profit-loss${buildQS(params)}`).then(r => (r as any).data ?? r),

  getCashFlow: (params: { period: string; branch_id?: string; from_date?: string; to_date?: string }) =>
    apiClient.get<any>(`/finance/reports/cash-flow${buildQS(params)}`).then(r => (r as any).data ?? r),

  getLedger: (params: { period: string; account_id?: string; from_date?: string; to_date?: string }) =>
    apiClient.get<any>(`/finance/reports/ledger${buildQS(params)}`).then(r => (r as any).data ?? r),

  getTrialBalance: (params: { period: string; branch_id?: string; from_date?: string; to_date?: string }) =>
    apiClient.get<any>(`/finance/reports/trial-balance${buildQS(params)}`).then(r => (r as any).data ?? r),
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
