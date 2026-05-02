import { z } from 'zod'

export const PAYMENT_METHODS = [
  'upfront',
  'scheduled',
  'monthly',
  'batch_lump',
  'per_session',
] as const

export const PAYMENT_METHOD_LABELS: Record<(typeof PAYMENT_METHODS)[number], string> = {
  upfront: 'Upfront (lunas di awal)',
  scheduled: 'Scheduled (cicilan terjadwal)',
  monthly: 'Monthly (bulanan)',
  batch_lump: 'Batch Lump (lunas per batch)',
  per_session: 'Per Session (per sesi hadir)',
}

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/

export const createCourseBatchSchema = z
  .object({
    course_id: z.string().uuid('course_id wajib UUID'),
    code: z.string().max(50).default(''),
    name: z.string().min(1, 'Name wajib').max(200),
    start_date: z.string().regex(ISO_DATE, 'Format: YYYY-MM-DD'),
    end_date: z.string().regex(ISO_DATE, 'Format: YYYY-MM-DD'),
    min_participants: z.number().int().nonnegative().default(0),
    max_participants: z.number().int().positive('Max participants harus > 0'),
    website_visible: z.boolean().default(true),
    is_active: z.boolean().default(true),
    price: z.number().int().nonnegative('Harga tidak boleh negatif'),
    payment_method: z.enum(PAYMENT_METHODS),
  })
  .refine((d) => d.start_date <= d.end_date, {
    message: 'Start date harus ≤ end date',
    path: ['start_date'],
  })
  .refine((d) => d.min_participants <= d.max_participants, {
    message: 'Min participants harus ≤ max',
    path: ['min_participants'],
  })

export const updateCourseBatchSchema = z
  .object({
    code: z.string().max(50).default(''),
    name: z.string().min(1, 'Name wajib').max(200),
    start_date: z.string().regex(ISO_DATE, 'Format: YYYY-MM-DD'),
    end_date: z.string().regex(ISO_DATE, 'Format: YYYY-MM-DD'),
    min_participants: z.number().int().nonnegative().default(0),
    max_participants: z.number().int().positive('Max participants harus > 0'),
    website_visible: z.boolean().default(true),
    is_active: z.boolean().default(true),
    price: z.number().int().nonnegative('Harga tidak boleh negatif'),
    payment_method: z.enum(PAYMENT_METHODS),
  })
  .refine((d) => d.start_date <= d.end_date, {
    message: 'Start date harus ≤ end date',
    path: ['start_date'],
  })
  .refine((d) => d.min_participants <= d.max_participants, {
    message: 'Min participants harus ≤ max',
    path: ['min_participants'],
  })

export const assignFacilitatorSchema = z.object({
  facilitator_id: z.string().uuid('Harus UUID valid'),
})

export type CreateCourseBatchInput = z.infer<typeof createCourseBatchSchema>
export type UpdateCourseBatchInput = z.infer<typeof updateCourseBatchSchema>
export type AssignFacilitatorInput = z.infer<typeof assignFacilitatorSchema>
