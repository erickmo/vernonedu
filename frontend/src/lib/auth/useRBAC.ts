import { useAuth } from './useAuth'

const ROLE_ADMIN = 'admin'
const ROLE_CEO = 'ceo'
const ROLE_STUDENT = 'student'
const ROLE_FRANCHISEE = 'franchisee'

export function useRBAC() {
  const { user } = useAuth()

  return {
    hasRole: (...roles: string[]) => roles.includes(user?.role ?? ''),
    isAdmin: () => user?.role === ROLE_ADMIN,
    isCEO: () => user?.role === ROLE_CEO,
    isStudent: () => user?.role === ROLE_STUDENT,
    isFranchisee: () => user?.role === ROLE_FRANCHISEE,
    role: user?.role ?? null,
  }
}
