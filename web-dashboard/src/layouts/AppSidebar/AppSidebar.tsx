import { useState, useMemo } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { ChevronLeft, LogOut } from 'lucide-react'
import { useAuthStore } from '@/stores/auth.store'
import { cn } from '@/utils/cn'
import { getFilteredSections } from './navItems'
import type { NavItem, NavSection } from './navItems'
import styles from './AppSidebar.module.css'

// ─── Component ──────────────────────────────────────────────────────────────────

export function AppSidebar() {
  const [collapsed, setCollapsed] = useState(false)
  const location = useLocation()
  const navigate = useNavigate()
  const { user, logout } = useAuthStore()

  const sections = useMemo(() => {
    if (!user) return []
    return getFilteredSections(user)
  }, [user])

  const isActive = (path: string) => {
    if (path === '/dashboard') {
      return (
        location.pathname === '/dashboard' ||
        location.pathname === '/'
      )
    }
    return location.pathname.startsWith(path)
  }

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const initials = user?.name
    ? user.name
        .split(' ')
        .map((w) => w[0])
        .join('')
        .slice(0, 2)
        .toUpperCase()
    : 'U'

  return (
    <aside
      className={cn(styles.sidebar, collapsed && styles.sidebarCollapsed)}
      aria-label="Sidebar navigasi"
    >
      {/* ── Header ──────────────────────────────────────────────────────────── */}
      <div className={styles.header}>
        <Link to="/dashboard" className={styles.logo}>
          <span className={styles.logoIcon}>V</span>
          <span className={styles.logoText}>VernonEdu</span>
        </Link>
        <button
          className={styles.collapseBtn}
          onClick={() => setCollapsed((c) => !c)}
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          <ChevronLeft
            size={14}
            className={cn(
              styles.collapseIcon,
              collapsed && styles.collapseIconRotated,
            )}
          />
        </button>
      </div>

      {/* ── Navigation ──────────────────────────────────────────────────────── */}
      <nav className={styles.navScroll}>
        {sections.map((section) => (
          <SectionGroup
            key={section.key}
            section={section}
            collapsed={collapsed}
            isActive={isActive}
          />
        ))}
      </nav>

      {/* ── Footer (User) ───────────────────────────────────────────────────── */}
      <div
        className={cn(styles.footer, collapsed && styles.footerCollapsed)}
      >
        <span className={styles.userAvatar}>{initials}</span>
        {!collapsed && (
          <div className={styles.userInfo}>
            <div className={styles.userName}>{user?.name}</div>
            <div className={styles.userRole}>{user?.roles?.join(', ')}</div>
          </div>
        )}
        <button
          className={styles.logoutBtn}
          onClick={handleLogout}
          aria-label="Keluar"
          title="Keluar"
        >
          <LogOut size={14} />
        </button>
      </div>
    </aside>
  )
}

// ─── Section group sub-component ────────────────────────────────────────────────

interface SectionGroupProps {
  section: NavSection
  collapsed: boolean
  isActive: (path: string) => boolean
}

function SectionGroup({ section, collapsed, isActive }: SectionGroupProps) {
  return (
    <div className={styles.section}>
      <div className={styles.sectionHeader}>{section.label}</div>
      {section.items.map((item) => (
        <NavItemLink
          key={item.key}
          item={item}
          collapsed={collapsed}
          active={isActive(item.path)}
        />
      ))}
    </div>
  )
}

// ─── Nav item sub-component ─────────────────────────────────────────────────────

interface NavItemLinkProps {
  item: NavItem
  collapsed: boolean
  active: boolean
}

function NavItemLink({ item, collapsed, active }: NavItemLinkProps) {
  const Icon = item.icon

  return (
    <Link
      to={item.path}
      className={cn(styles.navItem, active && styles.navItemActive)}
      title={collapsed ? item.label : undefined}
    >
      <span className={styles.navItemIcon}>
        <Icon size={18} />
      </span>
      <span className={styles.navItemLabel}>{item.label}</span>
      {collapsed && <span className={styles.tooltip}>{item.label}</span>}
    </Link>
  )
}
