import { z } from 'zod'

export const CERT_TYPES = ['participant', 'competency'] as const
export type CertType = typeof CERT_TYPES[number]

const jsonObjectString = z
  .string()
  .min(1, 'Template data wajib')
  .refine((s) => {
    try {
      const parsed = JSON.parse(s)
      return typeof parsed === 'object' && parsed !== null && !Array.isArray(parsed)
    } catch {
      return false
    }
  }, 'Invalid JSON object')

export const createCertificateTemplateSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(200),
  type: z.enum(CERT_TYPES),
  template_data: jsonObjectString,
})

export const updateCertificateTemplateSchema = createCertificateTemplateSchema

export type CreateCertificateTemplateInput = z.infer<typeof createCertificateTemplateSchema>
export type UpdateCertificateTemplateInput = z.infer<typeof updateCertificateTemplateSchema>
