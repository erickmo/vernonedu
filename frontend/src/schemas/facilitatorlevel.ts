import { z } from 'zod'

export const facilitatorLevelSchema = z.object({
  level: z.number().int().min(1).max(20),
  name: z.string().min(1, 'Name wajib').max(100),
  fee_per_session: z.number().int().nonnegative('Fee tidak boleh negatif'),
})

export const upsertFacilitatorLevelsSchema = z.object({
  levels: z.array(facilitatorLevelSchema).min(1, 'Minimal 1 level'),
})

export type FacilitatorLevelInput = z.infer<typeof facilitatorLevelSchema>
export type UpsertFacilitatorLevelsInput = z.infer<typeof upsertFacilitatorLevelsSchema>
