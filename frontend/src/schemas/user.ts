import { z } from 'zod'

export const ROLE_OPTIONS = [
  'director',
  'education_leader',
  'dept_leader',
  'course_owner',
  'course_creator',
  'facilitator',
  'operation_leader',
  'operation_admin',
  'customer_service',
  'marketing',
  'accounting_leader',
  'accounting_staff',
  'student',
  'partner',
] as const

export const createUserSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(200),
  email: z.string().email('Email tidak valid'),
  password: z.string().min(6, 'Password min 6 karakter'),
  roles: z.array(z.string()).min(1, 'Minimal 1 role'),
})

export const updateUserSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(200),
})

export type CreateUserInput = z.infer<typeof createUserSchema>
export type UpdateUserInput = z.infer<typeof updateUserSchema>
