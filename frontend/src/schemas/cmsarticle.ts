import { z } from 'zod'
import { ARTICLE_STATUSES } from '@/types/cmsarticle'

export const createCmsArticleSchema = z.object({
  title: z.string().min(1, 'Title wajib').max(200),
  category: z.string().min(1, 'Category wajib').max(100),
  content: z.string().min(1, 'Content wajib'),
  featured_image_url: z.string().max(500).optional().default(''),
  status: z.enum(ARTICLE_STATUSES as unknown as [string, ...string[]]),
})

export const updateCmsArticleSchema = createCmsArticleSchema.extend({
  slug: z.string().max(200).optional().default(''),
})

export type CreateCmsArticleInput = z.infer<typeof createCmsArticleSchema>
export type UpdateCmsArticleInput = z.infer<typeof updateCmsArticleSchema>
