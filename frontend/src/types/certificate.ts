export type CertificateType = 'participant' | 'competency'
export type CertificateStatus = 'issued' | 'revoked'

export interface Certificate {
  id: string
  code: string
  template_id: string
  student_id: string
  batch_id: string
  course_id: string
  type: CertificateType
  status: CertificateStatus
  verification_url?: string
  notes?: string
  issued_at: string
  revoked_at?: string | null
  revoke_reason?: string | null
  created_at: string
  updated_at: string
  // Optional joined fields the API may include for list/detail views
  student_name?: string
  batch_name?: string
}
