import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  Delegation, DelegationFilters, PaginatedDelegations,
} from '@/types/delegation'
import type {
  CreateDelegationInput, UpdateDelegationInput, TransitionDelegationInput,
} from '@/schemas/delegation'

const DELEGATIONS = '/delegations'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface DelegationSingleResponse { data: Delegation }

function toApiCreate(input: CreateDelegationInput) {
  return {
    title: input.title,
    type: input.type,
    description: input.description,
    requestedById: input.requested_by_id,
    requestedByName: input.requested_by_name,
    assignedToId: input.assigned_to_id,
    assignedToName: input.assigned_to_name,
    assignedToRole: input.assigned_to_role,
    dueDate: input.due_date,
    priority: input.priority,
    linkedEntityType: input.linked_entity_type,
    linkedEntityId: input.linked_entity_id,
    notes: input.notes,
  }
}

function toApiUpdate(input: UpdateDelegationInput) {
  return {
    title: input.title,
    description: input.description,
    dueDate: input.due_date,
    priority: input.priority,
    notes: input.notes,
  }
}

export function useDelegations(filters: DelegationFilters = {}) {
  const limit = filters.limit ?? 15
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.status) params.status = filters.status
  if (filters.type) params.type = filters.type
  if (filters.assigned_to_id) params.assigned_to_id = filters.assigned_to_id
  if (filters.requested_by_id) params.requested_by_id = filters.requested_by_id
  return useQuery({
    queryKey: ['delegations', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedDelegations>(DELEGATIONS, { params }).then((r) => r.data),
  })
}

export function useDelegation(id: string | undefined) {
  return useQuery({
    queryKey: ['delegations', id],
    queryFn: () =>
      apiClient
        .get<DelegationSingleResponse>(`${DELEGATIONS}/${id}`)
        .then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateDelegation() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateDelegationInput) =>
      apiClient.post(DELEGATIONS, toApiCreate(input)).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['delegations', 'list'] }),
  })
}

export function useUpdateDelegation(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateDelegationInput) =>
      apiClient.put(`${DELEGATIONS}/${id}`, toApiUpdate(input)).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['delegations', 'list'] })
      qc.invalidateQueries({ queryKey: ['delegations', id] })
    },
  })
}

function buildTransition(action: 'accept' | 'complete' | 'cancel') {
  return function useTransition(id: string) {
    const qc = useQueryClient()
    return useMutation({
      mutationFn: (input: TransitionDelegationInput = { notes: '' }) =>
        apiClient.post(`${DELEGATIONS}/${id}/${action}`, input).then((r) => r.data),
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: ['delegations', 'list'] })
        qc.invalidateQueries({ queryKey: ['delegations', id] })
      },
    })
  }
}

export const useAcceptDelegation = buildTransition('accept')
export const useCompleteDelegation = buildTransition('complete')
export const useCancelDelegation = buildTransition('cancel')
