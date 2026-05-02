export interface CourseModule {
  id: string
  course_version_id: string
  module_code: string
  module_title: string
  duration_hours: number
  sequence: number
  content_depth: string
  topics: string[]
  practical_activities: string[]
  assessment_method: string
  tools_required: string[]
  requirements: string[]
  is_reference: boolean
  ref_module_id?: string | null
  created_at: string | number
  updated_at: string | number
}
