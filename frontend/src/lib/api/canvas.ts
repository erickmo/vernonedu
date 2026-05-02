import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { Canvas, CanvasFilters } from '@/types/canvas'
import type { CreateCanvasInput, UpdateCanvasInput } from '@/schemas/canvas'

const CANVASES = '/canvases'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface CanvasListResponse { data: Canvas[]; total?: number }
interface CanvasSingleResponse { data: Canvas }

export function useCanvases(filters: CanvasFilters = {}) {
  const limit = filters.limit ?? 20
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.name) params.name = filters.name
  const path = filters.name ? `${CANVASES}/search` : CANVASES

  return useQuery({
    queryKey: ['canvases', 'list', params, !!filters.name],
    queryFn: () =>
      apiClient.get<CanvasListResponse>(path, { params }).then((r) => r.data.data ?? []),
  })
}

export function useCanvas(id: string | undefined) {
  return useQuery({
    queryKey: ['canvases', id],
    queryFn: () =>
      apiClient.get<CanvasSingleResponse>(`${CANVASES}/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateCanvas() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCanvasInput) =>
      apiClient.post(CANVASES, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['canvases', 'list'] }),
  })
}

export function useUpdateCanvas(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateCanvasInput) =>
      apiClient.put(`${CANVASES}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['canvases', 'list'] })
      qc.invalidateQueries({ queryKey: ['canvases', id] })
    },
  })
}

export function useDeleteCanvas() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${CANVASES}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['canvases', 'list'] }),
  })
}
