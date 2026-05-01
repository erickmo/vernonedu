/**
 * AdminLayout
 * Director-only admin panel wrapper with auth guard
 * Handles navigation and layout for CEO/Director admin features
 */

import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

export function AdminLayout() {
  const { isAuthenticated, isLoading, user } = useAuth()

  // Show loading while auth state is being determined
  if (isLoading) return <LoadingSpinner size="lg" />

  // Redirect to login if not authenticated
  if (!isAuthenticated) return <Navigate to="/login" replace />

  // Only directors can access admin panel
  const isDirector = user?.role === 'ceo' || user?.role === 'admin' || user?.role === 'director'
  if (!isDirector) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-neutral-50">
        <div className="text-center space-y-4">
          <h1 className="text-6xl font-bold text-neutral-300">403</h1>
          <p className="text-xl font-semibold text-neutral-700">Access Denied</p>
          <p className="text-neutral-500">
            Admin features are only available to directors.
          </p>
          <div className="flex gap-3 justify-center mt-6">
            <a
              href="/"
              className="inline-block px-5 py-2 bg-brand-600 text-white rounded-lg font-medium hover:bg-brand-700 transition-colors"
            >
              Go Home
            </a>
          </div>
        </div>
      </div>
    )
  }

  // Render the admin layout with child routes
  return (
    <div className="min-h-screen bg-neutral-50">
      {/* Admin Header */}
      <div className="bg-white border-b border-neutral-200 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-neutral-900">Admin Panel</h1>
              <p className="text-sm text-neutral-500 mt-1">
                Manage departments and organizational structure
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Admin Navigation Tabs */}
      <div className="bg-white border-b border-neutral-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <nav className="flex space-x-8" aria-label="Tabs">
            <a
              href="/admin/departments"
              className="px-3 py-4 text-sm font-medium text-neutral-700 hover:text-neutral-900 border-b-2 border-transparent hover:border-neutral-300"
            >
              Departments
            </a>
          </nav>
        </div>
      </div>

      {/* Admin Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <Outlet />
      </div>
    </div>
  )
}
