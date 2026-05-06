import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export interface Franchisee {
  id: string
  name: string
  branch_name: string
  location: string
  contact: string
  status: 'active' | 'inactive' | 'terminated'
  created_at: string
  updated_at?: string
  [key: string]: unknown
}

export interface FranchiseAgreement {
  id: string
  franchisee_id: string
  buy_in_fee: number
  monthly_royalty: number
  revenue_royalty_pct: number
  start_date: string
  end_date?: string
  status: string
  created_at: string
  [key: string]: unknown
}

export interface RoyaltyPayment {
  id: string
  franchisee_id: string
  period: string
  gross_revenue: number
  monthly_royalty: number
  revenue_royalty: number
  total_royalty: number
  status: 'unpaid' | 'overdue' | 'paid'
  paid_at?: string
  created_at: string
  [key: string]: unknown
}

export interface OtherRevenue {
  id: string
  franchisee_id: string
  label: string
  amount: number
  revenue_date: string
  created_at: string
  [key: string]: unknown
}

export interface CreateFranchiseePayload {
  name: string
  branch_name: string
  location: string
  contact: string
  status: string
}

export interface CreateAgreementPayload {
  buy_in_fee: number
  monthly_royalty: number
  revenue_royalty_pct: number
  start_date: string
  end_date?: string
  status?: string
}

export interface CreateRoyaltyPaymentPayload {
  period: string
  gross_revenue: number
}

export interface CreateOtherRevenuePayload {
  label: string
  amount: number
  revenue_date: string
}

export const franchiseeService = {
  list: (params?: ListParams): Promise<PaginatedResponse<Franchisee>> =>
    apiClient.get<unknown>(`/franchisees${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (id: string): Promise<Franchisee> =>
    apiClient.get<{ data: Franchisee }>(`/franchisees/${id}`).then((r) => r?.data ?? r),

  create: (data: CreateFranchiseePayload): Promise<{ data: Franchisee }> =>
    apiClient.post<{ data: Franchisee }>('/franchisees', data),

  update: (id: string, data: CreateFranchiseePayload): Promise<{ data: Franchisee }> =>
    apiClient.put<{ data: Franchisee }>(`/franchisees/${id}`, data),

  delete: (id: string): Promise<void> =>
    apiClient.delete<void>(`/franchisees/${id}`),

  // Agreement endpoints
  getAgreement: (franchiseeId: string): Promise<FranchiseAgreement> =>
    apiClient.get<{ data: FranchiseAgreement }>(`/franchisees/${franchiseeId}/agreement`).then((r) => r?.data ?? r),

  createAgreement: (franchiseeId: string, data: CreateAgreementPayload): Promise<{ data: FranchiseAgreement }> =>
    apiClient.post<{ data: FranchiseAgreement }>(`/franchisees/${franchiseeId}/agreement`, data),

  updateAgreement: (franchiseeId: string, agreementId: string, data: CreateAgreementPayload): Promise<{ data: FranchiseAgreement }> =>
    apiClient.put<{ data: FranchiseAgreement }>(`/franchisees/${franchiseeId}/agreement/${agreementId}`, data),

  // Royalty payment endpoints
  listRoyaltyPayments: (franchiseeId: string, params?: ListParams): Promise<PaginatedResponse<RoyaltyPayment>> =>
    apiClient.get<unknown>(`/franchisees/${franchiseeId}/royalty-payments${buildQueryString(params)}`).then(r => extractPaginated(r)),

  createRoyaltyPayment: (franchiseeId: string, data: CreateRoyaltyPaymentPayload): Promise<{ data: RoyaltyPayment }> =>
    apiClient.post<{ data: RoyaltyPayment }>(`/franchisees/${franchiseeId}/royalty-payments`, data),

  markRoyaltyPaid: (franchiseeId: string, paymentId: string): Promise<void> =>
    apiClient.put<void>(`/franchisees/${franchiseeId}/royalty-payments/${paymentId}/mark-paid`, {}),

  // Other revenue endpoints
  listOtherRevenue: (franchiseeId: string, params?: ListParams): Promise<PaginatedResponse<OtherRevenue>> =>
    apiClient.get<unknown>(`/franchisees/${franchiseeId}/other-revenue${buildQueryString(params)}`).then(r => extractPaginated(r)),

  createOtherRevenue: (franchiseeId: string, data: CreateOtherRevenuePayload): Promise<{ data: OtherRevenue }> =>
    apiClient.post<{ data: OtherRevenue }>(`/franchisees/${franchiseeId}/other-revenue`, data),

  updateOtherRevenue: (franchiseeId: string, revenueId: string, data: CreateOtherRevenuePayload): Promise<{ data: OtherRevenue }> =>
    apiClient.put<{ data: OtherRevenue }>(`/franchisees/${franchiseeId}/other-revenue/${revenueId}`, data),

  deleteOtherRevenue: (franchiseeId: string, revenueId: string): Promise<void> =>
    apiClient.delete<void>(`/franchisees/${franchiseeId}/other-revenue/${revenueId}`),
}
