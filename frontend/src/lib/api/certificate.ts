import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { CertificateTemplate } from '@/types/certificatetemplate'
import type {
  CreateCertificateTemplateInput,
  UpdateCertificateTemplateInput,
} from '@/schemas/certificatetemplate'

const BASE = '/certificate-templates'

interface CreatePayload {
  name: string
  type: string
  template_data: Record<string, unknown>
}

function toPayload(input: CreateCertificateTemplateInput | UpdateCertificateTemplateInput): CreatePayload {
  return {
    name: input.name,
    type: input.type,
    template_data: JSON.parse(input.template_data) as Record<string, unknown>,
  }
}

export function useCertificateTemplates() {
  return useQuery({
    queryKey: ['certificatetemplates', 'list'],
    queryFn: async () => {
      const r = await apiClient.get<CertificateTemplate[] | { data: CertificateTemplate[] }>(BASE)
      const body = r.data as any
      return (Array.isArray(body) ? body : body?.data ?? []) as CertificateTemplate[]
    },
  })
}

export function useCreateCertificateTemplate() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCertificateTemplateInput) =>
      apiClient.post<CertificateTemplate>(BASE, toPayload(input)).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['certificatetemplates', 'list'] }),
  })
}

export function useUpdateCertificateTemplate(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateCertificateTemplateInput) =>
      apiClient.put<CertificateTemplate>(`${BASE}/${id}`, toPayload(input)).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['certificatetemplates', 'list'] }),
  })
}
