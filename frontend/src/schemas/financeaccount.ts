import { z } from 'zod'
import { COA_ACCOUNT_TYPES } from '@/types/coa'
import { FINANCE_ACCOUNT_KINDS } from '@/types/financeaccount'

export const createFinanceAccountSchema = z.object({
  code: z.string().min(3, 'Code minimal 3 digit').max(20),
  name: z.string().min(2, 'Name minimal 2 karakter').max(120),
  type: z.enum(COA_ACCOUNT_TYPES).default('asset'),
  kind: z.enum(FINANCE_ACCOUNT_KINDS).optional(),
  parent_id: z.string().uuid().optional().or(z.literal('')),
  branch_id: z.string().uuid().optional().or(z.literal('')),
})

export const updateFinanceAccountSchema = z.object({
  name: z.string().min(2).max(120),
  is_active: z.boolean(),
})

export type CreateFinanceAccountInput = z.infer<typeof createFinanceAccountSchema>
export type UpdateFinanceAccountInput = z.infer<typeof updateFinanceAccountSchema>
