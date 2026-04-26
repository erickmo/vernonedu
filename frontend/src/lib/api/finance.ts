import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface Payment {
  id: string
  enrollment_id: string
  total_amount: number
  paid_amount: number
  status: 'pending' | 'partial' | 'paid' | 'overdue'
  due_date: string
  transactions: PaymentTransaction[]
}

export interface PaymentTransaction {
  id: string
  payment_id: string
  amount: number
  method: 'bank_transfer' | 'credit_card' | 'cash' | 'voucher'
  reference_number?: string
  proof_url?: string
  status: 'pending' | 'confirmed' | 'rejected'
  created_at: string
  confirmed_at?: string
  confirmed_by?: string
}

export interface Invoice {
  id: string
  number: string
  enrollment_id?: string
  partner_id?: string
  items: InvoiceItem[]
  subtotal: number
  tax_amount: number
  total: number
  status: 'draft' | 'sent' | 'paid' | 'overdue' | 'cancelled'
  issued_date: string
  due_date: string
  paid_date?: string
}

export interface InvoiceItem {
  description: string
  quantity: number
  unit_price: number
  total: number
}

export interface Budget {
  id: string
  batch_id: string
  total_allocated: number
  total_realized: number
  items: BudgetItem[]
}

export interface BudgetItem {
  id: string
  budget_id: string
  category: string
  description: string
  allocated_amount: number
  realized_amount: number
}

export interface InvoiceFilters {
  status?: string
  partner_id?: string
  enrollment_id?: string
  page?: number
  limit?: number
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
}

// ── Payment hooks ──────────────────────────────────────────────────────────

export function usePayment(enrollmentId: string) {
  return useQuery({
    queryKey: ['payments', { enrollmentId }],
    queryFn: () =>
      apiClient.get<Payment>(`/enrollments/${enrollmentId}/payment`).then((r) => r.data),
    enabled: !!enrollmentId,
  })
}

export function useCreatePaymentTransaction() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<PaymentTransaction, 'id' | 'status' | 'created_at' | 'confirmed_at' | 'confirmed_by'>) =>
      apiClient.post<PaymentTransaction>('/payment-transactions', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['payments'] }),
  })
}

export function useConfirmPayment() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ transactionId, action }: { transactionId: string; action: 'confirm' | 'reject'; note?: string }) =>
      apiClient
        .post<PaymentTransaction>(`/payment-transactions/${transactionId}/${action}`)
        .then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['payments'] })
      qc.invalidateQueries({ queryKey: ['enrollments'] })
    },
  })
}

// ── Invoice hooks ──────────────────────────────────────────────────────────

export function useInvoices(filters: InvoiceFilters = {}) {
  return useQuery({
    queryKey: ['invoices', filters],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Invoice>>('/invoices', { params: filters }).then((r) => r.data),
  })
}

export function useInvoice(id: string) {
  return useQuery({
    queryKey: ['invoices', id],
    queryFn: () => apiClient.get<Invoice>(`/invoices/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreateInvoice() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<Invoice, 'id' | 'number' | 'subtotal' | 'total'>) =>
      apiClient.post<Invoice>('/invoices', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['invoices'] }),
  })
}

export function useUpdateInvoiceStatus() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: Invoice['status'] }) =>
      apiClient.patch<Invoice>(`/invoices/${id}/status`, { status }).then((r) => r.data),
    onSuccess: (_data, vars) => {
      qc.invalidateQueries({ queryKey: ['invoices', vars.id] })
      qc.invalidateQueries({ queryKey: ['invoices'] })
    },
  })
}

export function useInvoicePDF(id: string) {
  return useQuery({
    queryKey: ['invoices', id, 'pdf'],
    queryFn: () =>
      apiClient.get(`/invoices/${id}/pdf`, { responseType: 'blob' }).then((r) => r.data as Blob),
    enabled: !!id,
  })
}

// ── Budget hooks ───────────────────────────────────────────────────────────

export function useBudget(batchId: string) {
  return useQuery({
    queryKey: ['budgets', { batchId }],
    queryFn: () =>
      apiClient.get<Budget>(`/batches/${batchId}/budget`).then((r) => r.data),
    enabled: !!batchId,
  })
}

export function useCreateBudgetRealization() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<BudgetItem, 'id'>) =>
      apiClient.post<BudgetItem>('/budget-items', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['budgets'] }),
  })
}
