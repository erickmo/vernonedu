import { Navigate, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/stores/auth.store'
import { hasRole, hasAnyRole } from '@/types/auth.types'

interface RouteProps {
  children: React.ReactNode
}

// ─── Root redirect ────────────────────────────────────────────────────────────
// VernonEdu is single-tenant — always redirects to /dashboard after auth.

export function RootRedirect() {
  const { isAuthenticated } = useAuthStore()

  if (!isAuthenticated) return <Navigate to="/login" replace />
  return <Navigate to="/dashboard" replace />
}

// ─── Auth guard — requires any authenticated user ─────────────────────────────

export function AuthRoute({ children }: RouteProps) {
  const { isAuthenticated } = useAuthStore()
  const location = useLocation()
  if (!isAuthenticated) return <Navigate to="/login" state={{ from: location }} replace />
  return <>{children}</>
}

// ─── Guest guard — redirect authenticated users away from login ───────────────

export function GuestRoute({ children }: RouteProps) {
  const { isAuthenticated } = useAuthStore()
  if (isAuthenticated) return <Navigate to="/" replace />
  return <>{children}</>
}

// ─── Role guard — requires specific role(s) ───────────────────────────────────

export function RoleRoute({ children, role }: RouteProps & { role: string | string[] }) {
  const { isAuthenticated, user } = useAuthStore()
  const location = useLocation()

  if (!isAuthenticated) return <Navigate to="/login" state={{ from: location }} replace />

  const requiredRoles = Array.isArray(role) ? role : [role]
  if (!hasAnyRole(user, requiredRoles as import('@/types/auth.types').VernonEduRole[])) {
    return <Navigate to="/403" replace />
  }

  return <>{children}</>
}

// ─── Director-only guard ──────────────────────────────────────────────────────

export function DirectorRoute({ children }: RouteProps) {
  const { isAuthenticated, user } = useAuthStore()
  const location = useLocation()
  if (!isAuthenticated) return <Navigate to="/login" state={{ from: location }} replace />
  if (!hasRole(user, 'director')) return <Navigate to="/" replace />
  return <>{children}</>
}

// ─── Multi-tenant stubs (kept for route compatibility) ────────────────────────
// VernonEdu is single-tenant. These guards simply pass through to children.

export function SuperuserRoute({ children }: RouteProps) {
  return <>{children}</>
}

export function GroupRoute({ children }: RouteProps) {
  return <>{children}</>
}

export function CompanyRoute({ children }: RouteProps) {
  return <>{children}</>
}
