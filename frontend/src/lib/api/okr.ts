import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  Objective, KeyResult, ObjectiveFilters, PaginatedObjectives,
} from '@/types/okr'
import type {
  CreateObjectiveInput, CreateKeyResultInput, UpdateKeyResultProgressInput,
} from '@/schemas/okr'

const OBJECTIVES = '/okr/objectives'
const KEY_RESULTS = '/okr/key-results'
const OKR = '/okr'

interface ObjResponse { data: Objective }
interface KRResponse { data: KeyResult }

export function useObjectives(filters: ObjectiveFilters = {}) {
  const params = {
    level: filters.level || undefined,
    status: filters.status || undefined,
  }
  return useQuery({
    queryKey: ['okr', 'objectives', params],
    queryFn: () =>
      apiClient
        .get<PaginatedObjectives>(OKR, { params })
        .then((r) => r.data),
  })
}

export function useObjective(id: string | undefined) {
  return useQuery({
    queryKey: ['okr', 'objectives', id],
    queryFn: () =>
      apiClient
        .get<ObjResponse>(`${OBJECTIVES}/${id}`)
        .then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateObjective() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateObjectiveInput) =>
      apiClient.post(OKR, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['okr'] }),
  })
}

export function useCreateKeyResult() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateKeyResultInput) =>
      apiClient.post(KEY_RESULTS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['okr'] }),
  })
}

export function useUpdateKeyResultProgress() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (args: { id: string; input: UpdateKeyResultProgressInput }) =>
      apiClient.put<KRResponse>(`${KEY_RESULTS}/${args.id}/progress`, args.input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['okr'] }),
  })
}
