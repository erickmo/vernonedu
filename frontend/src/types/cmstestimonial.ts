export interface CmsTestimonial {
  id: string
  student_name: string
  course_id: string
  quote: string
  rating: number
  photo_url: string
  is_featured: boolean
  created_at: string
  updated_at: string
}

export interface CmsTestimonialFilters {
  course_id?: string
  is_featured?: boolean
}
