import { z } from 'zod'

export const upsertInternshipConfigSchema = z.object({
  partner_company_name: z.string().min(1, 'Partner wajib').max(200),
  partner_company_id: z.string().uuid().optional().or(z.literal('')),
  position_title: z.string().min(1, 'Position wajib').max(200),
  duration_weeks: z.number().int().positive(),
  supervisor_name: z.string().max(200).default(''),
  supervisor_contact: z.string().max(200).default(''),
  mou_document_url: z.string().url('URL tidak valid').or(z.literal('')).default(''),
  is_company_provided: z.boolean().default(false),
})

export type UpsertInternshipConfigInput = z.infer<typeof upsertInternshipConfigSchema>
