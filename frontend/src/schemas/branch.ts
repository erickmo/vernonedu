import { z } from 'zod'

export const branchSchema = z.object({
  code: z.string().min(1, 'Code wajib').max(20),
  name: z.string().min(1, 'Name wajib').max(200),
  address: z.string().max(500).default(''),
  city: z.string().max(100).default(''),
  province: z.string().max(100).default(''),
  phone: z.string().max(30).default(''),
  email: z.union([z.literal(''), z.string().email('Email tidak valid')]).default(''),
  is_active: z.boolean().default(true),
})

export const createBranchSchema = branchSchema
export const updateBranchSchema = branchSchema

export type CreateBranchInput = z.infer<typeof createBranchSchema>
export type UpdateBranchInput = z.infer<typeof updateBranchSchema>
