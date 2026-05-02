export type MasterCourseStatus = 'active' | 'archived'

export interface MasterCourse {
  id: string
  course_code: string
  course_name: string
  field: string
  core_competencies: string[]
  description: string
  supporting_app_url?: string
  status: MasterCourseStatus
  created_at: string
  updated_at: string
}

export interface MasterCourseFilters {
  search?: string
  field?: string
  status?: MasterCourseStatus
  department_id?: string
  page?: number
  limit?: number
}

export interface PaginatedMasterCourses {
  data: MasterCourse[]
  total: number
  offset: number
  limit: number
}
