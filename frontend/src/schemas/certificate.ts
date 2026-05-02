import { z } from 'zod'

export const CERTIFICATE_TYPES = ['participant', 'competency'] as const
export type CertificateTypeValue = typeof CERTIFICATE_TYPES[number]

export const CERTIFICATE_STATUSES = ['issued', 'revoked'] as const

export const issueCertificateSchema = z.object({
  template_id: z.string().min(1, 'Template wajib'),
  student_id: z.string().min(1, 'Student wajib'),
  batch_id: z.string().min(1, 'Batch wajib'),
  course_id: z.string().min(1, 'Course wajib'),
  type: z.enum(CERTIFICATE_TYPES),
  verification_base_url: z.string().url('Verification URL tidak valid').optional().or(z.literal('')),
  notes: z.string().max(1000).optional(),
})

export const revokeCertificateSchema = z.object({
  reason: z.string().min(3, 'Reason minimal 3 karakter').max(500),
})

export type IssueCertificateInput = z.infer<typeof issueCertificateSchema>
export type RevokeCertificateInput = z.infer<typeof revokeCertificateSchema>
