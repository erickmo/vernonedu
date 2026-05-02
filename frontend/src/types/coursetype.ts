export type CourseTypeStatus = 'active' | 'inactive'

export interface CourseType {
  id: string
  master_course_id: string
  type_name: string
  price_type: string
  price_currency: string
  target_audience: string
  certification_type: string
  extra_docs: string[]
  normal_price: number
  min_price: number
  min_participants: number
  max_participants: number
  status: CourseTypeStatus
  created_at: string
  updated_at: string
}
