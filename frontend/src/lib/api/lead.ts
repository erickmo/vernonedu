import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { Lead, LeadFilters, PaginatedLeads } from '@/types/lead'
import type { CrmLog } from '@/types/crmlog'
import type { CreateLeadInput, UpdateLeadInput, AddCrmLogInput } from '@/schemas/lead'

const LEADS = '/leads'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface SingleResponse<T> { data: T }
interface ListResponse<T> { data: T[] }

export function useLeads(filters: LeadFilters = {}) {
  const limit = filters.limit ?? 15
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.status) params.status = filters.status
  if (filters.source) params.source = filters.source
  if (filters.interest) params.interest = filters.interest
  return useQuery({
    queryKey: ['leads', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedLeads>(LEADS, { params }).then((r) => r.data),
  })
}

export function useLead(id: string | undefined) {
  return useQuery({
    queryKey: ['leads', id],
    queryFn: () =>
      apiClient.get<SingleResponse<Lead>>(`${LEADS}/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateLead() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateLeadInput) =>
      apiClient.post(LEADS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['leads', 'list'] }),
  })
}

export function useUpdateLead(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateLeadInput) =>
      apiClient.put(`${LEADS}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['leads', 'list'] })
      qc.invalidateQueries({ queryKey: ['leads', id] })
    },
  })
}

export function useDeleteLead() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${LEADS}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['leads', 'list'] }),
  })
}

export function useConvertLead() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`${LEADS}/${id}/convert`).then((r) => r.data),
    onSuccess: (_d, id) => {
      qc.invalidateQueries({ queryKey: ['leads', 'list'] })
      qc.invalidateQueries({ queryKey: ['leads', id] })
      qc.invalidateQueries({ queryKey: ['students'] })
    },
  })
}

export function useCrmLogs(leadId: string | undefined) {
  return useQuery({
    queryKey: ['leads', leadId, 'crm-logs'],
    queryFn: () =>
      apiClient
        .get<ListResponse<CrmLog>>(`${LEADS}/${leadId}/crm-logs`)
        .then((r) => r.data.data ?? []),
    enabled: !!leadId,
  })
}

export function useAddCrmLog(leadId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: AddCrmLogInput) =>
      apiClient.post(`${LEADS}/${leadId}/crm-logs`, input).then((r) => r.data),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['leads', leadId, 'crm-logs'] }),
  })
}
