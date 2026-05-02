export type TalentPoolStage =
  | 'learning'
  | 'internship'
  | 'recommendation'
  | 'test'
  | 'talentpool'
  | 'placed'
  | 'inactive'

export interface PlacementRecord {
  company_name: string
  position: string
  notes: string
}

export interface TalentPoolEntry {
  id: string
  participant_id: string
  participant_name?: string
  master_course_id: string
  master_course_name?: string
  status: TalentPoolStage
  placement?: PlacementRecord | null
  created_at?: string
  updated_at?: string
}

export interface TalentPoolFilters {
  page?: number
  limit?: number
  status?: string
  master_course_id?: string
  participant_id?: string
}

export interface PaginatedTalentPool {
  data: TalentPoolEntry[]
  total: number
  offset: number
  limit: number
}
