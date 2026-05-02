import { z } from 'zod'

export const updateCmsPageSchema = z.object({
  title: z.string().min(1, 'Title wajib').max(200),
  subtitle: z.string().max(500).optional().default(''),
  content: z.record(z.unknown()).optional().default({}),
  hero_image_url: z.string().max(500).optional().default(''),
  seo: z.record(z.unknown()).optional().default({}),
})

export type UpdateCmsPageInput = z.infer<typeof updateCmsPageSchema>
