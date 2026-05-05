import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const accountingService = {
  getStats: (month: number, year: number) =>
    apiClient.get<any>(`/finance/stats?month=${month}&year=${year}`).then(r => (r as any).data ?? r),

  listTransactions: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/finance/transactions${qs}`).then(r => (r as any).data ?? r)
  },

  getTransaction: (id: string) =>
    apiClient.get<any>(`/finance/transactions/${id}`).then(r => (r as any).data ?? r),

  getJournal: (params?: { account?: string; source?: string; date_range?: string } & ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/finance/journal${qs}`).then(r => (r as any).data ?? r)
  },

  createTransaction: (data: any) =>
    apiClient.post<any>('/finance/transactions', data),

  updateTransaction: (id: string, data: any) =>
    apiClient.put<any>(`/finance/transactions/${id}`, data),

  deleteTransaction: (id: string) =>
    apiClient.delete(`/finance/transactions/${id}`),

  listCoa: () =>
    apiClient.get<any>('/finance/coa').then(r => (r as any).data ?? r),

  getCoaTree: () =>
    apiClient.get<any>('/finance/coa').then(r => (r as any).data ?? r),

  getBudgetVsActual: (month: number, year: number) =>
    apiClient.get<any>(`/finance/budget-vs-actual?month=${month}&year=${year}`).then(r => (r as any).data ?? r),

  listBankAccounts: (params?: { branch_id?: string; include_inactive?: boolean }) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/finance/bank-accounts${qs}`).then(r => (r as any).data ?? r)
  },

  getBankAccount: (id: string) =>
    apiClient.get<any>(`/finance/bank-accounts/${id}`).then(r => (r as any).data ?? r),

  createBankAccount: (data: any) =>
    apiClient.post<any>('/finance/bank-accounts', data),

  updateBankAccount: (id: string, data: any) =>
    apiClient.put<any>(`/finance/bank-accounts/${id}`, data),

  deleteBankAccount: (id: string) =>
    apiClient.delete(`/finance/bank-accounts/${id}`),

  listInvoices: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/finance/invoices${qs}`).then(r => (r as any).data ?? r)
  },

  updateInvoiceStatus: (id: string, status: string) =>
    apiClient.put<any>(`/finance/invoices/${id}/status`, { status }),
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
