import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { MarketingPost, MarketingPostFilters } from '@/types/marketingpost'
import type { ClassDocPost, ClassDocPostFilters } from '@/types/classdocpost'
import type {
  ReferralPartner,
  ReferralPartnerFilters,
  Referral,
} from '@/types/referralpartner'
import type { MarketingPr, MarketingPrFilters } from '@/types/marketingpr'
import type {
  CreateMarketingPostInput,
  UpdateMarketingPostInput,
  SubmitPostUrlInput,
} from '@/schemas/marketingpost'
import type {
  CreateReferralPartnerInput,
  UpdateReferralPartnerInput,
} from '@/schemas/referralpartner'
import type {
  CreateMarketingPrInput,
  UpdateMarketingPrInput,
} from '@/schemas/marketingpr'

const MARKETING = '/marketing'
const DEFAULT_LIMIT = 15

interface ListResponse<T> { data: T[] }

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

// ─── POSTS ────────────────────────────────────────────────────────────────────

export function useMarketingPosts(filters: MarketingPostFilters = {}) {
  const limit = filters.limit ?? DEFAULT_LIMIT
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.platform) params.platform = filters.platform
  if (filters.status) params.status = filters.status
  if (filters.month) params.month = filters.month
  return useQuery({
    queryKey: ['marketing-posts', 'list', params],
    queryFn: () =>
      apiClient
        .get<ListResponse<MarketingPost>>(`${MARKETING}/posts`, { params })
        .then((r) => r.data.data ?? []),
  })
}

export function useMarketingPost(id: string | undefined) {
  return useQuery({
    queryKey: ['marketing-posts', 'detail', id],
    queryFn: () =>
      apiClient
        .get<ListResponse<MarketingPost>>(`${MARKETING}/posts`, { params: { limit: 500 } })
        .then((r) => (r.data.data ?? []).find((p) => p.id === id) ?? null),
    enabled: !!id,
  })
}

export function useCreateMarketingPost() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateMarketingPostInput) =>
      apiClient.post(`${MARKETING}/posts`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['marketing-posts'] }),
  })
}

export function useUpdateMarketingPost(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateMarketingPostInput) =>
      apiClient.put(`${MARKETING}/posts/${id}`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['marketing-posts'] }),
  })
}

export function useSubmitMarketingPostUrl(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: SubmitPostUrlInput) =>
      apiClient.put(`${MARKETING}/posts/${id}/submit-url`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['marketing-posts'] }),
  })
}

export function useDeleteMarketingPost() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${MARKETING}/posts/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['marketing-posts'] }),
  })
}

// ─── CLASS DOCS ───────────────────────────────────────────────────────────────

export function useClassDocPosts(filters: ClassDocPostFilters = {}) {
  const limit = filters.limit ?? DEFAULT_LIMIT
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.status) params.status = filters.status
  return useQuery({
    queryKey: ['class-docs', 'list', params],
    queryFn: () =>
      apiClient
        .get<ListResponse<ClassDocPost>>(`${MARKETING}/class-docs`, { params })
        .then((r) => r.data.data ?? []),
  })
}

// ─── REFERRAL PARTNERS ────────────────────────────────────────────────────────

export function useReferralPartners(filters: ReferralPartnerFilters = {}) {
  const limit = filters.limit ?? DEFAULT_LIMIT
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.is_active !== undefined) params.is_active = filters.is_active
  return useQuery({
    queryKey: ['referral-partners', 'list', params],
    queryFn: () =>
      apiClient
        .get<ListResponse<ReferralPartner>>(`${MARKETING}/referral-partners`, { params })
        .then((r) => r.data.data ?? []),
  })
}

export function useCreateReferralPartner() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateReferralPartnerInput) =>
      apiClient.post(`${MARKETING}/referral-partners`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['referral-partners'] }),
  })
}

export function useUpdateReferralPartner(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateReferralPartnerInput) =>
      apiClient.put(`${MARKETING}/referral-partners/${id}`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['referral-partners'] }),
  })
}

export function useReferrals(partnerId: string | undefined) {
  return useQuery({
    queryKey: ['referral-partners', partnerId, 'referrals'],
    queryFn: () =>
      apiClient
        .get<ListResponse<Referral>>(`${MARKETING}/referral-partners/${partnerId}/referrals`)
        .then((r) => r.data.data ?? []),
    enabled: !!partnerId,
  })
}

// ─── PR ───────────────────────────────────────────────────────────────────────

export function useMarketingPrDetail(id: string | undefined) {
  return useQuery({
    queryKey: ['marketing-pr', 'detail', id],
    queryFn: () =>
      apiClient
        .get<ListResponse<MarketingPr>>(`${MARKETING}/pr`, { params: { limit: 500 } })
        .then((r) => (r.data.data ?? []).find((p) => p.id === id) ?? null),
    enabled: !!id,
  })
}

export function useMarketingPr(filters: MarketingPrFilters = {}) {
  const limit = filters.limit ?? DEFAULT_LIMIT
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.status) params.status = filters.status
  if (filters.type) params.type = filters.type
  return useQuery({
    queryKey: ['marketing-pr', 'list', params],
    queryFn: () =>
      apiClient
        .get<ListResponse<MarketingPr>>(`${MARKETING}/pr`, { params })
        .then((r) => r.data.data ?? []),
  })
}

export function useCreateMarketingPr() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateMarketingPrInput) =>
      apiClient.post(`${MARKETING}/pr`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['marketing-pr'] }),
  })
}

export function useUpdateMarketingPr(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateMarketingPrInput) =>
      apiClient.put(`${MARKETING}/pr/${id}`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['marketing-pr'] }),
  })
}

export function useDeleteMarketingPr() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${MARKETING}/pr/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['marketing-pr'] }),
  })
}
