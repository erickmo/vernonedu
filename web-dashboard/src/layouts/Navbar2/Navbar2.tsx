import { Link, useLocation } from 'react-router-dom'
import { cn } from '@/utils/cn'
import type { NavSection } from '../AppSidebar/navItems'
import styles from './Navbar2.module.css'

interface Navbar2Props {
  section: NavSection
}

export function Navbar2({ section }: Navbar2Props) {
  const location = useLocation()

  if (section.items.length <= 1) return null

  return (
    <nav className={styles.navbar}>
      {section.items.map((item) => {
        const Icon = item.icon
        const active = item.path === '/dashboard'
          ? location.pathname === '/dashboard' || location.pathname === '/'
          : location.pathname.startsWith(item.path)

        return (
          <Link
            key={item.key}
            to={item.path}
            className={cn(styles.navItem, active && styles.navItemActive)}
          >
            <Icon size={14} className={styles.navIcon} />
            {item.label}
          </Link>
        )
      })}
    </nav>
  )
}
