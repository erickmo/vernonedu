import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  InvestmentPlan, InvestmentFilters, PaginatedInvestments,
} from '@/types/investment'
import type { CreateInvestmentInput, UpdateInvestmentInput } from '@/schemas/investment'

const INVESTMENTS = '/investments'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface InvestmentSingleResponse { data: InvestmentPlan }

export function useInvestments(filters: InvestmentFilters = {}) {
  const limit = filters.limit ?? 15
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.status) params.status = filters.status
  return useQuery({
    queryKey: ['investments', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedInvestments>(INVESTMENTS, { params }).then((r) => r.data),
  })
}

export function useInvestment(id: string | undefined) {
  return useQuery({
    queryKey: ['investments', id],
    queryFn: () =>
      apiClient
        .get<InvestmentSingleResponse>(`${INVESTMENTS}/${id}`)
        .then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateInvestment() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateInvestmentInput) =>
      apiClient.post(INVESTMENTS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['investments', 'list'] }),
  })
}

export function useUpdateInvestment(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateInvestmentInput) =>
      apiClient.put(`${INVESTMENTS}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['investments', 'list'] })
      qc.invalidateQueries({ queryKey: ['investments', id] })
    },
  })
}
