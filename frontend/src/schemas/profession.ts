import { z } from 'zod'

export const professionSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(200),
  description: z.string().max(1000).default(''),
})

export type ProfessionInput = z.infer<typeof professionSchema>
