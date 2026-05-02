import { z } from 'zod'

export const TEST_TYPES = ['DISC', 'MBTI', 'Big5', 'Custom'] as const

export const upsertCharacterTestConfigSchema = z.object({
  test_type: z.string().min(1, 'Test type wajib').max(100),
  test_provider: z.string().max(200).default(''),
  passing_threshold: z.number().min(0, 'Min 0').max(100, 'Max 100'),
  talentpool_eligible: z.boolean().default(false),
})

export type UpsertCharacterTestConfigInput = z.infer<typeof upsertCharacterTestConfigSchema>
