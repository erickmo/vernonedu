import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { GraduationCap, LayoutDashboard, TrendingUp, DollarSign, LogOut, ChevronDown } from 'lucide-react'
import * as DropdownMenu from '@radix-ui/react-dropdown-menu'
import { useAuth } from '@/lib/auth/useAuth'
import { cn } from '@/lib/utils/cn'

const NAV_ITEMS = [
  { to: '/franchise', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: '/franchise/revenue', label: 'Revenue', icon: TrendingUp },
  { to: '/franchise/royalty', label: 'Royalty', icon: DollarSign },
]

export default function FranchisePortal() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-neutral-50 flex">
      <aside className="w-56 fixed inset-y-0 left-0 bg-white border-r border-border flex flex-col">
        <div className="h-16 flex items-center px-4 border-b border-border gap-3">
          <div className="w-8 h-8 rounded-lg bg-violet-600 flex items-center justify-center">
            <GraduationCap className="w-5 h-5 text-white" />
          </div>
          <div>
            <p className="font-bold text-neutral-900 text-sm">VernonEdu</p>
            <p className="text-xs text-neutral-500">Franchise Portal</p>
          </div>
        </div>

        <nav className="flex-1 px-2 py-4 space-y-1">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-violet-50 text-violet-700'
                    : 'text-neutral-600 hover:bg-neutral-100 hover:text-neutral-900'
                )
              }
            >
              <item.icon className="w-5 h-5" />
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="p-3 border-t border-border">
          <DropdownMenu.Root>
            <DropdownMenu.Trigger className="w-full flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-neutral-100 transition-colors text-left">
              <div className="w-8 h-8 rounded-full bg-violet-100 flex items-center justify-center">
                <span className="text-sm font-semibold text-violet-700">
                  {user?.name?.charAt(0).toUpperCase() ?? 'F'}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-neutral-800 truncate">{user?.name}</p>
                <p className="text-xs text-neutral-500">Franchisee</p>
              </div>
              <ChevronDown className="w-4 h-4 text-neutral-400 shrink-0" />
            </DropdownMenu.Trigger>

            <DropdownMenu.Portal>
              <DropdownMenu.Content
                side="top"
                align="end"
                className="z-50 min-w-[160px] bg-white rounded-lg shadow-lg border border-border p-1"
              >
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
      </aside>

      <main className="flex-1 ml-56 p-6">
        <Outlet />
      </main>
    </div>
  )
}
