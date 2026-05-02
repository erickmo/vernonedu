export type PaymentMethod =
  | 'upfront'
  | 'scheduled'
  | 'monthly'
  | 'batch_lump'
  | 'per_session'

export type CourseBatchStatus =
  | 'pending_approval'
  | 'active'
  | 'open'
  | 'ongoing'
  | 'completed'
  | 'cancelled'
  | 'draft'
  | 'full'

export interface CourseBatch {
  id: string
  course_id: string
  master_course_id?: string
  code: string
  name: string
  start_date: string
  end_date: string
  facilitator_id: string
  facilitator_name: string
  min_participants: number
  max_participants: number
  website_visible: boolean
  price: number
  payment_method: PaymentMethod | string
  is_active: boolean
  status: CourseBatchStatus | string
  enrollment_count: number
  created_at: number | string
  updated_at: number | string
}

export interface BatchEnrollment {
  enrollment_id: string
  student_id: string
  student_name: string
  student_email: string
  student_phone: string
  enrolled_at: string
  status: string
  payment_status: string
}

export interface CourseBatchDetail {
  id: string
  name: string
  start_date: string
  end_date: string
  max_participants: number
  is_active: boolean
  course_id: string
  course_name: string
  course_description: string
  department_id: string
  department_name: string
  facilitator_id: string
  facilitator_name: string
  facilitator_email: string
  total_enrolled: number
  paid_count: number
  pending_count: number
  failed_count: number
  created_at: number
  enrollments: BatchEnrollment[]
}

export interface BatchSchedule {
  id: string
  course_batch_id: string
  module_id: string | null
  room_id: string | null
  scheduled_at: string
  end_time: string
  duration_minutes: number
  notes: string
  status: string
}

export interface CourseBatchFilters {
  page?: number
  limit?: number
  status?: string
  course_id?: string
}

export interface PaginatedCourseBatches {
  data: CourseBatch[]
  total: number
  offset: number
  limit: number
}
