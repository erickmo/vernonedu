import { z } from 'zod'

const TYPES = ['course_request', 'project_assignment', 'task', 'review', 'other'] as const
const PRIORITIES = ['low', 'medium', 'high', 'urgent'] as const

export const createDelegationSchema = z.object({
  title: z.string().min(1, 'Title wajib').max(200),
  type: z.enum(TYPES),
  description: z.string().max(2000).default(''),
  requested_by_id: z.string().min(1, 'Requested by wajib'),
  requested_by_name: z.string().min(1).max(200),
  assigned_to_id: z.string().min(1, 'Assigned to wajib'),
  assigned_to_name: z.string().min(1).max(200),
  assigned_to_role: z.string().max(100).optional(),
  due_date: z.string().optional(),
  priority: z.enum(PRIORITIES).default('medium'),
  linked_entity_type: z.string().max(100).optional(),
  linked_entity_id: z.string().max(100).optional(),
  notes: z.string().max(2000).default(''),
})

export const updateDelegationSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(2000).default(''),
  due_date: z.string().optional(),
  priority: z.enum(PRIORITIES),
  notes: z.string().max(2000).default(''),
})

export const transitionDelegationSchema = z.object({
  notes: z.string().max(2000).default(''),
})

export type CreateDelegationInput = z.infer<typeof createDelegationSchema>
export type UpdateDelegationInput = z.infer<typeof updateDelegationSchema>
export type TransitionDelegationInput = z.infer<typeof transitionDelegationSchema>
