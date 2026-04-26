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
    mutationFn: (payload: { student_id: string; batch_id: string; voucher_code?: string }) =>
      apiClient.post<Enrollment>('/enrollments', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['enrollments'] }),
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
