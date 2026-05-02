export type CertificateTemplateType = 'participant' | 'competency'

export interface CertificateTemplate {
  id: string
  name: string
  type: CertificateTemplateType
  template_data: Record<string, unknown>
  created_at: string
  updated_at: string
}
