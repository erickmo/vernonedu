import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  CourseBatch,
  CourseBatchDetail,
  CourseBatchFilters,
  PaginatedCourseBatches,
  BatchSchedule,
} from '@/types/coursebatch'
import type {
  CreateCourseBatchInput,
  UpdateCourseBatchInput,
  AssignFacilitatorInput,
} from '@/schemas/coursebatch'

const BASE = '/course-batches'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface SingleResponse<T> {
  data: T
}
interface ListResponseEnvelope<T> {
  data: T[]
}

export function useCourseBatches(filters: CourseBatchFilters = {}) {
  const limit = filters.limit ?? 15
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.status) params.status = filters.status
  if (filters.course_id) params.course_id = filters.course_id

  return useQuery({
    queryKey: ['coursebatches', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedCourseBatches>(BASE, { params }).then((r) => r.data),
  })
}

export function useCourseBatch(id: string | undefined) {
  return useQuery({
    queryKey: ['coursebatches', id],
    queryFn: () =>
      apiClient
        .get<SingleResponse<CourseBatch>>(`${BASE}/${id}`)
        .then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCourseBatchDetail(id: string | undefined) {
  return useQuery({
    queryKey: ['coursebatches', id, 'detail'],
    queryFn: () =>
      apiClient
        .get<SingleResponse<CourseBatchDetail>>(`${BASE}/${id}/detail`)
        .then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useBatchSchedules(id: string | undefined) {
  return useQuery({
    queryKey: ['coursebatches', id, 'schedules'],
    queryFn: () =>
      apiClient
        .get<ListResponseEnvelope<BatchSchedule>>(`${BASE}/${id}/schedules`)
        .then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateCourseBatch() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCourseBatchInput) =>
      apiClient.post(BASE, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['coursebatches', 'list'] }),
  })
}

export function useUpdateCourseBatch(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateCourseBatchInput) =>
      apiClient.put(`${BASE}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['coursebatches', 'list'] })
      qc.invalidateQueries({ queryKey: ['coursebatches', id] })
    },
  })
}

export function useDeleteCourseBatch() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => apiClient.delete(`${BASE}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['coursebatches', 'list'] }),
  })
}

export function useAssignFacilitator(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: AssignFacilitatorInput) =>
      apiClient.put(`${BASE}/${id}/facilitator`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['coursebatches', id] })
      qc.invalidateQueries({ queryKey: ['coursebatches', id, 'detail'] })
      qc.invalidateQueries({ queryKey: ['coursebatches', 'list'] })
    },
  })
}
