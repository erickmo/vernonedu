import { z } from 'zod'
import { APPROVAL_TYPES, APPROVAL_STATUSES } from '@/types/approval'

export const createApprovalSchema = z.object({
  type: z.enum(APPROVAL_TYPES),
  title: z.string().min(1, 'Title wajib').max(200),
  description: z.string().max(2000).default(''),
  approver_id: z.string().uuid('Approver wajib'),
  entity_type: z.string().max(50).default(''),
  entity_id: z.string().max(64).default(''),
})

export const decisionSchema = z.object({
  reason: z.string().max(2000).default(''),
})

export const approvalFilterSchema = z.object({
  status: z.enum(APPROVAL_STATUSES).optional(),
  approver_id: z.string().uuid().optional(),
})

export type CreateApprovalInput = z.infer<typeof createApprovalSchema>
export type DecisionInput = z.infer<typeof decisionSchema>
