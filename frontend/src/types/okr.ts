export type OkrLevel = 'company' | 'department' | 'team' | 'individual'
export type OkrStatus = 'draft' | 'active' | 'completed' | 'archived'

export interface KeyResult {
  id: string
  objective_id: string
  title: string
  target: number
  current: number
  unit?: string
  progress: number // 0-100
}

export interface Objective {
  id: string
  title: string
  owner_id: string
  owner_name: string
  period: string
  level: OkrLevel
  status: OkrStatus
  progress: number
  key_results?: KeyResult[]
  created_at?: string
}

export interface ObjectiveFilters {
  level?: OkrLevel | ''
  status?: OkrStatus | ''
}

export interface PaginatedObjectives {
  data: Objective[]
  total: number
}

export const OKR_LEVELS: OkrLevel[] = ['company', 'department', 'team', 'individual']
export const OKR_STATUSES: OkrStatus[] = ['draft', 'active', 'completed', 'archived']
