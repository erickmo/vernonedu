import { z } from 'zod'

export const createTransactionSchema = z
  .object({
    description: z.string().min(3, 'Description minimal 3 karakter').max(500),
    account_debit_id: z.string().uuid('account_debit_id harus UUID'),
    account_credit_id: z.string().uuid('account_credit_id harus UUID'),
    amount: z.number().positive('Amount harus > 0'),
    reference: z.string().max(120).optional().default(''),
    branch_id: z.string().uuid('branch_id harus UUID'),
    attachment_url: z.string().url('attachment_url tidak valid').optional().or(z.literal('')),
  })
  .refine((d) => d.account_debit_id !== d.account_credit_id, {
    message: 'Debit dan credit account harus berbeda',
    path: ['account_credit_id'],
  })

export type CreateTransactionInput = z.infer<typeof createTransactionSchema>
