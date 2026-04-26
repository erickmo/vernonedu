import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from './useAuth'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

interface ProtectedRouteProps {
  allowedRoles: string[]
}

function ForbiddenPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-neutral-50">
      <div className="text-center space-y-4">
        <h1 className="text-6xl font-bold text-neutral-300">403</h1>
        <p className="text-xl font-semibold text-neutral-700">Access Denied</p>
        <p className="text-neutral-500">You don't have permission to view this page.</p>
        <a href="/" className="inline-block mt-4 text-brand-600 hover:text-brand-700 font-medium">
          Go back home
        </a>
      </div>
    </div>
  )
}

export default function ProtectedRoute({ allowedRoles }: ProtectedRouteProps) {
  const { isAuthenticated, isLoading, user } = useAuth()

  if (isLoading) return <LoadingSpinner size="lg" />
  if (!isAuthenticated) return <Navigate to="/login" replace />
  if (!allowedRoles.includes(user?.role ?? '')) return <ForbiddenPage />

  return <Outlet />
}
