import { z } from 'zod'

export const COMMISSION_BASIS = ['profit', 'revenue'] as const

const pct = z.number().min(0, 'Min 0').max(100, 'Max 100')

export const updateCommissionConfigSchema = z.object({
  op_leader_pct: pct,
  op_leader_basis: z.enum(COMMISSION_BASIS),
  dept_leader_pct: pct,
  dept_leader_basis: z.enum(COMMISSION_BASIS),
  course_creator_pct: pct,
  course_creator_basis: z.enum(COMMISSION_BASIS),
})

export type UpdateCommissionConfigInput = z.infer<typeof updateCommissionConfigSchema>
