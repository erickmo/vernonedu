import { ROLES, type Role } from './roles'

export type Action = 'create' | 'read' | 'update' | 'delete' | 'approve' | 'list'

export type Resource =
  // Curriculum
  | 'mastercourse' | 'coursetype' | 'courseversion' | 'coursemodule'
  | 'certificatetemplate' | 'internshipconfig' | 'charactertestconfig' | 'course'
  // Operations
  | 'coursebatch' | 'batchschedule' | 'building' | 'room' | 'holiday'
  | 'attendance' | 'facilitator_assignment'
  // Enrollment & Cert
  | 'enrollment' | 'enrollment.own' | 'invoice' | 'certificate' | 'certificate.own'
  | 'lead' | 'studentappaccess' | 'crmlog'
  // Accounting
  | 'coa' | 'finance_account' | 'transaction' | 'journal_entry' | 'payable'
  | 'report' | 'budget_vs_actual' | 'commission' | 'financial_alerts'
  // BizDev
  | 'bmc' | 'okr' | 'investment_plan' | 'delegation' | 'approval'
  | 'branch' | 'mou' | 'project'
  // Marketing & CMS
  | 'cms_page' | 'cms_article' | 'cms_faq' | 'cms_testimonial' | 'cms_media'
  | 'marketing_post' | 'classdoc_post' | 'referral_partner'
  // HR & Settings
  | 'user' | 'facilitator_levels' | 'commission_config' | 'settings'
  | 'notification' | 'talentpool' | 'item' | 'canvas' | 'designthinking'

const ALL: Action[] = ['create', 'read', 'update', 'delete', 'approve', 'list']

const KNOWN_RESOURCES = new Set<Resource>([
  // Curriculum
  'mastercourse', 'coursetype', 'courseversion', 'coursemodule',
  'certificatetemplate', 'internshipconfig', 'charactertestconfig', 'course',
  // Operations
  'coursebatch', 'batchschedule', 'building', 'room', 'holiday',
  'attendance', 'facilitator_assignment',
  // Enrollment & Cert
  'enrollment', 'enrollment.own', 'invoice', 'certificate', 'certificate.own',
  'lead', 'studentappaccess', 'crmlog',
  // Accounting
  'coa', 'finance_account', 'transaction', 'journal_entry', 'payable',
  'report', 'budget_vs_actual', 'commission', 'financial_alerts',
  // BizDev
  'bmc', 'okr', 'investment_plan', 'delegation', 'approval',
  'branch', 'mou', 'project',
  // Marketing & CMS
  'cms_page', 'cms_article', 'cms_faq', 'cms_testimonial', 'cms_media',
  'marketing_post', 'classdoc_post', 'referral_partner',
  // HR & Settings
  'user', 'facilitator_levels', 'commission_config', 'settings',
  'notification', 'talentpool', 'item', 'canvas', 'designthinking',
])

type ResourcePerms = Partial<Record<Resource, Action[]>> & { '*'?: Action[] }
type Matrix = Partial<Record<Role, ResourcePerms>>

const MATRIX: Matrix = {
  [ROLES.DIRECTOR]: { '*': ALL },
  [ROLES.CEO]: { '*': ALL },
  [ROLES.ADMIN]: { '*': ALL },
  [ROLES.VERNONEDU_ADMIN]: { '*': ALL },

  [ROLES.EDUCATION_LEADER]: {
    mastercourse: ALL, coursetype: ALL, courseversion: ALL, coursemodule: ALL,
    certificatetemplate: ALL, internshipconfig: ALL, charactertestconfig: ALL,
    course: ALL, coursebatch: ALL, certificate: ALL, talentpool: ALL,
  },
  [ROLES.ACADEMIC_LEADER]: {
    mastercourse: ALL, coursetype: ALL, courseversion: ALL, coursemodule: ALL,
    course: ALL, coursebatch: ALL, talentpool: ALL,
  },
  [ROLES.DEPT_LEADER]: {
    mastercourse: ALL, coursetype: ALL, courseversion: ALL, coursemodule: ALL,
    course: ALL, coursebatch: ALL, certificate: ['create', 'read', 'list', 'approve'],
    talentpool: ALL, approval: ['read', 'approve', 'list'],
  },
  [ROLES.COURSE_OWNER]: {
    course: ALL, coursebatch: ALL, coursetype: ['read', 'list'],
    courseversion: ['read', 'list'], coursemodule: ['read', 'list'],
    enrollment: ['read', 'list'],
  },
  [ROLES.COURSE_CREATOR]: {
    course: ALL, coursebatch: ['create', 'read', 'list'],
    coursetype: ALL,
    courseversion: ['create', 'read', 'update', 'list'],
    coursemodule: ALL,
  },
  [ROLES.FACILITATOR]: {
    coursebatch: ['read', 'list'], attendance: ['create', 'read', 'update', 'list'],
    enrollment: ['read', 'list'],
  },

  [ROLES.OPERATION_LEADER]: {
    coursebatch: ALL, batchschedule: ALL, building: ALL, room: ALL, holiday: ALL,
    lead: ALL, approval: ['read', 'approve', 'list'],
  },
  [ROLES.OPERATION_ADMIN]: {
    coursebatch: ['create', 'read', 'update', 'list'],
    batchschedule: ALL, building: ALL, room: ALL, holiday: ALL,
    facilitator_assignment: ALL,
  },
  [ROLES.CUSTOMER_SERVICE]: {
    enrollment: ALL, invoice: ['create', 'read', 'list'], lead: ALL,
    crmlog: ALL, studentappaccess: ['create', 'read', 'list'],
  },
  [ROLES.MARKETING]: {
    lead: ALL, marketing_post: ALL, classdoc_post: ALL, referral_partner: ALL,
    cms_page: ALL, cms_article: ALL, cms_faq: ALL, cms_testimonial: ALL, cms_media: ALL,
  },

  [ROLES.ACCOUNTING_LEADER]: {
    coa: ALL, finance_account: ALL, transaction: ALL, journal_entry: ALL,
    payable: ALL, report: ALL, budget_vs_actual: ALL,
    commission: ALL, financial_alerts: ALL, invoice: ALL,
  },
  [ROLES.ACCOUNTING_STAFF]: {
    transaction: ALL, journal_entry: ['create', 'read', 'list'],
    payable: ['create', 'read', 'update', 'list'], invoice: ALL,
    finance_account: ['read', 'list'],
  },
  [ROLES.FINANCE]: {
    transaction: ALL, payable: ALL, invoice: ALL, report: ALL,
    budget_vs_actual: ALL,
  },

  [ROLES.STUDENT]: {
    'enrollment.own': ['read', 'list'], 'certificate.own': ['read', 'list'],
    canvas: ALL, designthinking: ALL,
  },
  [ROLES.FRANCHISEE]: {
    coursebatch: ['read', 'list'], enrollment: ['read', 'list'],
    invoice: ['read', 'list'], user: ['read', 'list'],
  },
}

export function canAccess(
  role: Role | string | null | undefined,
  action: Action,
  resource: Resource,
): boolean {
  if (!role) return false
  if (!KNOWN_RESOURCES.has(resource)) return false
  const perms = MATRIX[role as Role]
  if (!perms) return false
  if (perms['*']?.includes(action)) return true
  const actions = perms[resource]
  return Array.isArray(actions) && actions.includes(action)
}
