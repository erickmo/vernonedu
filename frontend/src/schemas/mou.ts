import { z } from 'zod'
import { MOU_STATUSES } from '@/types/mou'

const dateString = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal: YYYY-MM-DD')

export const mouSchema = z
  .object({
    title: z.string().min(1, 'Title wajib').max(200),
    description: z.string().max(2000).default(''),
    start_date: dateString,
    end_date: dateString,
    document_url: z.union([z.literal(''), z.string().url('URL tidak valid')]).default(''),
    status: z.enum(MOU_STATUSES).default('draft'),
  })
  .refine((v) => v.end_date >= v.start_date, {
    message: 'End date harus setelah start date',
    path: ['end_date'],
  })

export const createMouSchema = mouSchema
export const updateMouSchema = mouSchema

export type CreateMouInput = z.infer<typeof createMouSchema>
export type UpdateMouInput = z.infer<typeof updateMouSchema>
