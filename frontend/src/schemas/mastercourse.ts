import { z } from 'zod'

export const FIELDS = ['Tech', 'Business', 'Design', 'Education', 'Other'] as const
export type Field = typeof FIELDS[number]

export const createMasterCourseSchema = z.object({
  course_code: z.string().min(1, 'Code wajib').max(20),
  course_name: z.string().min(1, 'Name wajib').max(200),
  field: z.enum(FIELDS),
  core_competencies: z.array(z.string().min(1)).default([]),
  description: z.string().max(2000).default(''),
  supporting_app_url: z.union([z.string().url(), z.literal('')]).optional(),
})

export const updateMasterCourseSchema = createMasterCourseSchema.partial()

export type CreateMasterCourseInput = z.infer<typeof createMasterCourseSchema>
export type UpdateMasterCourseInput = z.infer<typeof updateMasterCourseSchema>
