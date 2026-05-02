import { z } from 'zod'

export const createItemSchema = z.object({
  business_id: z.string().uuid('Business id wajib UUID'),
  canvas_type: z.string().min(1, 'Canvas type wajib').max(50),
  section_id: z.string().min(1, 'Section wajib').max(100),
  text: z.string().min(1, 'Text wajib').max(2000),
  note: z.string().max(2000).default(''),
})

export const updateItemSchema = z.object({
  text: z.string().min(1, 'Text wajib').max(2000),
  note: z.string().max(2000).default(''),
})

export type CreateItemInput = z.infer<typeof createItemSchema>
export type UpdateItemInput = z.infer<typeof updateItemSchema>
