import { z } from 'zod'

const LEVELS = ['company', 'department', 'team', 'individual'] as const
const STATUSES = ['draft', 'active', 'completed', 'archived'] as const

export const createObjectiveSchema = z.object({
  title: z.string().min(1, 'Title wajib').max(200),
  owner_id: z.string().min(1, 'Owner wajib'),
  owner_name: z.string().min(1).max(200),
  period: z.string().min(1, 'Period wajib').max(50),
  level: z.enum(LEVELS),
  status: z.enum(STATUSES).default('draft'),
})

export const createKeyResultSchema = z.object({
  objective_id: z.string().min(1),
  title: z.string().min(1, 'Title wajib').max(200),
  target: z.number().positive('Target harus > 0'),
  current: z.number().nonnegative().default(0),
  unit: z.string().max(50).optional(),
})

export const updateKeyResultProgressSchema = z.object({
  current: z.number().nonnegative(),
})

export type CreateObjectiveInput = z.infer<typeof createObjectiveSchema>
export type CreateKeyResultInput = z.infer<typeof createKeyResultSchema>
export type UpdateKeyResultProgressInput = z.infer<typeof updateKeyResultProgressSchema>
