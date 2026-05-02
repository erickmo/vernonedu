export type CourseVersionStatus = 'draft' | 'review' | 'approved' | 'archived'
export type ChangeType = 'major' | 'minor' | 'patch'

export interface CourseVersion {
  id: string
  course_type_id: string
  version_number: string
  status: CourseVersionStatus
  change_type: ChangeType
  changelog: string
  created_by?: string | null
  approved_by?: string | null
  created_at: string
  updated_at: string
  approved_at?: string | null
  archived_at?: string | null
}
