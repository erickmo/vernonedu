import { Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import { useUnreadCount } from '@/lib/api/platform'
import { SubNavProvider, SubNavBar } from '@/components/layout/SubNavContext'
import TopNavBar from '@/components/layout/TopNavBar'
import { getInternalNavItems } from '@/lib/auth/roleNav'

function InternalLayout() {
  const { user, logout } = useAuth()
  const unread = useUnreadCount()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const navItems = getInternalNavItems(user?.role ?? '')

  return (
    <div className="min-h-screen bg-neutral-50">
      <TopNavBar
        mainNav={navItems}
        user={user}
        unreadCount={unread}
        onLogout={handleLogout}
        avatarClass="bg-brand-100 text-brand-700"
      />
      <SubNavBar />
      <main className="px-6 md:px-8 lg:px-12 py-6">
        <Outlet />
      </main>
    </div>
  )
}

export default function InternalPortal() {
  return (
    <SubNavProvider>
      <InternalLayout />
    </SubNavProvider>
  )
}
