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
  ref_module_id: z.string().uuid().nullable().optional(),
}).refine(
  (d) => !d.is_reference || (typeof d.ref_module_id === 'string' && d.ref_module_id.length > 0),
  { message: 'Reference module wajib dipilih', path: ['ref_module_id'] },
)

export const updateCourseModuleSchema = z.object({
  module_title: z.string().min(1, 'Module title wajib').max(200),
  duration_hours: z.number().nonnegative().default(0),
  sequence: z.number().int().positive(),
  content_depth: z.string().max(2000).default(''),
  topics: z.array(z.string().min(1)).default([]),
  practical_activities: z.array(z.string().min(1)).default([]),
  assessment_method: z.string().max(500).default(''),
  tools_required: z.array(z.string().min(1)).default([]),
  requirements: z.array(z.string().min(1)).default([]),
})

export type CreateCourseModuleInput = z.infer<typeof createCourseModuleSchema>
export type UpdateCourseModuleInput = z.infer<typeof updateCourseModuleSchema>
