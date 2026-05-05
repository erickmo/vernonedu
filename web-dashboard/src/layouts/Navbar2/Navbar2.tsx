import { Link, useLocation } from 'react-router-dom'
import { cn } from '@/utils/cn'
import type { NavSection } from '../AppSidebar/navItems'
import styles from './Navbar2.module.css'

interface Navbar2Props {
  section: NavSection
}

function isItemActive(itemPath: string, pathname: string, siblings: { path: string }[]): boolean {
  if (itemPath === '/dashboard') return pathname === '/dashboard' || pathname === '/'
  const hasMoreSpecificMatch = siblings.some(
    (s) => s.path !== itemPath && s.path.startsWith(itemPath) && pathname.startsWith(s.path),
  )
  if (hasMoreSpecificMatch) return false
  return pathname.startsWith(itemPath)
}

export function Navbar2({ section }: Navbar2Props) {
  const location = useLocation()

  if (section.items.length <= 1) return null

  return (
    <nav className={styles.navbar}>
      {section.items.map((item) => {
        const Icon = item.icon
        const active = isItemActive(item.path, location.pathname, section.items)

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
