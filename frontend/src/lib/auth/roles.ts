export const ROLES = {
  // External
  STUDENT: 'student',
  FRANCHISEE: 'franchisee',
  // Staff — leadership
  DIRECTOR: 'director',
  CEO: 'ceo',
  // Staff — education
  EDUCATION_LEADER: 'education_leader',
  DEPT_LEADER: 'dept_leader',
  COURSE_OWNER: 'course_owner',
  COURSE_CREATOR: 'course_creator',
  FACILITATOR: 'facilitator',
  ACADEMIC_LEADER: 'academic_leader',
  // Staff — operations
  OPERATION_LEADER: 'operation_leader',
  OPERATION_ADMIN: 'operation_admin',
  CUSTOMER_SERVICE: 'customer_service',
  MARKETING: 'marketing',
  // Staff — accounting
  ACCOUNTING_LEADER: 'accounting_leader',
  ACCOUNTING_STAFF: 'accounting_staff',
  FINANCE: 'finance',
  // Misc
  ADMIN: 'admin',
  VERNONEDU_ADMIN: 'vernonedu_admin',
} as const

export type Role = typeof ROLES[keyof typeof ROLES]

export const STAFF_ROLES: Role[] = [
  ROLES.DIRECTOR, ROLES.CEO, ROLES.EDUCATION_LEADER, ROLES.DEPT_LEADER,
  ROLES.COURSE_OWNER, ROLES.COURSE_CREATOR, ROLES.FACILITATOR, ROLES.ACADEMIC_LEADER,
  ROLES.OPERATION_LEADER, ROLES.OPERATION_ADMIN, ROLES.CUSTOMER_SERVICE, ROLES.MARKETING,
  ROLES.ACCOUNTING_LEADER, ROLES.ACCOUNTING_STAFF, ROLES.FINANCE,
  ROLES.ADMIN, ROLES.VERNONEDU_ADMIN,
]

export const ROLE_LABELS: Record<Role, string> = {
  student: 'Siswa',
  franchisee: 'Franchisee',
  director: 'Direktur',
  ceo: 'CEO',
  education_leader: 'Education Leader',
  dept_leader: 'Department Leader',
  course_owner: 'Course Owner',
  course_creator: 'Course Creator',
  facilitator: 'Fasilitator',
  academic_leader: 'Academic Leader',
  operation_leader: 'Operation Leader',
  operation_admin: 'Operation Admin',
  customer_service: 'Customer Service',
  marketing: 'Marketing',
  accounting_leader: 'Accounting Leader',
  accounting_staff: 'Accounting Staff',
  finance: 'Finance',
  admin: 'Admin',
  vernonedu_admin: 'Platform Admin',
}
