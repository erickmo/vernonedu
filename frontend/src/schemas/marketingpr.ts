import { z } from 'zod'
import { PR_TYPES, PR_STATUSES } from '@/types/marketingpr'

export const createMarketingPrSchema = z.object({
  title: z.string().min(1, 'Title wajib').max(200),
  type: z.enum(PR_TYPES as unknown as [string, ...string[]]),
  scheduled_at: z.string().min(1, 'Scheduled at wajib'),
  media_venue: z.string().max(200).optional().default(''),
  pic_id: z.string().uuid().nullable().optional(),
  pic_name: z.string().max(200).optional().default(''),
  notes: z.string().max(2000).optional().default(''),
})

export const updateMarketingPrSchema = createMarketingPrSchema.extend({
  status: z.enum(PR_STATUSES as unknown as [string, ...string[]]),
})

export type CreateMarketingPrInput = z.infer<typeof createMarketingPrSchema>
export type UpdateMarketingPrInput = z.infer<typeof updateMarketingPrSchema>
