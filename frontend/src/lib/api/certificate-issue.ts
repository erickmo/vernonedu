import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { Certificate } from '@/types/certificate'
import type { IssueCertificateInput, RevokeCertificateInput } from '@/schemas/certificate'

const BASE = '/certificates'

export interface CertificateListFilters {
  student_id?: string
  batch_id?: string
  type?: string
  status?: string
  offset?: number
  limit?: number
}

function unwrapList(body: unknown): Certificate[] {
  if (Array.isArray(body)) return body as Certificate[]
  const wrapped = body as { data?: Certificate[] | { items?: Certificate[] } }
  if (Array.isArray(wrapped?.data)) return wrapped.data as Certificate[]
  const inner = wrapped?.data as { items?: Certificate[] } | undefined
  if (inner && Array.isArray(inner.items)) return inner.items
  return []
}

export function useCertificates(filters: CertificateListFilters = {}) {
  const params = new URLSearchParams()
  Object.entries(filters).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') params.set(k, String(v))
  })
  const qs = params.toString()
  return useQuery({
    queryKey: ['certificates', 'list', filters],
    queryFn: async () => {
      const r = await apiClient.get(`${BASE}${qs ? `?${qs}` : ''}`)
      return unwrapList(r.data)
    },
  })
}

export function useCertificate(id: string | undefined) {
  return useQuery({
    queryKey: ['certificates', 'detail', id],
    queryFn: async () => {
      const r = await apiClient.get<{ data: Certificate } | Certificate>(`${BASE}/${id}`)
      const body = r.data as any
      return (body?.data ?? body) as Certificate
    },
    enabled: !!id,
  })
}

export function useIssueCertificate() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: IssueCertificateInput) =>
      apiClient.post(BASE, {
        template_id: input.template_id,
        student_id: input.student_id,
        batch_id: input.batch_id,
        course_id: input.course_id,
        type: input.type,
        verification_base_url: input.verification_base_url || undefined,
      }).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['certificates'] }),
  })
}

export function useRevokeCertificate(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: RevokeCertificateInput) =>
      apiClient.post(`${BASE}/${id}/revoke`, { reason: input.reason }).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['certificates'] })
    },
  })
}
