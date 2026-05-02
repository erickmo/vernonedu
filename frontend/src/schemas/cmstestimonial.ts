import { z } from 'zod'

export const createCmsTestimonialSchema = z.object({
  student_name: z.string().min(1, 'Student name wajib').max(200),
  course_id: z.string().max(100).optional().default(''),
  quote: z.string().min(1, 'Quote wajib').max(2000),
  rating: z.number().int().min(1, 'Min rating 1').max(5, 'Max rating 5'),
  photo_url: z.string().max(500).optional().default(''),
  is_featured: z.boolean().optional().default(false),
})

export const updateCmsTestimonialSchema = createCmsTestimonialSchema

export type CreateCmsTestimonialInput = z.infer<typeof createCmsTestimonialSchema>
export type UpdateCmsTestimonialInput = z.infer<typeof updateCmsTestimonialSchema>
