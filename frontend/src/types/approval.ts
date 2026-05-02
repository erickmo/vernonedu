export const APPROVAL_STATUSES = ['pending', 'approved', 'rejected', 'cancelled'] as const
export type ApprovalStatus = (typeof APPROVAL_STATUSES)[number]

export const APPROVAL_TYPES = [
  'assign_dept_leader',
  'propose_course',
  'course_version_change',
  'create_batch',
  'batch_pricing_override',
  'batch_capacity_override',
  'schedule_conflict',
  'revoke_certificate',
  'other',
] as const
export type ApprovalType = (typeof APPROVAL_TYPES)[number]

export interface Approval {
  id: string
  type: ApprovalType
  status: ApprovalStatus
  title: string
  description: string
  requested_by_id: string
  requested_by_name?: string
  approver_id: string
  approver_name?: string
  entity_type?: string
  entity_id?: string
  reason?: string
  created_at: string
  updated_at: string
  decided_at?: string | null
}

export interface ApprovalFilters {
  status?: ApprovalStatus | ''
  approver_id?: string
  type?: ApprovalType | ''
  page?: number
  limit?: number
}

export interface PaginatedApprovals {
  data: Approval[]
  total: number
  offset: number
  limit: number
}
