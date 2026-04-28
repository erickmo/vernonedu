import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface Franchisee {
  id: string
  name: string
  branch_name: string
  location: string
  contact: string
  status: 'active' | 'inactive' | 'terminated'
  created_by: string
  user_id?: string
  created_at: string
  updated_at: string
}

export interface FranchiseAgreement {
  id: string
  franchisee_id: string
  buy_in_fee: number
  monthly_royalty: number
  revenue_royalty_pct: number
  start_date: string
  end_date?: string
  status: 'active' | 'inactive' | 'terminated'
  created_at: string
  updated_at: string
}

export interface RoyaltyRecord {
  id: string
  franchise_agreement_id: string
  period: string
  gross_revenue: number
  monthly_royalty: number
  revenue_royalty: number
  total_royalty: number
  status: 'unpaid' | 'overdue' | 'paid'
  created_at: string
  paid_at?: string
  recorded_by: string
}

// ── Hooks ──────────────────────────────────────────────────────────────────

export function useMyFranchisee() {
  return useQuery({
    queryKey: ['franchisee', 'me'],
    queryFn: () => apiClient.get<Franchisee>('/me/franchisee').then((r) => r.data),
  })
}

export function useFranchisee(id: string) {
  return useQuery({
    queryKey: ['franchisee', id],
    queryFn: () => apiClient.get<Franchisee>(`/franchisees/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useAgreement(franchiseeId: string) {
  return useQuery({
    queryKey: ['franchise-agreement', franchiseeId],
    queryFn: () =>
      apiClient
        .get<FranchiseAgreement>(`/franchise-agreements/${franchiseeId}`)
        .then((r) => r.data),
    enabled: !!franchiseeId,
  })
}

export function useRoyaltyRecords(franchiseeId: string) {
  return useQuery({
    queryKey: ['royalty-records', franchiseeId],
    queryFn: () =>
      apiClient
        .get<RoyaltyRecord[]>(`/royalty-records/${franchiseeId}/all`)
        .then((r) => r.data),
    enabled: !!franchiseeId,
  })
}

export function useMarkRoyaltyPaid() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/royalty-records/${id}/mark-paid`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['royalty-records'] }),
  })
}
