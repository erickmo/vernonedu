import type { NavItem } from '@/components/layout/TopNavBar'

interface RoleNavItem extends NavItem {
  allowedRoles?: string[]
}

const INTERNAL_NAV: RoleNavItem[] = [
  { to: '/internal', label: 'Dashboard', end: true },
  { to: '/internal/enrollments', label: 'Enrollments' },
  {
    to: '/internal/payments',
    label: 'Payments',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'finance'],
  },
  { to: '/internal/courses', label: 'Courses' },
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
  {
    to: '/internal/proposals',
    label: 'Proposals',
    allowedRoles: [
      'ceo', 'admin', 'vernonedu_admin',
      'dept_leader', 'academic_leader', 'course_creator', 'finance', 'facilitator',
    ],
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
    to: '/internal/partners',
    label: 'Partners',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
  },
  {
    to: '/internal/vouchers',
    label: 'Vouchers',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
  },
  { to: '/internal/calendar', label: 'Calendar' },
  {
    to: '/internal/franchises',
    label: 'Franchises',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
  },
  {
    to: '/internal/notifications',
    label: 'Notifications',
    allowedRoles: ['admin', 'vernonedu_admin'],
  },
]

export function getInternalNavItems(role: string): NavItem[] {
  return INTERNAL_NAV
    .filter((item) => !item.allowedRoles || item.allowedRoles.includes(role))
    .map(({ allowedRoles: _r, ...item }) => item)
}
