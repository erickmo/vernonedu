// ─── Employee ──────────────────────────────────────────────────────────────────

export interface Employee {
  id: string
  user_id: string
  employee_number: string
  department_id: string | null
  department_name?: string
  user_name?: string
  user_email?: string
  user_roles?: string[]
  position: string
  hire_date: string
  status: 'active' | 'inactive' | 'resigned' | 'terminated'
  phone: string
  address: string
  base_salary: number
  bank_name: string
  bank_account: string
  contract_type: string
  contract_end: string | null
  notes: string
  created_at: number
  updated_at: number
}

export type EmployeeStatus = Employee['status']

export const EMPLOYEE_STATUS_LABELS: Record<EmployeeStatus, string> = {
  active: 'Aktif',
  inactive: 'Nonaktif',
  resigned: 'Resign',
  terminated: 'Terminasi',
}

export const EMPLOYEE_STATUS_COLORS: Record<EmployeeStatus, { bg: string; color: string }> = {
  active: { bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  inactive: { bg: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' },
  resigned: { bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  terminated: { bg: 'var(--color-error-light)', color: 'var(--color-error-dark)' },
}

// ─── Staff Attendance ──────────────────────────────────────────────────────────

export interface StaffAttendance {
  id: string
  employee_id: string
  employee_name?: string
  date: string
  status: 'present' | 'absent' | 'late' | 'leave' | 'sick'
  clock_in: string | null
  clock_out: string | null
  note: string
  created_at: number
  updated_at: number
}

export type AttendanceStatus = StaffAttendance['status']

export const ATTENDANCE_STATUS_LABELS: Record<AttendanceStatus, string> = {
  present: 'Hadir',
  absent: 'Absen',
  late: 'Terlambat',
  leave: 'Cuti',
  sick: 'Sakit',
}

export const ATTENDANCE_STATUS_COLORS: Record<AttendanceStatus, { bg: string; color: string }> = {
  present: { bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  absent: { bg: 'var(--color-error-light)', color: 'var(--color-error-dark)' },
  late: { bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  leave: { bg: 'var(--color-info-light)', color: 'var(--color-info-dark)' },
  sick: { bg: 'var(--color-primary-subtle)', color: 'var(--color-primary)' },
}

export interface AttendanceSummary {
  total_working_days: number
  present: number
  absent: number
  late: number
  leave: number
  sick: number
}

// ─── Leave Requests ────────────────────────────────────────────────────────────

export interface LeaveRequest {
  id: string
  employee_id: string
  employee_name?: string
  leave_type: 'annual' | 'sick' | 'personal' | 'maternity' | 'other'
  start_date: string
  end_date: string
  reason: string
  status: 'pending' | 'approved' | 'rejected'
  reviewed_by: string | null
  reviewed_at: string | null
  created_at: number
  updated_at: number
}

export type LeaveType = LeaveRequest['leave_type']
export type LeaveStatus = LeaveRequest['status']

export const LEAVE_TYPE_LABELS: Record<LeaveType, string> = {
  annual: 'Tahunan',
  sick: 'Sakit',
  personal: 'Pribadi',
  maternity: 'Melahirkan',
  other: 'Lainnya',
}

export const LEAVE_STATUS_LABELS: Record<LeaveStatus, string> = {
  pending: 'Menunggu',
  approved: 'Disetujui',
  rejected: 'Ditolak',
}

export const LEAVE_STATUS_COLORS: Record<LeaveStatus, { bg: string; color: string }> = {
  pending: { bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  approved: { bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  rejected: { bg: 'var(--color-error-light)', color: 'var(--color-error-dark)' },
}

// ─── Payroll ───────────────────────────────────────────────────────────────────

export interface PayrollPeriod {
  id: string
  period: string
  start_date: string
  end_date: string
  status: 'draft' | 'processing' | 'approved' | 'disbursed'
  approved_by: string | null
  approved_at: string | null
  disbursed_at: string | null
  notes: string
  total_amount?: number
  created_at: number
  updated_at: number
}

export type PayrollPeriodStatus = PayrollPeriod['status']

export const PAYROLL_STATUS_LABELS: Record<PayrollPeriodStatus, string> = {
  draft: 'Draft',
  processing: 'Diproses',
  approved: 'Disetujui',
  disbursed: 'Disalurkan',
}

export const PAYROLL_STATUS_COLORS: Record<PayrollPeriodStatus, { bg: string; color: string }> = {
  draft: { bg: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' },
  processing: { bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  approved: { bg: 'var(--color-info-light)', color: 'var(--color-info-dark)' },
  disbursed: { bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
}

export interface PayrollItem {
  id: string
  payroll_period_id: string
  employee_id: string
  employee_name?: string
  base_salary: number
  facilitator_sessions: number
  facilitator_fee: number
  attendance_deduction: number
  bonus: number
  total_amount: number
  status: 'pending' | 'paid'
  notes: string
  created_at: number
  updated_at: number
}

// ─── Form Payloads ─────────────────────────────────────────────────────────────

export interface EmployeeFormData {
  user_id: string
  employee_number: string
  department_id: string
  position: string
  hire_date: string
  base_salary: number
  phone: string
  address: string
  bank_name: string
  bank_account: string
  contract_type: string
  contract_end: string
  notes: string
}

export interface PayrollPeriodFormData {
  period: string
  start_date: string
  end_date: string
  notes: string
}

export interface AttendanceFormData {
  employee_id: string
  date: string
  status: AttendanceStatus
  clock_in: string
  clock_out: string
  note: string
}

export interface LeaveFormData {
  employee_id: string
  leave_type: LeaveType
  start_date: string
  end_date: string
  reason: string
}
