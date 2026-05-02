import { z } from 'zod'

export const TYPE_NAMES = [
  'Reguler', 'Privat', 'Program Karir', 'Inhouse', 'Kolaborasi Sekolah/Univ',
] as const

export const PRICE_TYPES = ['one-time', 'monthly', 'per-session'] as const
export const CURRENCIES = ['IDR'] as const

export const createCourseTypeSchema = z.object({
  type_name: z.string().min(1, 'Type name wajib').max(100),
  price_type: z.enum(PRICE_TYPES).default('one-time'),
  price_currency: z.enum(CURRENCIES).default('IDR'),
  target_audience: z.string().max(500).default(''),
  certification_type: z.string().max(200).default(''),
  extra_docs: z.array(z.string().min(1)).default([]),
  normal_price: z.number().int().nonnegative(),
  min_price: z.number().int().nonnegative(),
  min_participants: z.number().int().positive(),
  max_participants: z.number().int().positive(),
}).refine((d) => d.min_price <= d.normal_price, {
  message: 'Min price harus ≤ Normal price',
  path: ['min_price'],
}).refine((d) => d.min_participants <= d.max_participants, {
  message: 'Min participants harus ≤ Max participants',
  path: ['min_participants'],
})

export const updateCourseTypeSchema = createCourseTypeSchema
export type CreateCourseTypeInput = z.infer<typeof createCourseTypeSchema>
export type UpdateCourseTypeInput = CreateCourseTypeInput
