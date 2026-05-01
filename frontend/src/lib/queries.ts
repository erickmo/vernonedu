/**
 * React Query Hooks - Fetch Operations
 * Department and staff data fetching hooks
 */

import { useQuery } from '@tanstack/react-query'
import { apiClient } from './api/client'
import type { Department, Staff } from '@/types/department'

// ── API Endpoints ──────────────────────────────────────────────────────────

/**
 * GET /departments
 * Fetch all departments
 */
export async function getDepartments(): Promise<Department[]> {
  const response = await apiClient.get<{ data: Department[] }>('/departments')
  return response.data.data
}

/**
 * GET /departments/{id}
 * Fetch a single department by ID
 */
export async function getDepartment(id: string): Promise<Department> {
  const response = await apiClient.get<{ data: Department }>(`/departments/${id}`)
  return response.data.data
}

/**
 * GET /staff
 * Fetch all staff members
 */
export async function getStaff(): Promise<Staff[]> {
  const response = await apiClient.get<{ data: Staff[] }>('/staff')
  return response.data.data
}

// ── Query Hooks ────────────────────────────────────────────────────────────

/**
 * Hook: Fetch all departments
 * @example
 * const { data, isLoading, error } = useDepartments()
 *
 * @queryKey ['departments']
 * @staleTime 5 minutes
 */
export function useDepartments() {
  return useQuery({
    queryKey: ['departments'],
    queryFn: getDepartments,
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

/**
 * Hook: Fetch a single department by ID
 * @example
 * const { data, isLoading, error } = useDepartment(departmentId)
 *
 * @param id Department ID (omit or pass undefined to disable query)
 * @queryKey ['department', id]
 * @enabled Only fetches when id exists
 */
export function useDepartment(id?: string) {
  return useQuery({
    queryKey: ['department', id],
    queryFn: () => getDepartment(id!),
    enabled: !!id,
  })
}

/**
 * Hook: Fetch all staff members
 * @example
 * const { data, isLoading, error } = useStaff()
 *
 * @queryKey ['staff']
 * @staleTime 10 minutes
 */
export function useStaff() {
  return useQuery({
    queryKey: ['staff'],
    queryFn: getStaff,
    staleTime: 10 * 60 * 1000, // 10 minutes
  })
}
