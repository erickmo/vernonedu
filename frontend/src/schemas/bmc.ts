import { z } from 'zod'

const BMC_KEYS = [
  'key_partners', 'key_activities', 'key_resources', 'value_propositions',
  'customer_relationships', 'channels', 'customer_segments',
  'cost_structure', 'revenue_streams',
] as const

const MAX_CONTENT = 5000

export const bmcComponentSchema = z.object({
  key: z.enum(BMC_KEYS),
  label: z.string().min(1).max(100),
  content: z.string().max(MAX_CONTENT).default(''),
  partner_count: z.number().int().nonnegative().optional(),
})

export const updateBMCSchema = z.object({
  components: z.array(bmcComponentSchema).length(9, 'BMC harus memiliki 9 komponen'),
})

export type UpdateBMCInput = z.infer<typeof updateBMCSchema>
export type BMCComponentInput = z.infer<typeof bmcComponentSchema>
