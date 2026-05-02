import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { Branch, BranchFilters, PaginatedBranches } from '@/types/branch'
import type { CreateBranchInput, UpdateBranchInput } from '@/schemas/branch'

const BRANCHES = '/settings/branches'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface SingleResponse<T> { data: T }

export function useBranches(filters: BranchFilters = {}) {
  const limit = filters.limit ?? 50
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (typeof filters.is_active === 'boolean') params.is_active = filters.is_active
  return useQuery({
    queryKey: ['branches', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedBranches>(BRANCHES, { params }).then((r) => r.data),
  })
}

export function useBranch(id: string | undefined) {
  return useQuery({
    queryKey: ['branches', id],
    queryFn: () =>
      apiClient.get<SingleResponse<Branch>>(`${BRANCHES}/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateBranch() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateBranchInput) =>
      apiClient.post(BRANCHES, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['branches', 'list'] }),
  })
}

export function useUpdateBranch(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateBranchInput) =>
      apiClient.put(`${BRANCHES}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['branches', 'list'] })
      qc.invalidateQueries({ queryKey: ['branches', id] })
    },
  })
}

export function useDeleteBranch() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${BRANCHES}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['branches', 'list'] }),
  })
}
