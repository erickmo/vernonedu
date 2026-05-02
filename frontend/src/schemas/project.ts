import { z } from 'zod'
import { PROJECT_STATUSES } from '@/types/project'

const dateString = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal: YYYY-MM-DD')

export const projectSchema = z
  .object({
    code: z.string().min(1, 'Code wajib').max(20),
    name: z.string().min(1, 'Name wajib').max(200),
    description: z.string().max(2000).default(''),
    status: z.enum(PROJECT_STATUSES).default('planning'),
    start_date: dateString,
    end_date: dateString,
    partner_id: z.string().uuid().optional().nullable(),
    branch_id: z.string().uuid().optional().nullable(),
    budget: z.coerce.number().nonnegative('Budget tidak boleh negatif').default(0),
    earning: z.coerce.number().nonnegative('Earning tidak boleh negatif').default(0),
  })
  .refine((v) => v.end_date >= v.start_date, {
    message: 'End date harus setelah start date',
    path: ['end_date'],
  })

export const createProjectSchema = projectSchema
export const updateProjectSchema = projectSchema

export type CreateProjectInput = z.infer<typeof createProjectSchema>
export type UpdateProjectInput = z.infer<typeof updateProjectSchema>
