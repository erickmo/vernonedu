export const PROJECT_STATUSES = [
  'planning',
  'active',
  'completed',
  'cancelled',
  'on_hold',
] as const
export type ProjectStatus = (typeof PROJECT_STATUSES)[number]

export interface Project {
  id: string
  code: string
  name: string
  description: string
  status: ProjectStatus
  start_date: string
  end_date: string
  partner_id?: string | null
  partner_name?: string
  branch_id?: string | null
  budget: number
  earning: number
  created_at: string
  updated_at: string
}

export interface ProjectFilters {
  status?: ProjectStatus | ''
  partner_id?: string
  branch_id?: string
  page?: number
  limit?: number
}

export interface PaginatedProjects {
  data: Project[]
  total: number
  offset: number
  limit: number
}
