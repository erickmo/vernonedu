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
      { to: '/internal/courses', label: 'Courses', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader', 'course_owner', 'facilitator'] },
      { to: '/internal/enrollments', label: 'Enrollments', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader', 'course_owner'] },
      { to: '/internal/batches', label: 'Batches', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader', 'course_owner', 'facilitator'] },
      { to: '/internal/certificates', label: 'Certificates', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader', 'course_owner'] },
      { to: '/internal/proposals', label: 'Proposals', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader', 'course_owner'] },
      { to: '/internal/my-sessions', label: 'My Sessions', allowedRoles: ['facilitator', 'course_owner'] },
      { to: '/internal/calendar', label: 'Calendar', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader', 'course_owner', 'facilitator'] },
    ],
  },
  {
    label: 'Finance',
    to: '/internal/finance',
    allowedRoles: ['ceo', 'admin', 'director', 'accounting_leader', 'accounting_staff'],
    items: [
      { to: '/internal/payments', label: 'Payments', allowedRoles: ['ceo', 'admin', 'director', 'accounting_leader', 'accounting_staff', 'operation_leader'] },
      { to: '/internal/invoices', label: 'Invoices', allowedRoles: ['ceo', 'admin', 'director', 'accounting_leader', 'accounting_staff'] },
      { to: '/internal/finance/transactions', label: 'Transactions', allowedRoles: ['ceo', 'admin', 'director', 'accounting_leader', 'accounting_staff'] },
      { to: '/internal/finance/payables', label: 'Payables', allowedRoles: ['ceo', 'admin', 'director', 'accounting_leader', 'accounting_staff'] },
      { to: '/internal/finance/coa', label: 'Chart of Accounts', allowedRoles: ['ceo', 'admin', 'director', 'accounting_leader'] },
      { to: '/internal/finance/accounts', label: 'Finance Accounts', allowedRoles: ['ceo', 'admin', 'director', 'accounting_leader', 'accounting_staff'] },
      { to: '/internal/budget', label: 'Budget', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader', 'course_owner'] },
      { to: '/internal/profit-split', label: 'Profit Split', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/vouchers', label: 'Vouchers', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/finance/reports', label: 'Reports', allowedRoles: ['ceo', 'admin', 'director', 'accounting_leader'] },
      { to: '/internal/finance/commissions', label: 'Commissions', allowedRoles: ['ceo', 'admin', 'director', 'accounting_leader'] },
      { to: '/internal/finance/analysis', label: 'Analysis', allowedRoles: ['ceo', 'admin', 'director', 'accounting_leader'] },
    ],
  },
  {
    label: 'Operations',
    to: '/internal/operations',
    allowedRoles: ['ceo', 'admin', 'director', 'operation_leader', 'operation_admin', 'customer_service', 'marketing'],
    items: [
      { to: '/internal/leads', label: 'Leads', allowedRoles: ['ceo', 'admin', 'director', 'operation_leader', 'operation_admin', 'customer_service', 'marketing'] },
      { to: '/internal/notifications', label: 'Notifications', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/projects', label: 'Projects', allowedRoles: ['ceo', 'admin', 'director'] },
    ],
  },
  {
    label: 'HR',
    to: '/internal/hr',
    allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader'],
    items: [
      { to: '/internal/students', label: 'Students', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'operation_leader', 'customer_service'] },
      { to: '/internal/users', label: 'Users', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/team-members', label: 'Team Members', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader'] },
      { to: '/internal/departments', label: 'Departments', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader'] },
      { to: '/internal/talentpool', label: 'Talent Pool', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader'] },
      { to: '/internal/inventory', label: 'Inventory', allowedRoles: ['ceo', 'admin', 'director', 'operation_leader'] },
      { to: '/internal/approvals', label: 'Approvals', allowedRoles: ['ceo', 'admin', 'director', 'education_leader', 'dept_leader'] },
    ],
  },
  {
    label: 'BizDev',
    to: '/internal/bizdev',
    allowedRoles: ['ceo', 'admin', 'director'],
    items: [
      { to: '/internal/bmc', label: 'Business Model Canvas', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/okr', label: 'OKR', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/investments', label: 'Investments', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/delegations', label: 'Delegations', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/franchises', label: 'Franchises', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/partners', label: 'Partners', allowedRoles: ['ceo', 'admin', 'director', 'operation_leader'] },
      { to: '/internal/buildings', label: 'Buildings', allowedRoles: ['ceo', 'admin', 'director', 'operation_leader', 'operation_admin'] },
    ],
  },
  {
    label: 'Marketing',
    to: '/internal/marketing',
    allowedRoles: ['ceo', 'admin', 'director', 'marketing'],
    items: [
      { to: '/internal/marketing/posts', label: 'Posts', allowedRoles: ['ceo', 'admin', 'director', 'marketing'] },
      { to: '/internal/marketing/class-docs', label: 'Class Docs', allowedRoles: ['ceo', 'admin', 'director', 'marketing'] },
      { to: '/internal/marketing/referral-partners', label: 'Referral Partners', allowedRoles: ['ceo', 'admin', 'director', 'marketing'] },
      { to: '/internal/marketing/pr', label: 'PR', allowedRoles: ['ceo', 'admin', 'director', 'marketing'] },
    ],
  },
  {
    label: 'Settings',
    to: '/internal/settings',
    allowedRoles: ['ceo', 'admin', 'director'],
    items: [
      { to: '/internal/settings/general', label: 'General', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/settings/branches', label: 'Branches', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/settings/holidays', label: 'Holidays', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/settings/facilitator-levels', label: 'Facilitator Levels', allowedRoles: ['ceo', 'admin', 'director'] },
      { to: '/internal/settings/commissions', label: 'Commission Config', allowedRoles: ['ceo', 'admin', 'director'] },
    ],
  },
  {
    label: 'CMS',
    to: '/internal/cms',
    allowedRoles: ['ceo', 'admin', 'director', 'marketing'],
    items: [
      { to: '/internal/cms/pages', label: 'Pages', allowedRoles: ['ceo', 'admin', 'director', 'marketing'] },
      { to: '/internal/cms/articles', label: 'Articles', allowedRoles: ['ceo', 'admin', 'director', 'marketing'] },
      { to: '/internal/cms/faq', label: 'FAQ', allowedRoles: ['ceo', 'admin', 'director', 'marketing'] },
      { to: '/internal/cms/testimonials', label: 'Testimonials', allowedRoles: ['ceo', 'admin', 'director', 'marketing'] },
      { to: '/internal/cms/media', label: 'Media', allowedRoles: ['ceo', 'admin', 'director', 'marketing'] },
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
