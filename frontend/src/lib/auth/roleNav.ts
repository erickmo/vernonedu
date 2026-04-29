import type { NavItem } from '@/components/layout/TopNavBar'

export interface DomainSubItem {
  to: string
  label: string
  allowedRoles?: string[]
}

export interface DomainGroup {
  label: string
  to: string
  allowedRoles?: string[]
  items: DomainSubItem[]
}

const INTERNAL_DOMAINS: DomainGroup[] = [
  {
    label: 'Academic',
    to: '/internal/academic',
    items: [
      { to: '/internal/courses', label: 'Courses' },
      { to: '/internal/enrollments', label: 'Enrollments' },
      {
        to: '/internal/proposals',
        label: 'Proposals',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'dept_leader', 'academic_leader', 'course_creator', 'finance', 'facilitator'],
      },
      { to: '/internal/calendar', label: 'Calendar' },
    ],
  },
  {
    label: 'Finance',
    to: '/internal/finance',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'finance', 'course_creator'],
    items: [
      {
        to: '/internal/payments',
        label: 'Payments',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'finance'],
      },
      {
        to: '/internal/budget',
        label: 'Budget',
        allowedRoles: ['course_creator', 'dept_leader', 'vernonedu_admin', 'ceo'],
      },
      {
        to: '/internal/profit-split',
        label: 'Profit Split',
        allowedRoles: ['ceo', 'vernonedu_admin', 'course_creator'],
      },
      {
        to: '/internal/vouchers',
        label: 'Vouchers',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
      },
    ],
  },
  {
    label: 'Operations',
    to: '/internal/operations',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
    items: [
      {
        to: '/internal/franchises',
        label: 'Franchises',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
      },
      {
        to: '/internal/partners',
        label: 'Partners',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
      },
      {
        to: '/internal/notifications',
        label: 'Notifications',
        allowedRoles: ['admin', 'vernonedu_admin'],
      },
    ],
  },
  {
    label: 'HR',
    to: '/internal/hr',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'dept_leader', 'academic_leader'],
    items: [
      {
        to: '/internal/students',
        label: 'Students',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
      },
      {
        to: '/internal/departments',
        label: 'Departments',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'dept_leader', 'academic_leader'],
      },
      {
        to: '/internal/team-members',
        label: 'Team Members',
        allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'dept_leader', 'academic_leader'],
      },
    ],
  },
]

export function getInternalDomains(role: string): DomainGroup[] {
  const normalized = role.toLowerCase()
  return INTERNAL_DOMAINS
    .filter(d => !d.allowedRoles || d.allowedRoles.includes(normalized))
    .map(d => ({
      ...d,
      items: d.items.filter(item => !item.allowedRoles || item.allowedRoles.includes(normalized)),
    }))
}

// Legacy — no longer used by InternalPortal but kept for type compatibility
export function getInternalNavItems(_role: string): NavItem[] {
  return []
}
