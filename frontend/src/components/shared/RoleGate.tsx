import { ReactNode } from 'react'
import { useRBAC } from '@/lib/auth/useRBAC'
import type { Action, Resource } from '@/lib/auth/permissions'

interface Props {
  action: Action
  resource: Resource
  fallback?: ReactNode
  children: ReactNode
}

export default function RoleGate({ action, resource, fallback = null, children }: Props) {
  const { canAccess } = useRBAC()
  if (!canAccess(action, resource)) return <>{fallback}</>
  return <>{children}</>
}
