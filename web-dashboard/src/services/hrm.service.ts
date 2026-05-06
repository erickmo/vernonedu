import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

// ─── Employees ─────────────────────────────────────────────────────────────────

export const hrmService = {
  // ── Employees ────────────────────────────────────────────────────────────────

  listEmployees: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/hrm/employees${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getEmployee: (id: string) =>
    apiClient.get<any>(`/hrm/employees/${id}`).then((r: any) => r?.data ?? r),

  createEmployee: (data: unknown) =>
    apiClient.post<any>('/hrm/employees', data),

  updateEmployee: (id: string, data: unknown) =>
    apiClient.put<any>(`/hrm/employees/${id}`, data),

  // ── Attendance ───────────────────────────────────────────────────────────────

  listAttendance: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/hrm/attendance${buildQueryString(params)}`).then(r => extractPaginated(r)),

  createAttendance: (data: unknown) =>
    apiClient.post<any>('/hrm/attendance', data),

  getAttendance: (id: string) =>
    apiClient.get<any>(`/hrm/attendance/${id}`).then((r: any) => r?.data ?? r),

  updateAttendance: (id: string, data: unknown) =>
    apiClient.put<any>(`/hrm/attendance/${id}`, data),

  getAttendanceSummary: (params?: { employee_id?: string; month?: number; year?: number }) =>
    apiClient.get<any>(`/hrm/attendance/summary${buildQueryString(params)}`).then((r: any) => r?.data ?? r),

  // ── Leave Requests ────────────────────────────────────────────────────────────

  listLeaves: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/hrm/leave-requests${buildQueryString(params)}`).then(r => extractPaginated(r)),

  createLeave: (data: unknown) =>
    apiClient.post<any>('/hrm/leave-requests', data),

  getLeave: (id: string) =>
    apiClient.get<any>(`/hrm/leave-requests/${id}`).then((r: any) => r?.data ?? r),

  reviewLeave: (id: string, data: { status: 'approved' | 'rejected'; note?: string }) =>
    apiClient.put<any>(`/hrm/leave-requests/${id}/review`, data),

  // ── Payroll Periods ─────────────────────────────────────────────────────────

  listPayrollPeriods: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/hrm/payroll-periods${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getPayrollPeriod: (id: string) =>
    apiClient.get<any>(`/hrm/payroll-periods/${id}`).then((r: any) => r?.data ?? r),

  createPayrollPeriod: (data: unknown) =>
    apiClient.post<any>('/hrm/payroll-periods', data),

  approvePayroll: (id: string) =>
    apiClient.put<any>(`/hrm/payroll-periods/${id}/approve`, {}),

  disbursePayroll: (id: string) =>
    apiClient.put<any>(`/hrm/payroll-periods/${id}/disburse`, {}),

  // ── Payroll Items ────────────────────────────────────────────────────────────

  getPayrollItems: (periodId: string): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/hrm/payroll-periods/${periodId}/items`).then(r => extractPaginated(r)),

  updatePayrollItem: (id: string, data: unknown) =>
    apiClient.put<any>(`/hrm/payroll-items/${id}`, data),

  // ── Departments (for filters) ────────────────────────────────────────────────

  listDepartments: () =>
    apiClient.get<any>('/departments').then((r: any) => {
      const d = r?.data ?? r
      return Array.isArray(d) ? d : d?.items ?? []
    }),

  deleteAttendance: (id: string) =>
    apiClient.delete<any>(`/hrm/attendance/${id}`),

  deleteLeaveRequest: (id: string) =>
    apiClient.delete<any>(`/hrm/leave-requests/${id}`),

  deletePayrollPeriod: (id: string) =>
    apiClient.delete<any>(`/hrm/payroll-periods/${id}`),
}
