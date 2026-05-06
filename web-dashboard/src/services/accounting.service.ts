import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const accountingService = {
  getStats: (month: number, year: number) =>
    apiClient.get<any>(`/finance/stats?month=${month}&year=${year}`).then((r: any) => r?.data ?? r),

  listTransactions: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/finance/transactions${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getTransaction: (id: string) =>
    apiClient.get<any>(`/finance/transactions/${id}`).then((r: any) => r?.data ?? r),

  getJournal: (params?: { account?: string; source?: string; date_range?: string } & ListParams) =>
    apiClient.get<any>(`/finance/journal${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  createTransaction: (data: any) =>
    apiClient.post<any>('/finance/transactions', data),

  updateTransaction: (id: string, data: any) =>
    apiClient.put<any>(`/finance/transactions/${id}`, data),

  deleteTransaction: (id: string) =>
    apiClient.delete(`/finance/transactions/${id}`),

  listCoa: () =>
    apiClient.get<any>('/finance/coa').then((r: any) => r?.data ?? r),

  getCoaTree: () =>
    apiClient.get<any>('/finance/coa').then((r: any) => r?.data ?? r),

  getBudgetVsActual: (month: number, year: number) =>
    apiClient.get<any>(`/finance/budget-vs-actual?month=${month}&year=${year}`).then((r: any) => r?.data ?? r),

  listBankAccounts: (params?: { branch_id?: string; include_inactive?: boolean }) =>
    apiClient.get<any>(`/finance/bank-accounts${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  getBankAccount: (id: string) =>
    apiClient.get<any>(`/finance/bank-accounts/${id}`).then((r: any) => r?.data ?? r),

  createBankAccount: (data: any) =>
    apiClient.post<any>('/finance/bank-accounts', data),

  updateBankAccount: (id: string, data: any) =>
    apiClient.put<any>(`/finance/bank-accounts/${id}`, data),

  deleteBankAccount: (id: string) =>
    apiClient.delete(`/finance/bank-accounts/${id}`),

  listInvoices: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/finance/invoices${buildQueryString(params)}`).then(r => extractPaginated(r)),

  updateInvoiceStatus: (id: string, status: string) =>
    apiClient.put<any>(`/finance/invoices/${id}/status`, { status }),
}
