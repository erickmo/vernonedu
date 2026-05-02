import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  Invoice,
  InvoiceListFilters,
  InvoiceListResponse,
  CreateInvoicePayload,
} from '@/types/invoice'

const INVOICES_BASE = '/finance/invoices'
const QK_INVOICES = ['finance', 'invoices'] as const

export function useFinanceInvoices(filters: InvoiceListFilters = {}) {
  return useQuery({
    queryKey: [...QK_INVOICES, 'list', filters],
    queryFn: () =>
      apiClient
        .get<InvoiceListResponse>(INVOICES_BASE, { params: filters })
        .then((r) => r.data),
  })
}

export function useFinanceInvoice(id: string) {
  return useQuery({
    queryKey: [...QK_INVOICES, 'detail', id],
    queryFn: () =>
      apiClient.get<Invoice>(`${INVOICES_BASE}/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreateFinanceInvoice() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: CreateInvoicePayload) =>
      apiClient.post<Invoice>(INVOICES_BASE, payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: QK_INVOICES }),
  })
}

export function usePayFinanceInvoice() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.put<Invoice>(`${INVOICES_BASE}/${id}/pay`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: QK_INVOICES }),
  })
}

export function useCancelFinanceInvoice() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient
        .put<Invoice>(`${INVOICES_BASE}/${id}/cancel`)
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: QK_INVOICES }),
  })
}
