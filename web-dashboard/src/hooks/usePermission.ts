import { useAuthStore } from '@/stores/auth.store'
import type { VernonEduRole } from '@/types/auth.types'

export function usePermission() {
  const { user } = useAuthStore()
  const roles = user?.roles ?? []
  const isDirector = roles.includes('director')

  return {
    hasRole: (role: VernonEduRole | VernonEduRole[]): boolean => {
      if (isDirector) return true
      const check = Array.isArray(role) ? role : [role]
      return check.some(r => roles.includes(r))
    },

    hasAnyRole: (checkRoles: VernonEduRole[]): boolean => {
      if (isDirector) return true
      return checkRoles.some(r => roles.includes(r))
    },
  }
}
