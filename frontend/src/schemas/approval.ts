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

export const REASON_MIN_LENGTH = 5
export const REASON_MAX_LENGTH = 2000

export const decisionSchema = z.object({
  reason: z.string().max(REASON_MAX_LENGTH).default(''),
})

/**
 * Stricter schema used by the multi-step approval wizard. Requires a reason
 * with at least REASON_MIN_LENGTH characters so approve/reject/cancel actions
 * always carry an audit-friendly justification.
 */
export const wizardDecisionSchema = z.object({
  reason: z
    .string()
    .trim()
    .min(REASON_MIN_LENGTH, `Reason minimal ${REASON_MIN_LENGTH} karakter`)
    .max(REASON_MAX_LENGTH, `Reason maksimal ${REASON_MAX_LENGTH} karakter`),
})

export const approvalFilterSchema = z.object({
  status: z.enum(APPROVAL_STATUSES).optional(),
  approver_id: z.string().uuid().optional(),
})

export type CreateApprovalInput = z.infer<typeof createApprovalSchema>
export type DecisionInput = z.infer<typeof decisionSchema>
export type WizardDecisionInput = z.infer<typeof wizardDecisionSchema>
