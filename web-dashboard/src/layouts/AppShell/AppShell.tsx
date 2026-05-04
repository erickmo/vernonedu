import { useMemo } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/stores/auth.store'
import { Navbar1 } from '@/layouts/Navbar1/Navbar1'
import { Navbar2 } from '@/layouts/Navbar2/Navbar2'
import { getFilteredSections, getActiveSection } from '@/layouts/AppSidebar/navItems'
import styles from './AppShell.module.css'

export type AppContext = 'default' | 'superuser' | 'hq' | 'company'

interface AppShellProps {
  context?: AppContext
}

export function AppShell(_props: AppShellProps) {
  const location = useLocation()
  const user = useAuthStore((s) => s.user)

  const sections = useMemo(() => {
    if (!user) return []
    return getFilteredSections(user)
  }, [user])

  const activeSection = useMemo(
    () => getActiveSection(location.pathname, sections),
    [location.pathname, sections],
  )

  return (
    <div className={styles.layout}>
      <Navbar1 sections={sections} activeSection={activeSection} />
      {activeSection && <Navbar2 section={activeSection} />}
      <main className={styles.mainContent}>
        <Outlet />
      </main>
    </div>
  )
}
