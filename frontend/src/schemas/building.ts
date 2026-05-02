import { z } from 'zod'

export const buildingSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(200),
  address: z.string().max(500).default(''),
  description: z.string().max(1000).default(''),
})

export const createBuildingSchema = buildingSchema
export const updateBuildingSchema = buildingSchema

export type CreateBuildingInput = z.infer<typeof createBuildingSchema>
export type UpdateBuildingInput = z.infer<typeof updateBuildingSchema>
