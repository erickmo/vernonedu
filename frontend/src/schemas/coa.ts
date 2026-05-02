import { z } from 'zod'
import { COA_ACCOUNT_TYPES } from '@/types/coa'

const COA_CODE_REGEX = /^[0-9]{3,8}(-[0-9]{1,4})?$/

export const createCoaSchema = z.object({
  code: z
    .string()
    .min(3, 'Code minimal 3 digit')
    .max(20)
    .regex(COA_CODE_REGEX, 'Format code: 3-8 digit, optional -suffix'),
  name: z.string().min(2, 'Name minimal 2 karakter').max(120),
  type: z.enum(COA_ACCOUNT_TYPES),
  parent_id: z.string().uuid('parent_id harus UUID').optional().or(z.literal('')),
  branch_id: z.string().uuid('branch_id harus UUID').optional().or(z.literal('')),
})

export const updateCoaSchema = z.object({
  name: z.string().min(2, 'Name minimal 2 karakter').max(120),
  is_active: z.boolean(),
})

export type CreateCoaInput = z.infer<typeof createCoaSchema>
export type UpdateCoaInput = z.infer<typeof updateCoaSchema>
