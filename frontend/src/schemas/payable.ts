import { z } from 'zod'
import { PAYABLE_TYPES } from '@/types/payable'

export const createPayableSchema = z.object({
  type: z.enum(PAYABLE_TYPES),
  recipient_id: z.string().uuid('recipient_id harus UUID'),
  recipient_name: z.string().min(2, 'Recipient name minimal 2 karakter').max(120),
  batch_id: z.string().uuid().optional().or(z.literal('')),
  branch_id: z.string().uuid().optional().or(z.literal('')),
  amount: z.number().int().positive('Amount harus > 0'),
  notes: z.string().max(1000).optional().default(''),
})

export const payPayableSchema = z.object({
  payment_proof: z.string().max(500).optional().default(''),
  account_code: z.string().max(50).optional().default(''),
})

export type CreatePayableInput = z.infer<typeof createPayableSchema>
export type PayPayableInput = z.infer<typeof payPayableSchema>
