import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Partner Types ──────────────────────────────────────────────────────────

export interface Partner {
  id: string
  name: string
  type: 'university' | 'vendor' | 'sponsor' | 'franchise_candidate' | 'community' | 'other'
  status: 'lead' | 'active' | 'inactive'
  contact_name?: string
  contact_email?: string
  contact_phone?: string
  address?: string
  notes?: string
  created_at: string
  updated_at: string
}

export interface PartnershipAgreement {
  id: string
  partner_id: string
  status: 'draft' | 'active' | 'expired' | 'terminated'
  created_at: string
  updated_at: string
}

// ── Partner Hooks ──────────────────────────────────────────────────────────

export function usePartners() {
  return useQuery({
    queryKey: ['partners'],
    queryFn: () => apiClient.get<Partner[]>('/partners').then((r) => r.data),
  })
}

export function usePartner(id: string) {
  return useQuery({
    queryKey: ['partner', id],
    queryFn: () => apiClient.get<Partner>(`/partners/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreatePartner() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: {
      name: string
      type: Partner['type']
      contact_name?: string
      contact_email?: string
      contact_phone?: string
      notes?: string
    }) => apiClient.post<Partner>('/partners', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['partners'] }),
  })
}

export function useCreateAgreement() {
  return useMutation({
    mutationFn: (input: { partner_id: string }) =>
      apiClient.post<PartnershipAgreement>('/agreements', input).then((r) => r.data),
  })
}

export function useActivateAgreement() {
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/agreements/${id}/activate`).then((r) => r.data),
  })
}

// ── Voucher Types ──────────────────────────────────────────────────────────

export interface Voucher {
  id: string
  code: string
  discount_type: 'fixed_amount' | 'percentage' | 'fixed_final_price'
  discount_value: string
  assigned_to?: string
  course_id?: string
  course_batch_id?: string
  valid_from: string
  valid_until?: string
  max_uses?: number
  used_count: number
  is_active: boolean
  created_by: string
  created_at: string
  updated_at: string
}

// ── Voucher Hooks ──────────────────────────────────────────────────────────

export function useVouchers() {
  return useQuery({
    queryKey: ['vouchers'],
    queryFn: () => apiClient.get<Voucher[]>('/vouchers').then((r) => r.data),
  })
}

export function useCreateVoucher() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: {
      code: string
      discount_type: Voucher['discount_type']
      discount_value: string
      valid_from: string
      valid_until?: string
      max_uses?: number
    }) => apiClient.post<Voucher>('/vouchers', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['vouchers'] }),
  })
}

// ── Calendar Types ─────────────────────────────────────────────────────────

export interface CalendarEvent {
  id: string
  title: string
  description?: string
  event_type:
    | 'class_session'
    | 'staff_meeting'
    | 'admin_deadline'
    | 'payment_due'
    | 'facilitator_schedule'
    | 'partner_meeting'
  start_at: string
  end_at: string
  is_all_day: boolean
  location?: string
  agenda?: string
  created_by: string
  created_at: string
}

// ── Calendar Hooks ─────────────────────────────────────────────────────────

export function useCalendarEvents() {
  return useQuery({
    queryKey: ['calendar-events'],
    queryFn: () => apiClient.get<CalendarEvent[]>('/calendar').then((r) => r.data),
  })
}

export function useCreateCalendarEvent() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: {
      title: string
      event_type: CalendarEvent['event_type']
      start_at: string
      end_at: string
      is_all_day: boolean
      description?: string
      location?: string
    }) => apiClient.post<CalendarEvent>('/calendar', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['calendar-events'] }),
  })
}

export function useDeleteCalendarEvent() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => apiClient.delete(`/calendar/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['calendar-events'] }),
  })
}
