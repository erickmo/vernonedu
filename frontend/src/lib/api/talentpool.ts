import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  TalentPoolEntry,
  TalentPoolFilters,
  PaginatedTalentPool,
} from '@/types/talentpool'
import type { Profession } from '@/types/profession'
import type { UpdateTalentPoolStatusInput } from '@/schemas/talentpool'
import type { ProfessionInput } from '@/schemas/profession'

const TP = '/talentpool'
const PROFESSIONS = '/talentpool/professions'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface TPSingleResponse { data: TalentPoolEntry }
interface ProfessionsResponse { data: Profession[] }

export function useTalentPool(filters: TalentPoolFilters = {}) {
  const limit = filters.limit ?? 50
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.status) params.status = filters.status
  if (filters.master_course_id) params.master_course_id = filters.master_course_id
  if (filters.participant_id) params.participant_id = filters.participant_id

  return useQuery({
    queryKey: ['talentpool', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedTalentPool>(TP, { params }).then((r) => r.data),
  })
}

export function useTalentPoolEntry(id: string | undefined) {
  return useQuery({
    queryKey: ['talentpool', id],
    queryFn: () =>
      apiClient.get<TPSingleResponse>(`${TP}/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useUpdateTalentPoolStatus() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (args: { id: string; input: UpdateTalentPoolStatusInput }) =>
      apiClient.put(`${TP}/${args.id}/status`, args.input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['talentpool', 'list'] }),
  })
}

export function useProfessions() {
  return useQuery({
    queryKey: ['talentpool', 'professions'],
    queryFn: () =>
      apiClient.get<ProfessionsResponse>(PROFESSIONS).then((r) => r.data.data ?? []),
  })
}

export function useCreateProfession() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: ProfessionInput) =>
      apiClient.post(PROFESSIONS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['talentpool', 'professions'] }),
  })
}

export function useUpdateProfession() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (args: { id: string; input: ProfessionInput }) =>
      apiClient.put(`${PROFESSIONS}/${args.id}`, args.input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['talentpool', 'professions'] }),
  })
}

export function useDeleteProfession() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${PROFESSIONS}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['talentpool', 'professions'] }),
  })
}
