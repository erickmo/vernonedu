import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface Enrollment {
  id: string
  student_id: string
  batch_id: string
  status: 'pending' | 'confirmed' | 'dropped' | 'completed'
  payment_status: 'pending' | 'partial' | 'paid' | 'overdue'
  completion_percent: number
  enrolled_at: string
  voucher_code?: string
  voucher_discount?: number
  final_price: number
  certificate_id?: string
}

export interface Voucher {
  id: string
  code: string
  type: 'percent' | 'fixed'
  value: number
  max_uses: number
  used_count: number
  valid_from: string
  valid_until: string
  status: 'active' | 'expired' | 'exhausted'
}

export interface EnrollmentFilters {
  student_id?: string
  batch_id?: string
  status?: string
  payment_status?: string
  page?: number
  limit?: number
}

export interface VoucherFilters {
  status?: string
  page?: number
  limit?: number
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
}

// ── Enrollment hooks ───────────────────────────────────────────────────────

export function useEnrollments(filters: EnrollmentFilters = {}) {
  return useQuery({
    queryKey: ['enrollments', filters],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Enrollment>>('/enrollments', { params: filters }).then((r) => r.data),
  })
}

export function useEnrollment(id: string) {
  return useQuery({
    queryKey: ['enrollments', id],
    queryFn: () => apiClient.get<Enrollment>(`/enrollments/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreateEnrollment() {
  const qc = useQueryClient()
  return useMutation({
    // Backend (api/internal/delivery/http/enrollment_handler.go) requires
    // student_id + course_batch_id. Extra fields (enrollment_date,
    // payment_method, voucher_code) are accepted by the form for invoice
    // automation; the API ignores unknown fields.
    mutationFn: (payload: {
      student_id: string
      course_batch_id: string
      enrollment_date?: string
      payment_method?: string
      voucher_code?: string
    }) =>
      apiClient
        .post<{ id?: string; data?: Enrollment } | Enrollment>('/enrollments', payload)
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['enrollments'] }),
  })
}

export function useUpdateEnrollmentStatus() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) =>
      apiClient.put(`/enrollments/${id}/status`, { status }).then((r) => r.data),
    onSuccess: (_d, vars) => {
      qc.invalidateQueries({ queryKey: ['enrollments', vars.id] })
      qc.invalidateQueries({ queryKey: ['enrollments'] })
    },
  })
}

export function useUpdateEnrollmentPaymentStatus() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, payment_status }: { id: string; payment_status: string }) =>
      apiClient.put(`/enrollments/${id}/payment-status`, { payment_status }).then((r) => r.data),
    onSuccess: (_d, vars) => {
      qc.invalidateQueries({ queryKey: ['enrollments', vars.id] })
      qc.invalidateQueries({ queryKey: ['enrollments'] })
    },
  })
}

// ── Student App Access ────────────────────────────────────────────────────
// Backend endpoints planned but not yet implemented. Shape:
// POST /api/v1/enrollments/{id}/access/grant
// POST /api/v1/enrollments/{id}/access/revoke

export function useGrantAppAccess() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/enrollments/${id}/access/grant`).then((r) => r.data),
    onSuccess: (_d, id) => {
      qc.invalidateQueries({ queryKey: ['enrollments', id] })
    },
  })
}

export function useRevokeAppAccess() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/enrollments/${id}/access/revoke`).then((r) => r.data),
    onSuccess: (_d, id) => {
      qc.invalidateQueries({ queryKey: ['enrollments', id] })
    },
  })
}

export function useUpdateEnrollmentCompletion() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, completion_percent }: { id: string; completion_percent: number }) =>
      apiClient.patch<Enrollment>(`/enrollments/${id}/completion`, { completion_percent }).then((r) => r.data),
    onSuccess: (_data, vars) => {
      qc.invalidateQueries({ queryKey: ['enrollments', vars.id] })
      qc.invalidateQueries({ queryKey: ['enrollments'] })
    },
  })
}

// ── Voucher hooks ──────────────────────────────────────────────────────────

export function useVouchers(filters: VoucherFilters = {}) {
  return useQuery({
    queryKey: ['vouchers', filters],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Voucher>>('/vouchers', { params: filters }).then((r) => r.data),
  })
}

export function useValidateVoucher() {
  return useMutation({
    mutationFn: ({ code, batch_id }: { code: string; batch_id: string }) =>
      apiClient
        .post<{ valid: boolean; discount_amount: number; voucher: Voucher }>('/vouchers/validate', {
          code,
          batch_id,
        })
        .then((r) => r.data),
  })
}

export function useCreateVoucher() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<Voucher, 'id' | 'used_count' | 'status'>) =>
      apiClient.post<Voucher>('/vouchers', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['vouchers'] }),
  })
}
