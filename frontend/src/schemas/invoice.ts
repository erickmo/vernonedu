import { z } from 'zod'
import { INVOICE_STATUSES } from '@/types/invoice'

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/

export const invoiceLineItemSchema = z.object({
  description: z.string().min(1, 'Description wajib'),
  quantity: z.number().int().positive('Quantity > 0'),
  unit_price: z.number().nonnegative('Unit price tidak boleh negatif'),
  total: z.number().nonnegative(),
})

export const createInvoiceSchema = z
  .object({
    student_id: z.string().uuid('student_id harus UUID').optional().or(z.literal('')),
    course_batch_id: z
      .string()
      .uuid('course_batch_id harus UUID')
      .optional()
      .or(z.literal('')),
    amount: z.number().int().nonnegative('Amount tidak boleh negatif'),
    due_date: z.string().regex(ISO_DATE, 'Format: YYYY-MM-DD'),
    items: z.array(invoiceLineItemSchema).optional().default([]),
    notes: z.string().max(1000).optional().default(''),
  })
  .refine((d) => !!d.student_id || !!d.course_batch_id, {
    message: 'Minimal satu dari student_id atau course_batch_id wajib diisi',
    path: ['student_id'],
  })

export const invoiceStatusSchema = z.enum(INVOICE_STATUSES)

export type CreateInvoiceInput = z.infer<typeof createInvoiceSchema>
export type InvoiceLineItemInput = z.infer<typeof invoiceLineItemSchema>
