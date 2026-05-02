import { z } from 'zod'

export const TALENTPOOL_STAGES = [
  'learning',
  'internship',
  'recommendation',
  'test',
  'talentpool',
  'placed',
  'inactive',
] as const

export const placementRecordSchema = z.object({
  company_name: z.string().min(1, 'Company wajib').max(200),
  position: z.string().min(1, 'Position wajib').max(200),
  notes: z.string().max(1000).default(''),
})

export const updateTalentPoolStatusSchema = z.object({
  status: z.enum(TALENTPOOL_STAGES),
  placement: placementRecordSchema.optional(),
})

export type UpdateTalentPoolStatusInput = z.infer<typeof updateTalentPoolStatusSchema>
export type PlacementRecordInput = z.infer<typeof placementRecordSchema>
