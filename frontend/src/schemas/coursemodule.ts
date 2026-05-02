import { z } from 'zod'

export const createCourseModuleSchema = z.object({
  module_code: z.string().min(1, 'Module code wajib').max(50),
  module_title: z.string().min(1, 'Module title wajib').max(200),
  duration_hours: z.number().nonnegative().default(0),
  sequence: z.number().int().positive(),
  content_depth: z.string().max(2000).default(''),
  topics: z.array(z.string().min(1)).default([]),
  practical_activities: z.array(z.string().min(1)).default([]),
  assessment_method: z.string().max(500).default(''),
  tools_required: z.array(z.string().min(1)).default([]),
  requirements: z.array(z.string().min(1)).default([]),
  is_reference: z.boolean().default(false),
})

export const updateCourseModuleSchema = createCourseModuleSchema.omit({
  module_code: true,
  is_reference: true,
})

export type CreateCourseModuleInput = z.infer<typeof createCourseModuleSchema>
export type UpdateCourseModuleInput = z.infer<typeof updateCourseModuleSchema>
