import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { CmsPage, CmsPageFilters } from '@/types/cmspage'
import type {
  CmsArticle,
  CmsArticleFilters,
  PaginatedCmsArticles,
} from '@/types/cmsarticle'
import type { CmsFaq, CmsFaqFilters } from '@/types/cmsfaq'
import type { CmsTestimonial, CmsTestimonialFilters } from '@/types/cmstestimonial'
import type {
  CmsMedia,
  CmsMediaFilters,
  PaginatedCmsMedia,
} from '@/types/cmsmedia'
import type { UpdateCmsPageInput } from '@/schemas/cmspage'
import type {
  CreateCmsArticleInput,
  UpdateCmsArticleInput,
} from '@/schemas/cmsarticle'
import type {
  CreateCmsFaqInput,
  UpdateCmsFaqInput,
} from '@/schemas/cmsfaq'
import type {
  CreateCmsTestimonialInput,
  UpdateCmsTestimonialInput,
} from '@/schemas/cmstestimonial'
import type { UploadCmsMediaInput } from '@/schemas/cmsmedia'

const CMS = '/cms'
const DEFAULT_LIMIT = 15

interface SingleResponse<T> { data: T }
interface ListResponse<T> { data: T[] }

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

// ─── PAGES ────────────────────────────────────────────────────────────────────

export function useCmsPages(filters: CmsPageFilters = {}) {
  const params: Record<string, unknown> = {}
  if (filters.type) params.type = filters.type
  return useQuery({
    queryKey: ['cms-pages', 'list', params],
    queryFn: () =>
      apiClient
        .get<ListResponse<CmsPage>>(`${CMS}/pages`, { params })
        .then((r) => r.data.data ?? []),
  })
}

export function useCmsPage(slug: string | undefined) {
  return useQuery({
    queryKey: ['cms-pages', slug],
    queryFn: () =>
      apiClient
        .get<SingleResponse<CmsPage>>(`${CMS}/pages/${slug}`)
        .then((r) => r.data.data),
    enabled: !!slug,
  })
}

export function useUpdateCmsPage(slug: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateCmsPageInput) =>
      apiClient.put(`${CMS}/pages/${slug}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['cms-pages'] })
    },
  })
}

// ─── ARTICLES ─────────────────────────────────────────────────────────────────

export function useCmsArticles(filters: CmsArticleFilters = {}) {
  const limit = filters.limit ?? DEFAULT_LIMIT
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.category) params.category = filters.category
  if (filters.status) params.status = filters.status
  return useQuery({
    queryKey: ['cms-articles', 'list', params],
    queryFn: () =>
      apiClient
        .get<PaginatedCmsArticles>(`${CMS}/articles`, { params })
        .then((r) => r.data),
  })
}

export function useCmsArticle(slug: string | undefined) {
  return useQuery({
    queryKey: ['cms-articles', slug],
    queryFn: () =>
      apiClient
        .get<SingleResponse<CmsArticle>>(`${CMS}/articles/${slug}`)
        .then((r) => r.data.data),
    enabled: !!slug,
  })
}

export function useCreateCmsArticle() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCmsArticleInput) =>
      apiClient.post(`${CMS}/articles`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-articles', 'list'] }),
  })
}

export function useUpdateCmsArticle(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateCmsArticleInput) =>
      apiClient.put(`${CMS}/articles/${id}`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-articles'] }),
  })
}

export function useDeleteCmsArticle() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${CMS}/articles/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-articles', 'list'] }),
  })
}

// ─── FAQ ──────────────────────────────────────────────────────────────────────

export function useCmsFaqs(filters: CmsFaqFilters = {}) {
  const params: Record<string, unknown> = {}
  if (filters.category) params.category = filters.category
  if (filters.page_slug) params.page_slug = filters.page_slug
  return useQuery({
    queryKey: ['cms-faq', 'list', params],
    queryFn: () =>
      apiClient
        .get<ListResponse<CmsFaq>>(`${CMS}/faq`, { params })
        .then((r) => r.data.data ?? []),
  })
}

export function useCreateCmsFaq() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCmsFaqInput) =>
      apiClient.post(`${CMS}/faq`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-faq'] }),
  })
}

export function useUpdateCmsFaq(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateCmsFaqInput) =>
      apiClient.put(`${CMS}/faq/${id}`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-faq'] }),
  })
}

export function useDeleteCmsFaq() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${CMS}/faq/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-faq'] }),
  })
}

// ─── TESTIMONIALS ─────────────────────────────────────────────────────────────

export function useCmsTestimonials(filters: CmsTestimonialFilters = {}) {
  const params: Record<string, unknown> = {}
  if (filters.course_id) params.course_id = filters.course_id
  if (filters.is_featured !== undefined) params.is_featured = filters.is_featured
  return useQuery({
    queryKey: ['cms-testimonials', 'list', params],
    queryFn: () =>
      apiClient
        .get<ListResponse<CmsTestimonial>>(`${CMS}/testimonials`, { params })
        .then((r) => r.data.data ?? []),
  })
}

export function useCreateCmsTestimonial() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCmsTestimonialInput) =>
      apiClient.post(`${CMS}/testimonials`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-testimonials'] }),
  })
}

export function useUpdateCmsTestimonial(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateCmsTestimonialInput) =>
      apiClient.put(`${CMS}/testimonials/${id}`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-testimonials'] }),
  })
}

export function useDeleteCmsTestimonial() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${CMS}/testimonials/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-testimonials'] }),
  })
}

// ─── MEDIA ────────────────────────────────────────────────────────────────────

export function useCmsMedia(filters: CmsMediaFilters = {}) {
  const limit = filters.limit ?? DEFAULT_LIMIT
  const offset = toOffset(filters.page, limit)
  const params = { offset, limit }
  return useQuery({
    queryKey: ['cms-media', 'list', params],
    queryFn: () =>
      apiClient
        .get<PaginatedCmsMedia>(`${CMS}/media`, { params })
        .then((r) => r.data),
  })
}

export function useUploadCmsMedia() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UploadCmsMediaInput) =>
      apiClient.post(`${CMS}/media`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-media'] }),
  })
}

export function useUploadCmsMediaFile() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (file: File) => {
      const fd = new FormData()
      fd.append('file', file)
      return apiClient
        .post(`${CMS}/media`, fd, { headers: { 'Content-Type': 'multipart/form-data' } })
        .then((r) => r.data as { data?: CmsMedia })
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-media'] }),
  })
}

export function useDeleteCmsMedia() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${CMS}/media/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cms-media'] }),
  })
}
