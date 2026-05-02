import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  MasterCourse,
  MasterCourseFilters,
  PaginatedMasterCourses,
} from '@/types/mastercourse'
import type { CreateMasterCourseInput, UpdateMasterCourseInput } from '@/schemas/mastercourse'

const BASE = '/curriculum/courses'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

export function useMasterCourses(filters: MasterCourseFilters = {}) {
  const limit = filters.limit ?? 15
  const offset = toOffset(filters.page, limit)
  const params = {
    offset,
    limit,
    ...(filters.search ? { search: filters.search } : {}),
    ...(filters.field ? { field: filters.field } : {}),
    ...(filters.status ? { status: filters.status } : {}),
    ...(filters.department_id ? { department_id: filters.department_id } : {}),
  }
  return useQuery({
    queryKey: ['mastercourses', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedMasterCourses>(BASE, { params }).then((r) => r.data),
  })
}

export function useMasterCourse(id: string | undefined) {
  return useQuery({
    queryKey: ['mastercourses', id],
    queryFn: () => apiClient.get<MasterCourse>(`${BASE}/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreateMasterCourse() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateMasterCourseInput) =>
      apiClient.post<MasterCourse>(BASE, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['mastercourses', 'list'] }),
  })
}

export function useUpdateMasterCourse(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateMasterCourseInput) =>
      apiClient.put<MasterCourse>(`${BASE}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['mastercourses', 'list'] })
      qc.invalidateQueries({ queryKey: ['mastercourses', id] })
    },
  })
}

export function useArchiveMasterCourse() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`${BASE}/${id}/archive`).then((r) => r.data),
    onSuccess: (_d, id) => {
      qc.invalidateQueries({ queryKey: ['mastercourses', 'list'] })
      qc.invalidateQueries({ queryKey: ['mastercourses', id] })
    },
  })
}
