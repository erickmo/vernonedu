import { z } from 'zod'
import { LEAD_STATUSES } from '@/types/lead'
import { CONTACT_METHODS } from '@/types/crmlog'

const optionalEmail = z
  .string()
  .max(200)
  .optional()
  .default('')
  .refine(
    (v) => !v || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
    'Invalid email format',
  )

export const createLeadSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(200),
  email: optionalEmail,
  phone: z.string().max(50).optional().default(''),
  interest: z.string().max(200).optional().default(''),
  source: z.string().max(100).optional().default(''),
  notes: z.string().max(2000).optional().default(''),
  pic_id: z.string().uuid().nullable().optional(),
})

export const updateLeadSchema = createLeadSchema.extend({
  status: z.enum(LEAD_STATUSES as [string, ...string[]]),
})

export const addCrmLogSchema = z.object({
  contacted_by_id: z.string().uuid('Invalid user id'),
  contact_method: z.enum(CONTACT_METHODS as unknown as [string, ...string[]]),
  response: z.string().min(1, 'Response wajib').max(2000),
  follow_up_date: z.string().optional().nullable(),
})

export type CreateLeadInput = z.infer<typeof createLeadSchema>
export type UpdateLeadInput = z.infer<typeof updateLeadSchema>
export type AddCrmLogInput = z.infer<typeof addCrmLogSchema>
