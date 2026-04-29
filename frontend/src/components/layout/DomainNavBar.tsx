import { NavLink, useLocation } from 'react-router-dom'
import { cn } from '@/lib/utils/cn'
import { getInternalDomains } from '@/lib/auth/roleNav'
import { useAuth } from '@/lib/auth/useAuth'

export default function DomainNavBar() {
  const { user } = useAuth()
  const location = useLocation()
  const domains = getInternalDomains(user?.role ?? '')

  const activeDomain = domains.find(
    d =>
      location.pathname === d.to ||
      d.items.some(item => location.pathname.startsWith(item.to)),
  )

  if (!activeDomain) return null

  return (
    <div className="sticky top-14 z-40 h-10 bg-white border-b border-neutral-100 flex items-center px-6 md:px-8 gap-0.5 overflow-x-auto scrollbar-none">
      {activeDomain.items.map(item => (
        <NavLink
          key={item.to}
          to={item.to}
          className={({ isActive }) =>
            cn(
              'shrink-0 px-3 h-10 text-sm font-medium transition-colors relative whitespace-nowrap flex items-center',
              isActive
                ? 'text-brand-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-brand-600 after:rounded-t-full'
                : 'text-neutral-500 hover:text-neutral-700 hover:bg-neutral-50',
            )
          }
        >
          {item.label}
        </NavLink>
      ))}
    </div>
  )
}
