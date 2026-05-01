import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface Partner {
  id: string
  name: string
  type: 'corporate' | 'government' | 'ngo' | 'university'
  contact_name: string
  contact_email: string
  contact_phone: string
  status: 'active' | 'inactive' | 'prospect'
  created_at: string
}

export interface PartnershipAgreement {
  id: string
  partner_id: string
  title: string
  start_date: string
  end_date?: string
  terms: string
  revenue_share_percent: number
  status: 'draft' | 'active' | 'expired' | 'terminated'
  signed_at?: string
}

export interface Franchise {
  id: string
  partner_id: string
  code: string
  region: string
  royalty_percent: number
  status: 'active' | 'inactive'
  activated_at: string
}

export interface PartnerFilters {
  type?: string
  status?: string
  search?: string
  page?: number
  limit?: number
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
}

// ── Partner hooks ──────────────────────────────────────────────────────────

export function usePartners(filters: PartnerFilters = {}) {
  return useQuery({
    queryKey: ['partners', filters],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Partner>>('/partners', { params: filters }).then((r) => r.data),
  })
}

export function usePartner(id: string) {
  return useQuery({
    queryKey: ['partners', id],
    queryFn: () => apiClient.get<Partner>(`/partners/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreatePartner() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<Partner, 'id' | 'created_at'>) =>
      apiClient.post<Partner>('/partners', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['partners'] }),
  })
}

export function useUpdatePartner() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, ...payload }: Partial<Partner> & { id: string }) =>
      apiClient.patch<Partner>(`/partners/${id}`, payload).then((r) => r.data),
    onSuccess: (_data, vars) => {
      qc.invalidateQueries({ queryKey: ['partners', vars.id] })
      qc.invalidateQueries({ queryKey: ['partners'] })
    },
  })
}

// ── Partnership agreement hooks ────────────────────────────────────────────

export function usePartnershipAgreements(partnerId: string) {
  return useQuery({
    queryKey: ['partnership-agreements', { partnerId }],
    queryFn: () =>
      apiClient.get<PartnershipAgreement[]>(`/partners/${partnerId}/agreements`).then((r) => r.data),
    enabled: !!partnerId,
  })
}

export function useCreatePartnershipAgreement() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<PartnershipAgreement, 'id' | 'signed_at'>) =>
      apiClient.post<PartnershipAgreement>('/partnership-agreements', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['partnership-agreements'] }),
  })
}

// ── Franchise hooks ────────────────────────────────────────────────────────

export function useFranchises() {
  return useQuery({
    queryKey: ['franchises'],
    queryFn: () => apiClient.get<Franchise[]>('/franchises').then((r) => r.data),
  })
}

export function useFranchise(id: string) {
  return useQuery({
    queryKey: ['franchises', id],
    queryFn: () => apiClient.get<Franchise>(`/franchises/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}
