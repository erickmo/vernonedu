import { usePermission } from '@/hooks/usePermission'

export interface PermissionGateProps {
  children: React.ReactNode
  role?: string | string[]
  fallback?: React.ReactNode
}

export function PermissionGate({
  children,
  role,
  fallback = null,
}: PermissionGateProps) {
  const { hasRole } = usePermission()

  if (role === undefined) return <>{children}</>

  const allowed = hasRole(role as any)
  return allowed ? <>{children}</> : <>{fallback}</>
}
