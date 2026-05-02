import { z } from 'zod'

export const designThinkingSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(200),
})

export const createDesignThinkingSchema = designThinkingSchema
export const updateDesignThinkingSchema = designThinkingSchema

export type CreateDesignThinkingInput = z.infer<typeof createDesignThinkingSchema>
export type UpdateDesignThinkingInput = z.infer<typeof updateDesignThinkingSchema>
