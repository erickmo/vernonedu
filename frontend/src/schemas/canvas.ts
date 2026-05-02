import { z } from 'zod'

export const canvasSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(200),
})

export const createCanvasSchema = canvasSchema
export const updateCanvasSchema = canvasSchema

export type CreateCanvasInput = z.infer<typeof createCanvasSchema>
export type UpdateCanvasInput = z.infer<typeof updateCanvasSchema>
