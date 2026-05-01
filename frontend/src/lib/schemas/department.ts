/**
 * Department Validation Schemas
 * Zod schemas for department form validation
 */

import { z } from 'zod'

export const departmentFormSchema = z.object({
  name: z
    .string()
    .min(1, 'Department name is required')
    .min(1, 'Name must be at least 1 character')
    .max(100, 'Name must not exceed 100 characters'),
  description: z
    .string()
    .max(500, 'Description must not exceed 500 characters')
    .optional()
    .or(z.literal('')),
  leaderId: z
    .string()
    .min(1, 'Department leader is required'),
})

export type DepartmentFormValues = z.infer<typeof departmentFormSchema>

export const assignLeaderSchema = z.object({
  leaderId: z
    .string()
    .min(1, 'Department leader is required'),
})

export type AssignLeaderValues = z.infer<typeof assignLeaderSchema>
