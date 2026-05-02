import { Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import { useUnreadCount } from '@/lib/api/platform'
import { SubNavProvider, SubNavBar } from '@/components/layout/SubNavContext'
import TopNavBar, { NavItem } from '@/components/layout/TopNavBar'

const NAV_ITEMS: NavItem[] = [
  { to: '/student', label: 'Dashboard', end: true },
  { to: '/student/catalog', label: 'Course Catalog' },
  { to: '/student/enrollments', label: 'My Enrollments' },
  { to: '/student/certificates', label: 'Certificates' },
  { to: '/student/canvas', label: 'Canvas' },
  { to: '/student/design-thinking', label: 'Design Thinking' },
  { to: '/student/profile', label: 'Profile' },
]

function StudentLayout() {
  const { user, logout } = useAuth()
  const unread = useUnreadCount()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-neutral-50">
      <TopNavBar
        mainNav={NAV_ITEMS}
        user={user}
        unreadCount={unread}
        onLogout={handleLogout}
        avatarClass="bg-emerald-100 text-emerald-700"
      />
      <SubNavBar />
      <main className="px-6 md:px-8 lg:px-12 py-6">
        <Outlet />
      </main>
    </div>
  )
}

export default function StudentPortal() {
  return (
    <SubNavProvider>
      <StudentLayout />
    </SubNavProvider>
  )
}
