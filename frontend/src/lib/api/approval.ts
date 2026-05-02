import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { Approval, ApprovalFilters, PaginatedApprovals } from '@/types/approval'
import type { CreateApprovalInput, DecisionInput } from '@/schemas/approval'

const APPROVALS = '/approvals'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface SingleResponse<T> { data: T }

export function useApprovals(filters: ApprovalFilters = {}) {
  const limit = filters.limit ?? 15
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.status) params.status = filters.status
  if (filters.approver_id) params.approver_id = filters.approver_id
  if (filters.type) params.type = filters.type
  return useQuery({
    queryKey: ['approvals', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedApprovals>(APPROVALS, { params }).then((r) => r.data),
  })
}

export function useApproval(id: string | undefined) {
  return useQuery({
    queryKey: ['approvals', id],
    queryFn: () =>
      apiClient.get<SingleResponse<Approval>>(`${APPROVALS}/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateApproval() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateApprovalInput) =>
      apiClient.post(APPROVALS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['approvals', 'list'] }),
  })
}

function decisionMutation(id: string, action: 'approve' | 'reject' | 'cancel') {
  return (input: DecisionInput) =>
    apiClient.put(`${APPROVALS}/${id}/${action}`, input).then((r) => r.data)
}

export function useApproveApproval(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: decisionMutation(id, 'approve'),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['approvals', 'list'] })
      qc.invalidateQueries({ queryKey: ['approvals', id] })
    },
  })
}

export function useRejectApproval(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: decisionMutation(id, 'reject'),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['approvals', 'list'] })
      qc.invalidateQueries({ queryKey: ['approvals', id] })
    },
  })
}

export function useCancelApproval(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: decisionMutation(id, 'cancel'),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['approvals', 'list'] })
      qc.invalidateQueries({ queryKey: ['approvals', id] })
    },
  })
}
