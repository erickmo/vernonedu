import { useAuthStore } from '@/stores/auth.store'
import type { VernonEduRole } from '@/types/auth.types'

export function usePermission() {
  const { user } = useAuthStore()
  const roles = user?.roles ?? []
  const isDirector = roles.includes('director')

  return {
    can: (_permission: string): boolean =>
      isDirector,

    canAny: (_perms: string[]): boolean =>
      isDirector,

    canAll: (_perms: string[]): boolean =>
      isDirector,

    hasRole: (role: VernonEduRole | VernonEduRole[]): boolean => {
      if (isDirector) return true
      const checkRoles = Array.isArray(role) ? role : [role]
      return checkRoles.some((r) => roles.includes(r))
    },
  }
}
