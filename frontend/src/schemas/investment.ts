import { z } from 'zod'

const STATUSES = ['proposed', 'approved', 'rejected', 'in_progress', 'completed'] as const

export const investmentSchema = z.object({
  title: z.string().min(1, 'Title wajib').max(200),
  category: z.string().min(1, 'Category wajib').max(100),
  proposed_by: z.string().min(1, 'Proposed by wajib').max(200),
  amount: z.number().positive('Amount harus > 0'),
  expected_roi: z.number().min(0, 'ROI tidak boleh negatif').max(10000),
  status: z.enum(STATUSES).default('proposed'),
  notes: z.string().max(2000).default(''),
})

export const createInvestmentSchema = investmentSchema
export const updateInvestmentSchema = investmentSchema.partial().extend({
  title: z.string().min(1).max(200),
})

export type CreateInvestmentInput = z.infer<typeof createInvestmentSchema>
export type UpdateInvestmentInput = z.infer<typeof updateInvestmentSchema>
