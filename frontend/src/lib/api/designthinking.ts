import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { DesignThinking, DesignThinkingFilters } from '@/types/designthinking'
import type {
  CreateDesignThinkingInput,
  UpdateDesignThinkingInput,
} from '@/schemas/designthinking'

const DTS = '/design-thinkings'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface DTListResponse { data: DesignThinking[] }
interface DTSingleResponse { data: DesignThinking }

export function useDesignThinkings(filters: DesignThinkingFilters = {}) {
  const limit = filters.limit ?? 20
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.name) params.name = filters.name
  const path = filters.name ? `${DTS}/search` : DTS

  return useQuery({
    queryKey: ['design-thinkings', 'list', params, !!filters.name],
    queryFn: () =>
      apiClient.get<DTListResponse>(path, { params }).then((r) => r.data.data ?? []),
  })
}

export function useDesignThinking(id: string | undefined) {
  return useQuery({
    queryKey: ['design-thinkings', id],
    queryFn: () =>
      apiClient.get<DTSingleResponse>(`${DTS}/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateDesignThinking() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateDesignThinkingInput) =>
      apiClient.post(DTS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['design-thinkings', 'list'] }),
  })
}

export function useUpdateDesignThinking(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateDesignThinkingInput) =>
      apiClient.put(`${DTS}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['design-thinkings', 'list'] })
      qc.invalidateQueries({ queryKey: ['design-thinkings', id] })
    },
  })
}

export function useDeleteDesignThinking() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${DTS}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['design-thinkings', 'list'] }),
  })
}
