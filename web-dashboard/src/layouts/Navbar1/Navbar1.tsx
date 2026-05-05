import { useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { Bell, Calendar, ChevronDown, LogOut, Menu, X } from 'lucide-react'
import { useAuthStore } from '@/stores/auth.store'
import { cn } from '@/utils/cn'
import type { NavSection } from '../AppSidebar/navItems'
import styles from './Navbar1.module.css'

interface Navbar1Props {
  sections: NavSection[]
  activeSection: NavSection | null
}

export function Navbar1({ sections }: Navbar1Props) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const [profileOpen, setProfileOpen] = useState(false)
  const location = useLocation()
  const navigate = useNavigate()
  const { user, logout } = useAuthStore()

  const initials = user?.name
    ? user.name.split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase()
    : 'U'

  const handleLogout = () => {
    setProfileOpen(false)
    logout()
    navigate('/login')
  }

  const isSectionActive = (section: NavSection) => {
    return section.items.some((item) => {
      if (item.path === '/dashboard') {
        return location.pathname === '/dashboard' || location.pathname === '/'
      }
      return location.pathname.startsWith(item.path)
    })
  }

  const getSectionLink = (section: NavSection) => {
    if (section.key === 'utama') return '/dashboard'
    return section.items[0]?.path ?? '/dashboard'
  }

  return (
    <>
      <header className={styles.navbar}>
        {/* Logo */}
        <Link to="/dashboard" className={styles.logo}>
          <span className={styles.logoIcon}>V</span>
          <span className={styles.logoText}>VernonEdu</span>
        </Link>

        {/* Desktop tabs */}
        <nav className={styles.navTabs}>
          {sections.map((section) => {
            const Icon = section.icon
            const active = isSectionActive(section)
            return (
              <Link
                key={section.key}
                to={getSectionLink(section)}
                className={cn(styles.navTab, active && styles.navTabActive)}
              >
                <Icon size={16} className={styles.navTabIcon} />
                {section.label}
              </Link>
            )
          })}
        </nav>

        {/* Right */}
        <div className={styles.right}>
          <Link to="/calendar" className={styles.iconBtn}>
            <Calendar size={18} />
          </Link>
          <button className={styles.iconBtn}>
            <Bell size={18} />
          </button>

          <div style={{ position: 'relative' }}>
            <button
              className={styles.avatarBtn}
              onClick={() => setProfileOpen((v) => !v)}
            >
              <span className={styles.avatar}>{initials}</span>
              <div className={styles.avatarInfo}>
                <span className={styles.avatarName}>{user?.name}</span>
                <span className={styles.avatarRole}>{user?.roles?.[0]}</span>
              </div>
              <ChevronDown size={14} className={styles.avatarChevron} />
            </button>

            {profileOpen && (
              <div className={styles.profileDropdown}>
                <div className={styles.profileInfo}>
                  <span className={styles.profileAvatar}>{initials}</span>
                  <div>
                    <div className={styles.profileName}>{user?.name}</div>
                    <div className={styles.profileEmail}>{user?.email}</div>
                  </div>
                </div>
                <hr className={styles.divider} />
                <button
                  className={cn(styles.dropdownItem, styles.logoutItem)}
                  onClick={handleLogout}
                >
                  <LogOut size={16} />
                  Keluar
                </button>
              </div>
            )}
          </div>

          {/* Mobile hamburger */}
          <button
            className={styles.hamburger}
            onClick={() => setMobileOpen((v) => !v)}
          >
            {mobileOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
      </header>

      {/* Mobile drawer */}
      {mobileOpen && (
        <div className={styles.mobileDrawer}>
          {sections.map((section) => (
            <div key={section.key}>
              {section.items.length > 1 && (
                <div className={styles.mobileSectionLabel}>{section.label}</div>
              )}
              {section.items.map((item) => {
                const Icon = item.icon
                const active = location.pathname.startsWith(item.path) ||
                  (item.path === '/dashboard' && (location.pathname === '/dashboard' || location.pathname === '/'))
                return (
                  <Link
                    key={item.key}
                    to={item.path}
                    className={cn(styles.mobileItem, active && styles.mobileItemActive)}
                    onClick={() => setMobileOpen(false)}
                  >
                    <Icon size={16} />
                    {item.label}
                  </Link>
                )
              })}
            </div>
          ))}
        </div>
      )}
    </>
  )
}
