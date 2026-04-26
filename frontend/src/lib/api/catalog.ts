import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface Course {
  id: string
  name: string
  code: string
  department_id: string
  description: string
  duration_days: number
  format: 'online' | 'offline' | 'hybrid'
  status: 'active' | 'inactive'
}

export interface Batch {
  id: string
  course_id: string
  code: string
  start_date: string
  end_date: string
  max_students: number
  enrolled_count: number
  price: number
  status: 'draft' | 'open' | 'full' | 'ongoing' | 'completed' | 'cancelled'
}

export interface ClassSession {
  id: string
  batch_id: string
  date: string
  start_time: string
  end_time: string
  facilitator_id: string
  topic: string
  location?: string
  meeting_url?: string
}

export interface Module {
  id: string
  course_id: string
  title: string
  order: number
  description: string
}

export interface ModuleVersion {
  id: string
  module_id: string
  version: number
  status: 'draft' | 'published'
  published_at?: string
  created_by: string
}

export interface ModuleAsset {
  id: string
  version_id: string
  type: 'pdf' | 'video' | 'link' | 'quiz'
  title: string
  url: string
  order: number
}

export interface CourseFilters {
  department_id?: string
  status?: string
  search?: string
  page?: number
  limit?: number
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
}

// ── Course hooks ───────────────────────────────────────────────────────────

export function useCourses(filters: CourseFilters = {}) {
  return useQuery({
    queryKey: ['courses', filters],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Course>>('/courses', { params: filters }).then((r) => r.data),
  })
}

export function useCourse(id: string) {
  return useQuery({
    queryKey: ['courses', id],
    queryFn: () => apiClient.get<Course>(`/courses/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreateCourse() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<Course, 'id'>) =>
      apiClient.post<Course>('/courses', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['courses'] }),
  })
}

export function useUpdateCourse() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, ...payload }: Partial<Course> & { id: string }) =>
      apiClient.patch<Course>(`/courses/${id}`, payload).then((r) => r.data),
    onSuccess: (_data, vars) => {
      qc.invalidateQueries({ queryKey: ['courses', vars.id] })
      qc.invalidateQueries({ queryKey: ['courses'] })
    },
  })
}

// ── Batch hooks ────────────────────────────────────────────────────────────

export function useBatches(courseId: string) {
  return useQuery({
    queryKey: ['batches', { courseId }],
    queryFn: () =>
      apiClient.get<Batch[]>(`/courses/${courseId}/batches`).then((r) => r.data),
    enabled: !!courseId,
  })
}

export function useBatch(id: string) {
  return useQuery({
    queryKey: ['batches', id],
    queryFn: () => apiClient.get<Batch>(`/batches/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreateBatch() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<Batch, 'id' | 'enrolled_count'>) =>
      apiClient.post<Batch>('/batches', payload).then((r) => r.data),
    onSuccess: (_data, vars) => qc.invalidateQueries({ queryKey: ['batches', { courseId: vars.course_id }] }),
  })
}

export function useUpdateBatchStatus() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: Batch['status'] }) =>
      apiClient.patch<Batch>(`/batches/${id}/status`, { status }).then((r) => r.data),
    onSuccess: (_data, vars) => {
      qc.invalidateQueries({ queryKey: ['batches', vars.id] })
      qc.invalidateQueries({ queryKey: ['batches'] })
    },
  })
}

// ── Class session hooks ────────────────────────────────────────────────────

export function useClasses(batchId: string) {
  return useQuery({
    queryKey: ['classes', { batchId }],
    queryFn: () =>
      apiClient.get<ClassSession[]>(`/batches/${batchId}/classes`).then((r) => r.data),
    enabled: !!batchId,
  })
}

export function useCreateClass() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<ClassSession, 'id'>) =>
      apiClient.post<ClassSession>('/classes', payload).then((r) => r.data),
    onSuccess: (_data, vars) => qc.invalidateQueries({ queryKey: ['classes', { batchId: vars.batch_id }] }),
  })
}

// ── Module hooks ───────────────────────────────────────────────────────────

export function useModules(courseId: string) {
  return useQuery({
    queryKey: ['modules', { courseId }],
    queryFn: () =>
      apiClient.get<Module[]>(`/courses/${courseId}/modules`).then((r) => r.data),
    enabled: !!courseId,
  })
}

export function useCreateModule() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<Module, 'id'>) =>
      apiClient.post<Module>('/modules', payload).then((r) => r.data),
    onSuccess: (_data, vars) => qc.invalidateQueries({ queryKey: ['modules', { courseId: vars.course_id }] }),
  })
}

export function useModuleVersions(moduleId: string) {
  return useQuery({
    queryKey: ['module-versions', { moduleId }],
    queryFn: () =>
      apiClient.get<ModuleVersion[]>(`/modules/${moduleId}/versions`).then((r) => r.data),
    enabled: !!moduleId,
  })
}

export function usePublishModuleVersion() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (versionId: string) =>
      apiClient.post<ModuleVersion>(`/module-versions/${versionId}/publish`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['module-versions'] }),
  })
}

export function useModuleAssets(versionId: string) {
  return useQuery({
    queryKey: ['module-assets', { versionId }],
    queryFn: () =>
      apiClient.get<ModuleAsset[]>(`/module-versions/${versionId}/assets`).then((r) => r.data),
    enabled: !!versionId,
  })
}

export function useAddModuleAsset() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<ModuleAsset, 'id'>) =>
      apiClient.post<ModuleAsset>('/module-assets', payload).then((r) => r.data),
    onSuccess: (_data, vars) =>
      qc.invalidateQueries({ queryKey: ['module-assets', { versionId: vars.version_id }] }),
  })
}
