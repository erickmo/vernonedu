import { z } from 'zod'
import { PAYMENT_METHODS } from './coursebatch'
import { ENROLLMENT_STATUSES, ENROLLMENT_PAYMENT_STATUSES } from '@/types/enrollment'

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/

// Create — backend accepts only student_id + course_batch_id, but the form
// also collects enrollment_date and payment_method for display/finance hooks.
export const createEnrollmentSchema = z.object({
  student_id: z.string().uuid('student_id wajib UUID'),
  course_batch_id: z.string().uuid('course_batch_id wajib UUID'),
  enrollment_date: z.string().regex(ISO_DATE, 'Format: YYYY-MM-DD'),
  payment_method: z.enum(PAYMENT_METHODS),
  voucher_code: z.string().max(64).optional().or(z.literal('')),
})

// Edit — backend only exposes status + payment_status updates.
export const updateEnrollmentSchema = z.object({
  status: z.enum(ENROLLMENT_STATUSES as [string, ...string[]]),
  payment_status: z.enum(ENROLLMENT_PAYMENT_STATUSES as [string, ...string[]]),
})

export type CreateEnrollmentInput = z.infer<typeof createEnrollmentSchema>
export type UpdateEnrollmentInput = z.infer<typeof updateEnrollmentSchema>
