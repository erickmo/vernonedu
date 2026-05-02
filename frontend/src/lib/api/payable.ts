import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  Payable,
  PayableListFilters,
  PayableListResponse,
  CreatePayablePayload,
  PayPayablePayload,
} from '@/types/payable'

const PAYABLE_BASE = '/finance/payables'
const QK_PAYABLE = ['finance', 'payables'] as const

export function usePayables(filters: PayableListFilters = {}) {
  return useQuery({
    queryKey: [...QK_PAYABLE, 'list', filters],
    queryFn: () =>
      apiClient
        .get<PayableListResponse>(PAYABLE_BASE, { params: filters })
        .then((r) => r.data),
  })
}

export function usePayable(id: string) {
  return useQuery({
    queryKey: [...QK_PAYABLE, 'detail', id],
    queryFn: () =>
      apiClient.get<Payable>(`${PAYABLE_BASE}/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreatePayable() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: CreatePayablePayload) =>
      apiClient.post(PAYABLE_BASE, payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: QK_PAYABLE }),
  })
}

export function useApprovePayable() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.put(`${PAYABLE_BASE}/${id}/approve`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: QK_PAYABLE }),
  })
}

export function usePayPayable() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload?: PayPayablePayload }) =>
      apiClient
        .put(`${PAYABLE_BASE}/${id}/pay`, payload ?? {})
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: QK_PAYABLE }),
  })
}

export function useCancelPayable() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.put(`${PAYABLE_BASE}/${id}/cancel`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: QK_PAYABLE }),
  })
}
