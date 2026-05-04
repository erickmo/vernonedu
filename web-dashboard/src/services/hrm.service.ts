import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

function toPaginated<T>(raw: unknown, fallback: T[]): PaginatedResponse<T> {
  const r = raw as Record<string, unknown>
  if (r && typeof r === 'object' && 'items' in r) return r as unknown as PaginatedResponse<T>
  const list = Array.isArray(raw) ? raw : fallback
  return { items: list as T[], total: list.length, limit: 9999, offset: 0 }
}

function buildQS(params?: Record<string, unknown>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') q.set(k, String(v))
  })
  const s = q.toString()
  return s ? `?${s}` : ''
}

function unwrap<T>(res: unknown): T {
  const r = res as Record<string, unknown>
  return (r?.data ?? res) as T
}

// ─── Employees ─────────────────────────────────────────────────────────────────

export const hrmService = {
  // ── Employees ────────────────────────────────────────────────────────────────

  listEmployees: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<any>(`/hrm/employees${buildQS(params)}`)
      .then(r => toPaginated(unwrap(r), [])),

  getEmployee: (id: string) =>
    apiClient.get<any>(`/hrm/employees/${id}`).then(r => unwrap(r)),

  createEmployee: (data: unknown) =>
    apiClient.post<any>('/hrm/employees', data),

  updateEmployee: (id: string, data: unknown) =>
    apiClient.put<any>(`/hrm/employees/${id}`, data),

  // ── Attendance ───────────────────────────────────────────────────────────────

  listAttendance: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<any>(`/hrm/attendance${buildQS(params)}`)
      .then(r => toPaginated(unwrap(r), [])),

  createAttendance: (data: unknown) =>
    apiClient.post<any>('/hrm/attendance', data),

  getAttendanceSummary: (period?: string) =>
    apiClient.get<any>(`/hrm/attendance/summary${period ? `?period=${period}` : ''}`)
      .then(r => unwrap(r)),

  // ── Leaves ───────────────────────────────────────────────────────────────────

  listLeaves: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<any>(`/hrm/leaves${buildQS(params)}`)
      .then(r => toPaginated(unwrap(r), [])),

  createLeave: (data: unknown) =>
    apiClient.post<any>('/hrm/leaves', data),

  reviewLeave: (id: string, data: { status: 'approved' | 'rejected'; note?: string }) =>
    apiClient.post<any>(`/hrm/leaves/${id}/review`, data),

  // ── Payroll Periods ─────────────────────────────────────────────────────────

  listPayrollPeriods: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<any>(`/hrm/payroll-periods${buildQS(params)}`)
      .then(r => toPaginated(unwrap(r), [])),

  getPayrollPeriod: (id: string) =>
    apiClient.get<any>(`/hrm/payroll-periods/${id}`).then(r => unwrap(r)),

  createPayrollPeriod: (data: unknown) =>
    apiClient.post<any>('/hrm/payroll-periods', data),

  generatePayroll: (id: string) =>
    apiClient.post<any>(`/hrm/payroll-periods/${id}/generate`, {}),

  approvePayroll: (id: string) =>
    apiClient.post<any>(`/hrm/payroll-periods/${id}/approve`, {}),

  disbursePayroll: (id: string) =>
    apiClient.post<any>(`/hrm/payroll-periods/${id}/disburse`, {}),

  // ── Payroll Items ────────────────────────────────────────────────────────────

  getPayrollItems: (periodId: string): Promise<PaginatedResponse<any>> =>
    apiClient.get<any>(`/hrm/payroll-periods/${periodId}/items`)
      .then(r => toPaginated(unwrap(r), [])),

  updatePayrollItem: (id: string, data: unknown) =>
    apiClient.put<any>(`/hrm/payroll-items/${id}`, data),

  // ── Departments (for filters) ────────────────────────────────────────────────

  listDepartments: () =>
    apiClient.get<any>('/departments').then(r => {
      const d = unwrap(r)
      return Array.isArray(d) ? d : (d as Record<string, unknown>)?.items ?? []
    }),
}
