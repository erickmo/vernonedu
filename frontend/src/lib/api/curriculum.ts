import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  MasterCourse,
  MasterCourseFilters,
  PaginatedMasterCourses,
} from '@/types/mastercourse'
import type { CreateMasterCourseInput, UpdateMasterCourseInput } from '@/schemas/mastercourse'
import type { CourseType } from '@/types/coursetype'
import type { CreateCourseTypeInput, UpdateCourseTypeInput } from '@/schemas/coursetype'
import type { CourseVersion } from '@/types/courseversion'
import type {
  CreateCourseVersionInput,
  PromoteCourseVersionInput,
} from '@/schemas/courseversion'
import type { CourseModule } from '@/types/coursemodule'
import type {
  CreateCourseModuleInput,
  UpdateCourseModuleInput,
} from '@/schemas/coursemodule'
import type { InternshipConfig } from '@/types/internshipconfig'
import type { UpsertInternshipConfigInput } from '@/schemas/internshipconfig'
import type { CharacterTestConfig } from '@/types/charactertestconfig'
import type { UpsertCharacterTestConfigInput } from '@/schemas/charactertestconfig'

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

// ── CourseType (variants under master course) ──────────────────────────────

const TYPES_BASE = '/api/v1/curriculum/types'
const COURSE_TYPES = (courseId: string) =>
  `/api/v1/curriculum/courses/${courseId}/types`

interface CourseTypeListResponse {
  data: CourseType[]
}

interface CourseTypeSingleResponse {
  data: CourseType
}

export function useCourseTypes(courseId: string | undefined) {
  return useQuery({
    queryKey: ['coursetypes', 'list', courseId],
    queryFn: () =>
      apiClient
        .get<CourseTypeListResponse>(COURSE_TYPES(courseId!))
        .then((r) => r.data.data),
    enabled: !!courseId,
  })
}

export function useCourseType(typeId: string | undefined) {
  return useQuery({
    queryKey: ['coursetypes', typeId],
    queryFn: () =>
      apiClient
        .get<CourseTypeSingleResponse>(`${TYPES_BASE}/${typeId}`)
        .then((r) => r.data.data),
    enabled: !!typeId,
  })
}

export function useCreateCourseType(courseId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCourseTypeInput) =>
      apiClient
        .post<CourseTypeSingleResponse>(COURSE_TYPES(courseId), input)
        .then((r) => r.data.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['coursetypes', 'list', courseId] }),
  })
}

export function useUpdateCourseType(typeId: string, courseId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateCourseTypeInput) =>
      apiClient
        .put<CourseTypeSingleResponse>(`${TYPES_BASE}/${typeId}`, input)
        .then((r) => r.data.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['coursetypes', 'list', courseId] })
      qc.invalidateQueries({ queryKey: ['coursetypes', typeId] })
    },
  })
}

export function useToggleCourseType(courseId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (typeId: string) =>
      apiClient.post(`${TYPES_BASE}/${typeId}/toggle`).then((r) => r.data),
    onSuccess: (_d, typeId) => {
      qc.invalidateQueries({ queryKey: ['coursetypes', 'list', courseId] })
      qc.invalidateQueries({ queryKey: ['coursetypes', typeId] })
    },
  })
}

// ===== CourseVersion =====

const VERSIONS_BASE = '/api/v1/curriculum/versions'
const TYPE_VERSIONS = (typeId: string) => `/api/v1/curriculum/types/${typeId}/versions`

interface CourseVersionListResponse {
  data: CourseVersion[]
}
interface CourseVersionSingleResponse {
  data: CourseVersion
}

export function useCourseVersions(typeId: string | undefined) {
  return useQuery({
    queryKey: ['courseversions', 'list', typeId],
    queryFn: () =>
      apiClient
        .get<CourseVersionListResponse>(TYPE_VERSIONS(typeId!))
        .then((r) => r.data.data),
    enabled: !!typeId,
  })
}

export function useCourseVersion(versionId: string | undefined) {
  return useQuery({
    queryKey: ['courseversions', versionId],
    queryFn: () =>
      apiClient
        .get<CourseVersionSingleResponse>(`${VERSIONS_BASE}/${versionId}`)
        .then((r) => r.data.data),
    enabled: !!versionId,
  })
}

export function useCreateCourseVersion(typeId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCourseVersionInput) =>
      apiClient.post(TYPE_VERSIONS(typeId), input).then((r) => r.data),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['courseversions', 'list', typeId] }),
  })
}

export function usePromoteCourseVersion(typeId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (args: { versionId: string; input: PromoteCourseVersionInput }) =>
      apiClient
        .post(`${VERSIONS_BASE}/${args.versionId}/promote`, args.input)
        .then((r) => r.data),
    onSuccess: (_d, { versionId }) => {
      qc.invalidateQueries({ queryKey: ['courseversions', 'list', typeId] })
      qc.invalidateQueries({ queryKey: ['courseversions', versionId] })
    },
  })
}

// ===== CourseModule =====

const MODULES_BASE = '/api/v1/curriculum/modules'
const VERSION_MODULES = (versionId: string) =>
  `/api/v1/curriculum/versions/${versionId}/modules`

interface CourseModuleListResponse { data: CourseModule[] }
interface CourseModuleSingleResponse { data: CourseModule }

export function useCourseModules(versionId: string | undefined) {
  return useQuery({
    queryKey: ['coursemodules', 'list', versionId],
    queryFn: () =>
      apiClient
        .get<CourseModuleListResponse>(VERSION_MODULES(versionId!))
        .then((r) => r.data.data),
    enabled: !!versionId,
  })
}

export function useCourseModule(moduleId: string | undefined) {
  return useQuery({
    queryKey: ['coursemodules', moduleId],
    queryFn: () =>
      apiClient
        .get<CourseModuleSingleResponse>(`${MODULES_BASE}/${moduleId}`)
        .then((r) => r.data.data),
    enabled: !!moduleId,
  })
}

export function useCreateCourseModule(versionId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCourseModuleInput) =>
      apiClient.post(VERSION_MODULES(versionId), input).then((r) => r.data),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['coursemodules', 'list', versionId] }),
  })
}

export function useUpdateCourseModule(versionId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (args: { moduleId: string; input: UpdateCourseModuleInput }) =>
      apiClient
        .put(`${MODULES_BASE}/${args.moduleId}`, args.input)
        .then((r) => r.data),
    onSuccess: (_d, { moduleId }) => {
      qc.invalidateQueries({ queryKey: ['coursemodules', 'list', versionId] })
      qc.invalidateQueries({ queryKey: ['coursemodules', moduleId] })
    },
  })
}

export function useDeleteCourseModule(versionId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (moduleId: string) =>
      apiClient.delete(`${MODULES_BASE}/${moduleId}`).then((r) => r.data),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['coursemodules', 'list', versionId] }),
  })
}

// ===== Program Karir Configs =====

const VERSION_INTERNSHIP = (versionId: string) =>
  `/api/v1/curriculum/versions/${versionId}/internship`
const VERSION_CHARACTER_TEST = (versionId: string) =>
  `/api/v1/curriculum/versions/${versionId}/character-test`

interface InternshipConfigResponse { data: InternshipConfig }
interface CharacterTestConfigResponse { data: CharacterTestConfig }

export function useInternshipConfig(versionId: string | undefined) {
  return useQuery({
    queryKey: ['internshipconfig', versionId],
    queryFn: async () => {
      try {
        const r = await apiClient.get<InternshipConfigResponse>(VERSION_INTERNSHIP(versionId!))
        return r.data.data
      } catch (e: any) {
        if (e?.response?.status === 404) return null
        throw e
      }
    },
    enabled: !!versionId,
  })
}

export function useUpsertInternshipConfig(versionId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpsertInternshipConfigInput) =>
      apiClient.put(VERSION_INTERNSHIP(versionId), input).then((r) => r.data),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['internshipconfig', versionId] }),
  })
}

export function useCharacterTestConfig(versionId: string | undefined) {
  return useQuery({
    queryKey: ['charactertestconfig', versionId],
    queryFn: async () => {
      try {
        const r = await apiClient.get<CharacterTestConfigResponse>(VERSION_CHARACTER_TEST(versionId!))
        return r.data.data
      } catch (e: any) {
        if (e?.response?.status === 404) return null
        throw e
      }
    },
    enabled: !!versionId,
  })
}

export function useUpsertCharacterTestConfig(versionId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpsertCharacterTestConfigInput) =>
      apiClient.put(VERSION_CHARACTER_TEST(versionId), input).then((r) => r.data),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['charactertestconfig', versionId] }),
  })
}
