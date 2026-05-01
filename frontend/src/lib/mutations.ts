/**
 * React Query Hooks - Mutation Operations
 * Department create, update, delete mutations with toast notifications
 */

import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { apiClient } from './api/client'
import type { Department, CreateDepartmentPayload, UpdateDepartmentPayload } from '@/types/department'

// ── API Endpoints ──────────────────────────────────────────────────────────

/**
 * POST /departments
 * Create a new department
 */
export async function createDepartment(
  payload: CreateDepartmentPayload
): Promise<Department> {
  const response = await apiClient.post<{ data: Department }>('/departments', payload)
  return response.data.data
}

/**
 * PATCH /departments/{id}
 * Update a department by ID
 */
export async function updateDepartment(
  id: string,
  payload: UpdateDepartmentPayload
): Promise<Department> {
  const response = await apiClient.patch<{ data: Department }>(
    `/departments/${id}`,
    payload
  )
  return response.data.data
}

/**
 * DELETE /departments/{id}
 * Delete a department by ID
 */
export async function deleteDepartment(id: string): Promise<void> {
  await apiClient.delete(`/departments/${id}`)
}

// ── Mutation Hooks ─────────────────────────────────────────────────────────

/**
 * Hook: Create a new department
 * @example
 * const mutation = useCreateDepartment()
 * mutation.mutate({ name: 'Engineering', leader_id: '123', is_active: true })
 *
 * @invalidates ['departments']
 * @onSuccess Shows toast: 'Department created successfully'
 * @onError Shows toast with error message
 */
export function useCreateDepartment() {
  const qc = useQueryClient()

  return useMutation({
    mutationFn: (payload: CreateDepartmentPayload) => createDepartment(payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['departments'] })
      toast.success('Department created successfully')
    },
    onError: (error: any) => {
      const message = error.response?.data?.message || 'Failed to create department'
      toast.error(message)
    },
  })
}

/**
 * Hook: Update a department
 * @example
 * const mutation = useUpdateDepartment()
 * mutation.mutate({ id: '123', payload: { name: 'Engineering Team' } })
 *
 * @invalidates ['departments'], ['department', id]
 * @onSuccess Shows toast: 'Department updated successfully'
 * @onError Shows toast with error message
 */
export function useUpdateDepartment() {
  const qc = useQueryClient()

  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateDepartmentPayload }) =>
      updateDepartment(id, payload),
    onSuccess: (_data, { id }) => {
      qc.invalidateQueries({ queryKey: ['departments'] })
      qc.invalidateQueries({ queryKey: ['department', id] })
      toast.success('Department updated successfully')
    },
    onError: (error: any) => {
      const message = error.response?.data?.message || 'Failed to update department'
      toast.error(message)
    },
  })
}

/**
 * Hook: Delete a department
 * @example
 * const mutation = useDeleteDepartment()
 * mutation.mutate(departmentId)
 *
 * @invalidates ['departments']
 * @onSuccess Shows toast: 'Department deleted successfully'
 * @onError Shows toast with error message
 */
export function useDeleteDepartment() {
  const qc = useQueryClient()

  return useMutation({
    mutationFn: (id: string) => deleteDepartment(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['departments'] })
      toast.success('Department deleted successfully')
    },
    onError: (error: any) => {
      const message = error.response?.data?.message || 'Failed to delete department'
      toast.error(message)
    },
  })
}
