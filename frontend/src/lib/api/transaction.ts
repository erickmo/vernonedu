import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  FinanceTransaction,
  TransactionListFilters,
  TransactionListResponse,
  CreateTransactionPayload,
} from '@/types/transaction'

const TX_BASE = '/finance/transactions'
const QK_TX = ['finance', 'transactions'] as const

export function useFinanceTransactions(filters: TransactionListFilters = {}) {
  return useQuery({
    queryKey: [...QK_TX, 'list', filters],
    queryFn: () =>
      apiClient
        .get<TransactionListResponse>(TX_BASE, { params: filters })
        .then((r) => r.data),
  })
}

export function useCreateFinanceTransaction() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: CreateTransactionPayload) =>
      apiClient.post<FinanceTransaction>(TX_BASE, payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: QK_TX }),
  })
}
