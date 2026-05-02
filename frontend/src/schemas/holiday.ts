import { z } from 'zod'

const ISO_DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/

export const createHolidaySchema = z.object({
  date: z
    .string()
    .min(1, 'Date is required')
    .regex(ISO_DATE_REGEX, 'Date must be in YYYY-MM-DD format')
    .refine((v) => !Number.isNaN(new Date(v).getTime()), 'Invalid calendar date'),
  name: z
    .string()
    .min(1, 'Name is required')
    .max(120, 'Name must be 120 characters or fewer'),
})

export type CreateHolidayInput = z.infer<typeof createHolidaySchema>
