import { z } from 'zod'
import { POST_PLATFORMS, POST_CONTENT_TYPES, POST_STATUSES } from '@/types/marketingpost'

export const createMarketingPostSchema = z.object({
  platforms: z
    .array(z.enum(POST_PLATFORMS as unknown as [string, ...string[]]))
    .min(1, 'Min 1 platform'),
  scheduled_at: z.string().min(1, 'Scheduled at wajib'),
  content_type: z.enum(POST_CONTENT_TYPES as unknown as [string, ...string[]]),
  caption: z.string().min(1, 'Caption wajib').max(5000),
  media_url: z.string().max(1000).optional().default(''),
  batch_id: z.string().uuid().nullable().optional(),
})

export const updateMarketingPostSchema = createMarketingPostSchema.extend({
  status: z.enum(POST_STATUSES as unknown as [string, ...string[]]),
})

export const submitPostUrlSchema = z.object({
  post_url: z.string().min(1, 'Post URL wajib').max(1000),
})

export type CreateMarketingPostInput = z.infer<typeof createMarketingPostSchema>
export type UpdateMarketingPostInput = z.infer<typeof updateMarketingPostSchema>
export type SubmitPostUrlInput = z.infer<typeof submitPostUrlSchema>
