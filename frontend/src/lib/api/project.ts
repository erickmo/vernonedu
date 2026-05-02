import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { Project, ProjectFilters, PaginatedProjects } from '@/types/project'
import type { CreateProjectInput, UpdateProjectInput } from '@/schemas/project'

const PROJECTS = '/projects'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface SingleResponse<T> { data: T }

export function useProjects(filters: ProjectFilters = {}) {
  const limit = filters.limit ?? 15
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.status) params.status = filters.status
  if (filters.partner_id) params.partner_id = filters.partner_id
  if (filters.branch_id) params.branch_id = filters.branch_id
  return useQuery({
    queryKey: ['projects', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedProjects>(PROJECTS, { params }).then((r) => r.data),
  })
}

export function useProject(id: string | undefined) {
  return useQuery({
    queryKey: ['projects', id],
    queryFn: () =>
      apiClient.get<SingleResponse<Project>>(`${PROJECTS}/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateProject() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateProjectInput) =>
      apiClient.post(PROJECTS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['projects', 'list'] }),
  })
}

export function useUpdateProject(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateProjectInput) =>
      apiClient.put(`${PROJECTS}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['projects', 'list'] })
      qc.invalidateQueries({ queryKey: ['projects', id] })
    },
  })
}

export function useDeleteProject() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${PROJECTS}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['projects', 'list'] }),
  })
}
