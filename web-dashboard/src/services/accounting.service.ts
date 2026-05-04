import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const accountingService = {
  getStats: (month: number, year: number) =>
    apiClient.get<any>(`/accounting/stats?month=${month}&year=${year}`).then(r => (r as any).data ?? r),

  listTransactions: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/accounting/transactions${qs}`).then(r => (r as any).data ?? r)
  },

  createTransaction: (data: any) =>
    apiClient.post<any>('/accounting/transactions', data),

  updateTransaction: (id: string, data: any) =>
    apiClient.put<any>(`/accounting/transactions/${id}`, data),

  deleteTransaction: (id: string) =>
    apiClient.delete(`/accounting/transactions/${id}`),

  listCoa: () =>
    apiClient.get<any>('/accounting/coa').then(r => (r as any).data ?? r),

  getCoaTree: () =>
    apiClient.get<any>('/accounting/coa/tree').then(r => (r as any).data ?? r),

  getBudgetVsActual: (month: number, year: number) =>
    apiClient.get<any>(`/accounting/budget-vs-actual?month=${month}&year=${year}`).then(r => (r as any).data ?? r),

  listBankAccounts: (params?: { branch_id?: string; include_inactive?: boolean }) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/accounting/bank-accounts${qs}`).then(r => (r as any).data ?? r)
  },

  getBankAccount: (id: string) =>
    apiClient.get<any>(`/accounting/bank-accounts/${id}`).then(r => (r as any).data ?? r),

  createBankAccount: (data: any) =>
    apiClient.post<any>('/accounting/bank-accounts', data),

  updateBankAccount: (id: string, data: any) =>
    apiClient.put<any>(`/accounting/bank-accounts/${id}`, data),

  deleteBankAccount: (id: string) =>
    apiClient.delete(`/accounting/bank-accounts/${id}`),

  listInvoices: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/accounting/invoices${qs}`).then(r => (r as any).data ?? r)
  },

  updateInvoiceStatus: (id: string, status: string) =>
    apiClient.put<any>(`/accounting/invoices/${id}/status`, { status }),
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
