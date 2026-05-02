import { z } from 'zod'

export const createCmsFaqSchema = z.object({
  question: z.string().min(1, 'Question wajib').max(500),
  answer: z.string().min(1, 'Answer wajib').max(5000),
  category: z.string().max(100).optional().default(''),
  page_slugs: z.array(z.string().max(200)).optional().default([]),
  sort_order: z.number().int().min(0).optional().default(0),
})

export const updateCmsFaqSchema = createCmsFaqSchema

export type CreateCmsFaqInput = z.infer<typeof createCmsFaqSchema>
export type UpdateCmsFaqInput = z.infer<typeof updateCmsFaqSchema>
