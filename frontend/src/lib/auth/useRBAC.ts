import { useAuth } from './useAuth'
import { ROLES, STAFF_ROLES, type Role } from './roles'
import { canAccess as canAccessFn, type Action, type Resource } from './permissions'

export function useRBAC() {
  const { user } = useAuth()
  const role = (user?.role ?? null) as Role | null

  return {
    role,
    hasRole: (...roles: string[]) => roles.includes(role ?? ''),
    isStaff: () => role !== null && STAFF_ROLES.includes(role),
    isStudent: () => role === ROLES.STUDENT,
    isFranchisee: () => role === ROLES.FRANCHISEE,
    isDirector: () => role === ROLES.DIRECTOR || role === ROLES.CEO,
    canAccess: (action: Action, resource: Resource) => canAccessFn(role, action, resource),
  }
}
