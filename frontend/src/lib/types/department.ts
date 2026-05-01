/**
 * Department Types
 * TypeScript interfaces for department management domain
 */

export interface Staff {
  id: string
  name: string
  email: string
  role: string
  avatar?: string
}

export interface Department {
  id: string
  name: string
  description?: string
  leaderId: string
  leaderName?: string
  leaderRole?: string
  leaderAvatar?: string
  isActive: boolean
  courseCount?: number
  paidEnrollmentCount?: number
  batchUpcoming?: number
  batchOngoing?: number
  batchCompleted?: number
  createdAt?: string
  updatedAt?: string
}

export interface CreateDepartmentPayload {
  name: string
  description?: string
  leader_id: string
  is_active: boolean
}

export interface UpdateDepartmentPayload {
  name?: string
  description?: string
  leader_id?: string
  is_active?: boolean
}
