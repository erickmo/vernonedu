import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  Partner,
  PartnerFilters,
  PaginatedPartners,
  PartnerGroup,
} from '@/types/partner'
import type { ExpiringMou, Mou } from '@/types/mou'
import type { CreatePartnerInput, UpdatePartnerInput, PartnerGroupInput } from '@/schemas/partner'
import type { CreateMouInput, UpdateMouInput } from '@/schemas/mou'

const PARTNERS = '/partners'
const PARTNER_GROUPS = '/partner-groups'
const MOUS = '/mous'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface SingleResponse<T> { data: T }
interface ListResponse<T> { data: T[] }

// ── Partners ─────────────────────────────────────────────────────────────

export function usePartners(filters: PartnerFilters = {}) {
  const limit = filters.limit ?? 15
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.type) params.type = filters.type
  if (filters.status) params.status = filters.status
  if (filters.search) params.search = filters.search
  return useQuery({
    queryKey: ['partners', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedPartners>(PARTNERS, { params }).then((r) => r.data),
  })
}

export function usePartner(id: string | undefined) {
  return useQuery({
    queryKey: ['partners', id],
    queryFn: () =>
      apiClient.get<SingleResponse<Partner>>(`${PARTNERS}/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreatePartner() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreatePartnerInput) =>
      apiClient.post(PARTNERS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['partners', 'list'] }),
  })
}

export function useUpdatePartner(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdatePartnerInput) =>
      apiClient.put(`${PARTNERS}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['partners', 'list'] })
      qc.invalidateQueries({ queryKey: ['partners', id] })
    },
  })
}

export function useDeletePartner() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${PARTNERS}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['partners', 'list'] }),
  })
}

// ── Partner Groups ───────────────────────────────────────────────────────

export function usePartnerGroups() {
  return useQuery({
    queryKey: ['partner-groups', 'list'],
    queryFn: () =>
      apiClient.get<ListResponse<PartnerGroup>>(PARTNER_GROUPS).then((r) => r.data.data ?? []),
  })
}

export function useCreatePartnerGroup() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: PartnerGroupInput) =>
      apiClient.post(PARTNER_GROUPS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['partner-groups', 'list'] }),
  })
}

export function useUpdatePartnerGroup(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: PartnerGroupInput) =>
      apiClient.put(`${PARTNER_GROUPS}/${id}`, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['partner-groups', 'list'] }),
  })
}

// ── MOUs ─────────────────────────────────────────────────────────────────

export function usePartnerMous(partnerId: string | undefined) {
  return useQuery({
    queryKey: ['partners', partnerId, 'mous'],
    queryFn: () =>
      apiClient
        .get<ListResponse<Mou>>(`${PARTNERS}/${partnerId}/mous`)
        .then((r) => r.data.data ?? []),
    enabled: !!partnerId,
  })
}

export function useCreateMou(partnerId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateMouInput) =>
      apiClient.post(`${PARTNERS}/${partnerId}/mous`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['partners', partnerId, 'mous'] })
      qc.invalidateQueries({ queryKey: ['mous', 'expiring'] })
    },
  })
}

export function useUpdateMou(partnerId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (args: { mouId: string; input: UpdateMouInput }) =>
      apiClient.put(`${MOUS}/${args.mouId}`, args.input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['partners', partnerId, 'mous'] })
      qc.invalidateQueries({ queryKey: ['mous', 'expiring'] })
    },
  })
}

export function useDeleteMou(partnerId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (mouId: string) =>
      apiClient.delete(`${MOUS}/${mouId}`).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['partners', partnerId, 'mous'] })
      qc.invalidateQueries({ queryKey: ['mous', 'expiring'] })
    },
  })
}

export function useExpiringMous() {
  return useQuery({
    queryKey: ['mous', 'expiring'],
    queryFn: () =>
      apiClient
        .get<ListResponse<ExpiringMou>>(`${MOUS}/expiring`)
        .then((r) => r.data.data ?? []),
  })
}
