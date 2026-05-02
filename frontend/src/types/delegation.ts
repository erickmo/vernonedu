export type DelegationType = 'course_request' | 'project_assignment' | 'task' | 'review' | 'other'
export type DelegationStatus = 'pending' | 'accepted' | 'in_progress' | 'completed' | 'cancelled'
export type DelegationPriority = 'low' | 'medium' | 'high' | 'urgent'

export interface Delegation {
  id: string
  title: string
  type: DelegationType
  description: string
  requested_by_id: string
  requested_by_name: string
  assigned_to_id: string
  assigned_to_name: string
  assigned_to_role?: string
  status: DelegationStatus
  priority: DelegationPriority
  due_date?: string
  linked_entity_type?: string
  linked_entity_id?: string
  notes?: string
  created_at?: string
  updated_at?: string
}

export interface DelegationFilters {
  page?: number
  limit?: number
  type?: DelegationType | ''
  status?: DelegationStatus | ''
  assigned_to_id?: string
  requested_by_id?: string
}

export interface PaginatedDelegations {
  data: Delegation[]
  total: number
  offset: number
  limit: number
}

export const DELEGATION_TYPES: DelegationType[] = [
  'course_request', 'project_assignment', 'task', 'review', 'other',
]
export const DELEGATION_STATUSES: DelegationStatus[] = [
  'pending', 'accepted', 'in_progress', 'completed', 'cancelled',
]
export const DELEGATION_PRIORITIES: DelegationPriority[] = ['low', 'medium', 'high', 'urgent']
