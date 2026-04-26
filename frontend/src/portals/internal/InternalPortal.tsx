import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import {
  GraduationCap, LayoutDashboard, Users, BookOpen, CreditCard,
  Bell, LogOut, ChevronDown, Menu, X
} from 'lucide-react'
import { useState } from 'react'
import * as DropdownMenu from '@radix-ui/react-dropdown-menu'
import { useAuth } from '@/lib/auth/useAuth'
import { useRBAC } from '@/lib/auth/useRBAC'
import { useUnreadCount } from '@/lib/api/platform'
import { cn } from '@/lib/utils/cn'

interface NavItem {
  to: string
  label: string
  icon: typeof LayoutDashboard
  roles?: string[]
  end?: boolean
}

const NAV_ITEMS: NavItem[] = [
  { to: '/internal', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: '/internal/enrollments', label: 'Enrollments', icon: GraduationCap },
  { to: '/internal/payments', label: 'Payments', icon: CreditCard },
  { to: '/internal/courses', label: 'Courses', icon: BookOpen },
  { to: '/internal/students', label: 'Students', icon: Users },
]

export default function InternalPortal() {
  const { user, logout } = useAuth()
  const { hasRole } = useRBAC()
  const unread = useUnreadCount()
  const navigate = useNavigate()
  const [sidebarOpen, setSidebarOpen] = useState(true)

  const visibleItems = NAV_ITEMS.filter((item) =>
    !item.roles || hasRole(...item.roles)
  )

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-neutral-50 flex">
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-50 bg-white border-r border-border flex flex-col transition-all duration-200',
          sidebarOpen ? 'w-56' : 'w-16'
        )}
      >
        <div className="h-16 flex items-center px-4 border-b border-border gap-3">
          <div className="w-8 h-8 rounded-lg bg-brand-600 flex items-center justify-center shrink-0">
            <GraduationCap className="w-5 h-5 text-white" />
          </div>
          {sidebarOpen && (
            <span className="font-bold text-neutral-900 text-sm">VernonEdu</span>
          )}
        </div>

        <nav className="flex-1 px-2 py-4 space-y-1 overflow-y-auto">
          {visibleItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-brand-50 text-brand-700'
                    : 'text-neutral-600 hover:bg-neutral-100 hover:text-neutral-900'
                )
              }
              title={!sidebarOpen ? item.label : undefined}
            >
              <item.icon className="w-5 h-5 shrink-0" />
              {sidebarOpen && item.label}
            </NavLink>
          ))}
        </nav>

        <div className="p-2 border-t border-border">
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="w-full flex items-center justify-center p-2 rounded-lg hover:bg-neutral-100 transition-colors"
          >
            {sidebarOpen ? <X className="w-4 h-4 text-neutral-500" /> : <Menu className="w-4 h-4 text-neutral-500" />}
          </button>
        </div>
      </aside>

      <div className={cn('flex-1 flex flex-col transition-all duration-200', sidebarOpen ? 'ml-56' : 'ml-16')}>
        <header className="sticky top-0 z-40 bg-white border-b border-border h-16 flex items-center justify-between px-6">
          <div />
          <div className="flex items-center gap-2">
            <button className="relative p-2 rounded-lg hover:bg-neutral-100 transition-colors">
              <Bell className="w-5 h-5 text-neutral-600" />
              {unread > 0 && (
                <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full" />
              )}
            </button>

            <DropdownMenu.Root>
              <DropdownMenu.Trigger className="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-neutral-100 transition-colors">
                <div className="w-8 h-8 rounded-full bg-brand-100 flex items-center justify-center">
                  <span className="text-sm font-semibold text-brand-700">
                    {user?.name?.charAt(0).toUpperCase() ?? 'A'}
                  </span>
                </div>
                <div className="text-left hidden sm:block">
                  <p className="text-xs font-semibold text-neutral-800">{user?.name}</p>
                  <p className="text-xs text-neutral-500 capitalize">{user?.role}</p>
                </div>
                <ChevronDown className="w-4 h-4 text-neutral-400" />
              </DropdownMenu.Trigger>

              <DropdownMenu.Portal>
                <DropdownMenu.Content
                  align="end"
                  className="z-50 min-w-[180px] bg-white rounded-lg shadow-lg border border-border p-1"
                >
                  <DropdownMenu.Separator className="my-1 border-t border-border" />
                  <DropdownMenu.Item
                    onClick={handleLogout}
                    className="flex items-center gap-2 px-3 py-2 text-sm text-red-600 rounded cursor-pointer hover:bg-red-50 outline-none"
                  >
                    <LogOut className="w-4 h-4" />
                    Sign out
                  </DropdownMenu.Item>
                </DropdownMenu.Content>
              </DropdownMenu.Portal>
            </DropdownMenu.Root>
          </div>
        </header>

        <main className="flex-1 p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
