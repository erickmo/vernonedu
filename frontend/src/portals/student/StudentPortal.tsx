import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { GraduationCap, BookOpen, Award, User, LayoutDashboard, Bell, LogOut, ChevronDown } from 'lucide-react'
import * as DropdownMenu from '@radix-ui/react-dropdown-menu'
import { useAuth } from '@/lib/auth/useAuth'
import { useUnreadCount } from '@/lib/api/platform'
import { cn } from '@/lib/utils/cn'

const NAV_ITEMS = [
  { to: '/student', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: '/student/catalog', label: 'Course Catalog', icon: BookOpen },
  { to: '/student/enrollments', label: 'My Enrollments', icon: GraduationCap },
  { to: '/student/certificates', label: 'Certificates', icon: Award },
  { to: '/student/profile', label: 'Profile', icon: User },
]

export default function StudentPortal() {
  const { user, logout } = useAuth()
  const unread = useUnreadCount()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-neutral-50">
      <header className="sticky top-0 z-40 bg-white border-b border-border shadow-sm">
        <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between gap-4">
          <div className="flex items-center gap-8">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-brand-600 flex items-center justify-center">
                <GraduationCap className="w-5 h-5 text-white" />
              </div>
              <span className="font-bold text-neutral-900">VernonEdu</span>
            </div>

            <nav className="hidden md:flex items-center gap-1">
              {NAV_ITEMS.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.end}
                  className={({ isActive }) =>
                    cn(
                      'flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                      isActive
                        ? 'bg-brand-50 text-brand-700'
                        : 'text-neutral-600 hover:bg-neutral-100 hover:text-neutral-900'
                    )
                  }
                >
                  <item.icon className="w-4 h-4" />
                  {item.label}
                </NavLink>
              ))}
            </nav>
          </div>

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
                    {user?.name?.charAt(0).toUpperCase() ?? 'U'}
                  </span>
                </div>
                <span className="hidden sm:block text-sm font-medium text-neutral-700">{user?.name}</span>
                <ChevronDown className="w-4 h-4 text-neutral-400" />
              </DropdownMenu.Trigger>

              <DropdownMenu.Portal>
                <DropdownMenu.Content
                  align="end"
                  className="z-50 min-w-[180px] bg-white rounded-lg shadow-lg border border-border p-1 animate-in fade-in-0 zoom-in-95"
                >
                  <DropdownMenu.Item
                    onClick={() => navigate('/student/profile')}
                    className="flex items-center gap-2 px-3 py-2 text-sm text-neutral-700 rounded cursor-pointer hover:bg-neutral-100 outline-none"
                  >
                    <User className="w-4 h-4" />
                    Profile
                  </DropdownMenu.Item>
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
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        <Outlet />
      </main>
    </div>
  )
}
