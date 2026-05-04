// VernonEdu staff roles
export type VernonEduRole =
  | 'director'
  | 'education_leader'
  | 'dept_leader'
  | 'course_owner'
  | 'facilitator'
  | 'operation_leader'
  | 'operation_admin'
  | 'customer_service'
  | 'marketing'
  | 'accounting_leader'
  | 'accounting_staff'

export interface VernonEduUser {
  id: string
  name: string
  email: string
  roles: VernonEduRole[]
  departmentId?: string
  departmentName?: string
  avatarUrl?: string
  isActive?: boolean
}

export interface VernonEduLoginRequest {
  email: string
  password: string
}

export interface VernonEduLoginResponse {
  access_token: string
  refresh_token: string
  user: VernonEduUser
}

// Permission helpers
export function hasRole(user: VernonEduUser | null, role: VernonEduRole): boolean {
  return user?.roles.includes(role) ?? false
}

export function hasAnyRole(user: VernonEduUser | null, roles: VernonEduRole[]): boolean {
  return user?.roles.some(r => roles.includes(r)) ?? false
}

export const canManageCourse = (user: VernonEduUser | null) =>
  hasAnyRole(user, ['director', 'education_leader', 'dept_leader', 'course_owner'])

export const canManageStudent = (user: VernonEduUser | null) =>
  hasAnyRole(user, ['director', 'education_leader', 'dept_leader', 'course_owner', 'customer_service', 'operation_leader', 'operation_admin'])

export const canViewAccounting = (user: VernonEduUser | null) =>
  hasAnyRole(user, ['director', 'accounting_leader', 'accounting_staff'])

export const canViewHrm = (user: VernonEduUser | null) =>
  hasAnyRole(user, ['director', 'education_leader', 'dept_leader', 'operation_leader'])

export const canViewCrm = (user: VernonEduUser | null) =>
  hasAnyRole(user, ['director', 'customer_service', 'marketing'])

export const isOperationTeam = (user: VernonEduUser | null) =>
  hasAnyRole(user, ['operation_leader', 'operation_admin', 'customer_service', 'marketing'])

export const canManageLocation = (user: VernonEduUser | null) =>
  hasAnyRole(user, ['director', 'operation_leader', 'operation_admin'])

export const canViewTalentPool = (user: VernonEduUser | null) =>
  hasAnyRole(user, ['director', 'education_leader', 'dept_leader', 'course_owner'])

export const canViewBusinessDev = (user: VernonEduUser | null) =>
  hasRole(user, 'director')

export const canAccessAdmin = (user: VernonEduUser | null) =>
  user ? user.roles.length > 0 : false

// Keep compatibility with existing imports
export type UserRole = VernonEduRole
export type UserProfile = VernonEduUser
export type LoginRequest = VernonEduLoginRequest
export type LoginResponse = VernonEduLoginResponse
