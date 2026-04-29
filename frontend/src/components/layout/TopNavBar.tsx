import { useState } from 'react'
import { NavLink, Link } from 'react-router-dom'
import { Bell, ChevronDown, GraduationCap, LogOut, Menu, X } from 'lucide-react'
import * as DropdownMenu from '@radix-ui/react-dropdown-menu'
import { cn } from '@/lib/utils/cn'
import type { DomainGroup } from '@/lib/auth/roleNav'

export interface NavItem {
  to: string
  label: string
  end?: boolean
}

interface TopNavBarProps {
  mainNav?: NavItem[]
  domainNav?: DomainGroup[]
  dashboardTo?: string
  user: { id: string; name: string; role: string; email: string } | null
  unreadCount?: number
  onLogout: () => void
  avatarClass?: string
}

export default function TopNavBar({
  mainNav,
  domainNav,
  dashboardTo,
  user,
  unreadCount = 0,
  onLogout,
  avatarClass = 'bg-brand-100 text-brand-700',
}: TopNavBarProps) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const initial = user?.name?.charAt(0).toUpperCase() ?? '?'

  return (
    <>
      <header className="sticky top-0 z-50 h-14 bg-white/95 backdrop-blur-sm border-b border-neutral-100 flex items-center gap-4 px-6 md:px-8">
        {/* Logo */}
        <Link to="/" className="flex items-center gap-2.5 shrink-0 mr-2">
          <div className="w-8 h-8 rounded-lg bg-brand-600 flex items-center justify-center">
            <GraduationCap className="w-5 h-5 text-white" />
          </div>
          <span className="font-bold text-neutral-900 text-sm tracking-tight">VernonEdu</span>
        </Link>

        {/* Main nav — desktop */}
        <nav className="hidden md:flex items-center gap-0.5 flex-1">
          {dashboardTo && domainNav && (
            <NavLink
              to={dashboardTo}
              end
              className={({ isActive }) =>
                cn(
                  'relative px-3 py-2 text-sm font-medium rounded-lg transition-colors',
                  isActive
                    ? 'text-brand-600 after:absolute after:bottom-1 after:left-3 after:right-3 after:h-0.5 after:bg-brand-600 after:rounded-full'
                    : 'text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50',
                )
              }
            >
              Dashboard
            </NavLink>
          )}
          {domainNav
            ? domainNav.map(domain => (
                <NavLink
                  key={domain.to}
                  to={domain.to}
                  className={({ isActive }) =>
                    cn(
                      'relative px-3 py-2 text-sm font-medium rounded-lg transition-colors',
                      isActive
                        ? 'text-brand-600 after:absolute after:bottom-1 after:left-3 after:right-3 after:h-0.5 after:bg-brand-600 after:rounded-full'
                        : 'text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50',
                    )
                  }
                >
                  {domain.label}
                </NavLink>
              ))
            : (mainNav ?? []).map(item => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.end}
                  className={({ isActive }) =>
                    cn(
                      'relative px-3 py-2 text-sm font-medium rounded-lg transition-colors',
                      isActive
                        ? 'text-brand-600 after:absolute after:bottom-1 after:left-3 after:right-3 after:h-0.5 after:bg-brand-600 after:rounded-full'
                        : 'text-neutral-600 hover:text-neutral-900 hover:bg-neutral-50',
                    )
                  }
                >
                  {item.label}
                </NavLink>
              ))}
        </nav>

        {/* Right side */}
        <div className="flex items-center gap-1 ml-auto">
          <button className="relative p-2 rounded-lg hover:bg-neutral-100 transition-colors">
            <Bell className="w-5 h-5 text-neutral-500" />
            {unreadCount > 0 && (
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full ring-2 ring-white" />
            )}
          </button>

          <DropdownMenu.Root>
            <DropdownMenu.Trigger className="flex items-center gap-2 px-2 py-1.5 rounded-lg hover:bg-neutral-100 transition-colors outline-none">
              <div
                className={cn(
                  'w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold shrink-0',
                  avatarClass,
                )}
              >
                {initial}
              </div>
              <div className="hidden sm:block text-left leading-tight">
                <p className="text-xs font-semibold text-neutral-800">{user?.name}</p>
                <p className="text-[11px] text-neutral-500 capitalize">{user?.role}</p>
              </div>
              <ChevronDown className="w-3.5 h-3.5 text-neutral-400 hidden sm:block" />
            </DropdownMenu.Trigger>

            <DropdownMenu.Portal>
              <DropdownMenu.Content
                align="end"
                sideOffset={6}
                className="z-50 min-w-[200px] bg-white rounded-xl shadow-lg border border-neutral-100 p-1.5 animate-in fade-in-0 zoom-in-95 duration-100"
              >
                <div className="px-3 py-2">
                  <p className="text-xs font-semibold text-neutral-800">{user?.name}</p>
                  <p className="text-[11px] text-neutral-500 truncate">{user?.email}</p>
                </div>
                <DropdownMenu.Separator className="my-1 -mx-1.5 border-t border-neutral-100" />
                <DropdownMenu.Item
                  onClick={onLogout}
                  className="flex items-center gap-2 px-3 py-2 text-sm text-red-600 rounded-lg cursor-pointer hover:bg-red-50 outline-none"
                >
                  <LogOut className="w-4 h-4" />
                  Sign out
                </DropdownMenu.Item>
              </DropdownMenu.Content>
            </DropdownMenu.Portal>
          </DropdownMenu.Root>

          {/* Mobile hamburger */}
          <button
            onClick={() => setMobileOpen((v) => !v)}
            className="md:hidden p-2 rounded-lg hover:bg-neutral-100 transition-colors"
          >
            {mobileOpen ? (
              <X className="w-5 h-5 text-neutral-600" />
            ) : (
              <Menu className="w-5 h-5 text-neutral-600" />
            )}
          </button>
        </div>
      </header>

      {/* Mobile nav drawer */}
      {mobileOpen && (
        <div className="md:hidden fixed inset-x-0 top-14 z-50 bg-white border-b border-neutral-100 shadow-lg px-4 py-3 space-y-0.5">
          {domainNav ? (
            <>
              {dashboardTo && (
                <NavLink
                  to={dashboardTo}
                  end
                  onClick={() => setMobileOpen(false)}
                  className={({ isActive }) =>
                    cn(
                      'flex items-center px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                      isActive
                        ? 'bg-brand-50 text-brand-700'
                        : 'text-neutral-600 hover:bg-neutral-50 hover:text-neutral-900',
                    )
                  }
                >
                  Dashboard
                </NavLink>
              )}
              {domainNav.map(domain => (
                <NavLink
                  key={domain.to}
                  to={domain.to}
                  onClick={() => setMobileOpen(false)}
                  className={({ isActive }) =>
                    cn(
                      'flex items-center px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                      isActive
                        ? 'bg-brand-50 text-brand-700'
                        : 'text-neutral-600 hover:bg-neutral-50 hover:text-neutral-900',
                    )
                  }
                >
                  {domain.label}
                </NavLink>
              ))}
            </>
          ) : (
            (mainNav ?? []).map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.end}
                onClick={() => setMobileOpen(false)}
                className={({ isActive }) =>
                  cn(
                    'flex items-center px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                    isActive
                      ? 'bg-brand-50 text-brand-700'
                      : 'text-neutral-600 hover:bg-neutral-50 hover:text-neutral-900',
                  )
                }
              >
                {item.label}
              </NavLink>
            ))
          )}
        </div>
      )}
    </>
  )
}
