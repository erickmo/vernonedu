import { Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import { SubNavProvider, SubNavBar } from '@/components/layout/SubNavContext'
import TopNavBar, { NavItem } from '@/components/layout/TopNavBar'
import { FranchiseeProvider } from './FranchiseeContext'

const NAV_ITEMS: NavItem[] = [
  { to: '/franchise', label: 'Dashboard', end: true },
  { to: '/franchise/royalty', label: 'Royalty' },
  { to: '/franchise/enrollments', label: 'Enrollments' },
  { to: '/franchise/payments', label: 'Payments' },
  { to: '/franchise/team', label: 'Team' },
]

function FranchiseLayout() {
  const { user, logout } = useAuth()
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
        unreadCount={0}
        onLogout={handleLogout}
        avatarClass="bg-violet-100 text-violet-700"
      />
      <SubNavBar />
      <main className="px-6 md:px-8 lg:px-12 py-6">
        <Outlet />
      </main>
    </div>
  )
}

export default function FranchisePortal() {
  return (
    <FranchiseeProvider>
      <SubNavProvider>
        <FranchiseLayout />
      </SubNavProvider>
    </FranchiseeProvider>
  )
}
