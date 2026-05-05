import type { LucideIcon } from 'lucide-react'
import {
  LayoutDashboard,
  BookOpen,
  CalendarDays,
  UserPlus,
  GraduationCap,
  Trophy,
  Award,
  Building2,
  Magnet,
  MapPin,
  CreditCard,
  Megaphone,
  Users,
  Handshake,
  Wallet,
  UserCog,
  FolderKanban,
  Rocket,
  FileText,
  CheckCircle,
  Bell,
  Settings,
  ArrowLeftRight,
  Receipt,
  ClipboardList,
  ScrollText,
  Landmark,
  LayoutList,
  BarChart2,
  CalendarCheck,
  CalendarOff,
} from 'lucide-react'

// ─── Permission helpers ─────────────────────────────────────────────────────────

type RoleKey =
  | 'director'
  | 'education_leader'
  | 'dept_leader'
  | 'course_owner'
  | 'facilitator'
  | 'operation_leader'
  | 'operation_admin'
  | 'customer_service'
  | 'marketing'
  | 'accounting_leader'
  | 'accounting_staff'

interface PermissionContext {
  roles: string[]
}

const OPERATION_ROLES: RoleKey[] = [
  'operation_leader',
  'operation_admin',
  'customer_service',
  'marketing',
]

function hasRole(ctx: PermissionContext, role: string | string[]): boolean {
  const roles = ctx.roles ?? []
  if (Array.isArray(role)) return role.some(r => roles.includes(r))
  return roles.includes(role)
}

function hasAnyRole(ctx: PermissionContext, roles: string[]): boolean {
  return hasRole(ctx, roles)
}

function canManageCourse(ctx: PermissionContext): boolean {
  return hasAnyRole(ctx, [
    'director',
    'education_leader',
    'dept_leader',
    'course_owner',
  ])
}

function isOperationTeam(ctx: PermissionContext): boolean {
  return hasAnyRole(ctx, OPERATION_ROLES)
}

function canManageStudent(ctx: PermissionContext): boolean {
  return hasAnyRole(ctx, [
    'director',
    'operation_leader',
    'customer_service',
  ])
}

function canViewTalentPool(ctx: PermissionContext): boolean {
  return hasAnyRole(ctx, [
    'director',
    'education_leader',
    'dept_leader',
    'course_owner',
  ])
}

function canManageLocation(ctx: PermissionContext): boolean {
  return hasAnyRole(ctx, [
    'director',
    'operation_leader',
    'operation_admin',
  ])
}

function canViewAccounting(ctx: PermissionContext): boolean {
  return hasAnyRole(ctx, [
    'director',
    'accounting_leader',
    'accounting_staff',
  ])
}

function canViewCrm(ctx: PermissionContext): boolean {
  return hasAnyRole(ctx, [
    'director',
    'operation_leader',
    'marketing',
    'customer_service',
  ])
}

function canViewHrm(ctx: PermissionContext): boolean {
  return hasAnyRole(ctx, [
    'director',
    'education_leader',
    'dept_leader',
    'operation_leader',
  ])
}

function canViewBusinessDev(ctx: PermissionContext): boolean {
  return hasAnyRole(ctx, [
    'director',
    'education_leader',
    'operation_leader',
  ])
}

function canAccessAdmin(ctx: PermissionContext): boolean {
  return hasRole(ctx, 'director') || ctx.roles.length > 0
}

// ─── Nav item definition ────────────────────────────────────────────────────────

export interface NavItem {
  key: string
  label: string
  icon: LucideIcon
  path: string
  hasAccess: (ctx: PermissionContext) => boolean
}

export interface NavSection {
  key: string
  label: string
  icon: LucideIcon
  items: NavItem[]
}

// ─── All nav items ──────────────────────────────────────────────────────────────

const ALL_ITEMS: NavItem[] = [
  {
    key: 'dashboard',
    label: 'Dashboard',
    icon: LayoutDashboard,
    path: '/dashboard',
    hasAccess: () => true,
  },
  {
    key: 'course',
    label: 'Kurikulum',
    icon: BookOpen,
    path: '/course',
    hasAccess: (ctx) => canManageCourse(ctx) || hasRole(ctx, 'facilitator'),
  },
  {
    key: 'course-batches',
    label: 'Kelas (Batch)',
    icon: CalendarDays,
    path: '/course-batches',
    hasAccess: (ctx) =>
      canManageCourse(ctx) || hasRole(ctx, 'facilitator') || isOperationTeam(ctx),
  },
  {
    key: 'enrollments',
    label: 'Enrollment',
    icon: UserPlus,
    path: '/enrollments',
    hasAccess: (ctx) => canManageStudent(ctx) || canManageCourse(ctx),
  },
  {
    key: 'students',
    label: 'Siswa',
    icon: GraduationCap,
    path: '/students',
    hasAccess: (ctx) => canManageStudent(ctx),
  },
  {
    key: 'talentpool',
    label: 'Talent Pool',
    icon: Trophy,
    path: '/talentpool',
    hasAccess: (ctx) => canViewTalentPool(ctx),
  },
  {
    key: 'certificates',
    label: 'Sertifikat',
    icon: Award,
    path: '/certificates',
    hasAccess: (ctx) => canManageCourse(ctx) || hasRole(ctx, 'customer_service'),
  },
  {
    key: 'departments',
    label: 'Departemen',
    icon: Building2,
    path: '/pengembangan/departments',
    hasAccess: (ctx) =>
      hasAnyRole(ctx, ['director', 'education_leader', 'dept_leader']),
  },
  {
    key: 'leads',
    label: 'Leads',
    icon: Magnet,
    path: '/leads',
    hasAccess: (ctx) =>
      hasAnyRole(ctx, [
        'director',
        'operation_leader',
        'customer_service',
        'marketing',
      ]),
  },
  {
    key: 'locations',
    label: 'Lokasi',
    icon: MapPin,
    path: '/pengembangan/locations',
    hasAccess: (ctx) => canManageLocation(ctx),
  },
  {
    key: 'payments',
    label: 'Pembayaran',
    icon: CreditCard,
    path: '/payments',
    hasAccess: (ctx) => canManageStudent(ctx) || canViewAccounting(ctx),
  },
  {
    key: 'marketing',
    label: 'Marketing',
    icon: Megaphone,
    path: '/marketing',
    hasAccess: (ctx) =>
      hasAnyRole(ctx, ['director', 'operation_leader', 'marketing']),
  },
  {
    key: 'crm',
    label: 'CRM',
    icon: Users,
    path: '/crm',
    hasAccess: (ctx) => canViewCrm(ctx),
  },
  {
    key: 'partners',
    label: 'Partner',
    icon: Handshake,
    path: '/partners',
    hasAccess: (ctx) =>
      hasAnyRole(ctx, ['director', 'operation_leader', 'education_leader']),
  },
  {
    key: 'finance',
    label: 'Keuangan',
    icon: Wallet,
    path: '/finance',
    hasAccess: (ctx) => canViewAccounting(ctx),
  },
  {
    key: 'hrm',
    label: 'SDM',
    icon: UserCog,
    path: '/hrm',
    hasAccess: (ctx) => canViewHrm(ctx),
  },
  {
    key: 'projects',
    label: 'Proyek',
    icon: FolderKanban,
    path: '/projects',
    hasAccess: (ctx) =>
      hasAnyRole(ctx, ['director', 'education_leader', 'operation_leader']),
  },
  {
    key: 'business-development',
    label: 'Business Dev',
    icon: Rocket,
    path: '/business-development',
    hasAccess: (ctx) => canViewBusinessDev(ctx),
  },
  {
    key: 'cms',
    label: 'CMS',
    icon: FileText,
    path: '/cms',
    hasAccess: (ctx) => hasRole(ctx, 'director'),
  },
  {
    key: 'approvals',
    label: 'Persetujuan',
    icon: CheckCircle,
    path: '/approvals',
    hasAccess: (ctx) => canAccessAdmin(ctx),
  },
  {
    key: 'notifications',
    label: 'Notifikasi',
    icon: Bell,
    path: '/notifications',
    hasAccess: (ctx) => canAccessAdmin(ctx),
  },
  {
    key: 'settings',
    label: 'Pengaturan',
    icon: Settings,
    path: '/settings',
    hasAccess: (ctx) => hasRole(ctx, 'director'),
  },
]

// ─── Finance sub-nav items ──────────────────────────────────────────────────────

const FINANCE_ITEMS: NavItem[] = [
  {
    key: 'finance-overview',
    label: 'Overview',
    icon: Wallet,
    path: '/finance',
    hasAccess: (ctx) => canViewAccounting(ctx),
  },
  {
    key: 'finance-transactions',
    label: 'Transaksi',
    icon: ArrowLeftRight,
    path: '/finance/transactions',
    hasAccess: (ctx) => canViewAccounting(ctx),
  },
  {
    key: 'finance-invoices',
    label: 'Invoice',
    icon: Receipt,
    path: '/finance/invoices',
    hasAccess: (ctx) => canViewAccounting(ctx),
  },
  {
    key: 'finance-payables',
    label: 'Tagihan',
    icon: ClipboardList,
    path: '/finance/payables',
    hasAccess: (ctx) => canViewAccounting(ctx),
  },
  {
    key: 'finance-journals',
    label: 'Jurnal',
    icon: ScrollText,
    path: '/finance/journals',
    hasAccess: (ctx) => canViewAccounting(ctx),
  },
  {
    key: 'finance-bank-accounts',
    label: 'Rekening',
    icon: Landmark,
    path: '/finance/bank-accounts',
    hasAccess: (ctx) => canViewAccounting(ctx),
  },
  {
    key: 'finance-coa',
    label: 'Bagan Akun',
    icon: LayoutList,
    path: '/finance/chart-of-accounts',
    hasAccess: (ctx) => canViewAccounting(ctx),
  },
  {
    key: 'finance-reports',
    label: 'Laporan',
    icon: BarChart2,
    path: '/finance/reports',
    hasAccess: (ctx) => canViewAccounting(ctx),
  },
]

// ─── HRM sub-nav items ──────────────────────────────────────────────────────────

const HRM_ITEMS: NavItem[] = [
  {
    key: 'hrm-employees',
    label: 'Karyawan',
    icon: UserCog,
    path: '/hrm',
    hasAccess: (ctx) => canViewHrm(ctx),
  },
  {
    key: 'hrm-attendance',
    label: 'Kehadiran',
    icon: CalendarCheck,
    path: '/hrm/attendance',
    hasAccess: (ctx) => canViewHrm(ctx),
  },
  {
    key: 'hrm-leaves',
    label: 'Cuti',
    icon: CalendarOff,
    path: '/hrm/leaves',
    hasAccess: (ctx) => canViewHrm(ctx),
  },
  {
    key: 'hrm-payroll',
    label: 'Penggajian',
    icon: CreditCard,
    path: '/hrm/payroll',
    hasAccess: (ctx) => canViewHrm(ctx),
  },
]

// ─── Section grouping ───────────────────────────────────────────────────────────

export const NAV_SECTIONS: NavSection[] = [
  {
    key: 'utama',
    label: 'Utama',
    icon: LayoutDashboard,
    items: [ALL_ITEMS[0]], // Dashboard
  },
  {
    key: 'pendidikan',
    label: 'Pendidikan',
    icon: BookOpen,
    items: ALL_ITEMS.slice(1, 7), // Kurikulum..Sertifikat
  },
  {
    key: 'operasi',
    label: 'Operasi',
    icon: MapPin,
    items: [ALL_ITEMS[8], ALL_ITEMS[10]], // Leads, Pembayaran
  },
  {
    key: 'marketing',
    label: 'Marketing',
    icon: Megaphone,
    items: ALL_ITEMS.slice(11, 14), // Marketing, CRM, Partner
  },
  {
    key: 'keuangan',
    label: 'Keuangan',
    icon: Wallet,
    items: FINANCE_ITEMS,
  },
  {
    key: 'sdm',
    label: 'SDM',
    icon: UserCog,
    items: HRM_ITEMS,
  },
  {
    key: 'pengembangan',
    label: 'Pengembangan',
    icon: Rocket,
    items: [ALL_ITEMS[7], ALL_ITEMS[9], ...ALL_ITEMS.slice(16, 18)], // Departemen, Lokasi, Proyek, Business Dev
  },
  {
    key: 'sistem',
    label: 'Sistem',
    icon: Settings,
    items: ALL_ITEMS.slice(18), // CMS, Persetujuan, Notifikasi, Pengaturan
  },
]

// ─── Filter nav items by user permissions ───────────────────────────────────────

export function getFilteredSections(ctx: PermissionContext): NavSection[] {
  return NAV_SECTIONS
    .map((section) => ({
      ...section,
      items: section.items.filter((item) => item.hasAccess(ctx)),
    }))
    .filter((section) => section.items.length > 0)
}

export function getActiveSection(
  pathname: string,
  sections: NavSection[],
): NavSection | null {
  return sections.find((section) =>
    section.items.some((item) => {
      if (item.path === '/dashboard') {
        return pathname === '/dashboard' || pathname === '/'
      }
      return pathname.startsWith(item.path)
    }),
  ) ?? null
}
