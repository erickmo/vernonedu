import { z } from 'zod'
import type { ChangeType } from '@/types/courseversion'

export const CHANGE_TYPES = ['major', 'minor', 'patch'] as const
export const VERSION_STATUSES = ['draft', 'review', 'approved', 'archived'] as const
const VERSION_REGEX = /^\d+\.\d+\.\d+$/

export const createCourseVersionSchema = z.object({
  version_number: z.string().regex(VERSION_REGEX, 'Format: MAJOR.MINOR.PATCH (mis. 1.2.3)'),
  change_type: z.enum(CHANGE_TYPES),
  changelog: z.string().min(10, 'Changelog minimal 10 karakter').max(5000),
})

export const promoteCourseVersionSchema = z
  .object({
    target_status: z.enum(['review', 'approved']),
    approved_by: z.string().uuid().optional(),
  })
  .refine((d) => d.target_status !== 'approved' || !!d.approved_by, {
    message: 'approved_by wajib saat promote ke approved',
    path: ['approved_by'],
  })

export type CreateCourseVersionInput = z.infer<typeof createCourseVersionSchema>
export type PromoteCourseVersionInput = z.infer<typeof promoteCourseVersionSchema>

export function nextVersion(current: string, changeType: ChangeType): string {
  const parts = current.split('.').map((n) => Number.parseInt(n, 10))
  if (parts.length !== 3 || parts.some((n) => Number.isNaN(n))) return '1.0.0'
  const [maj, min, pat] = parts
  if (changeType === 'major') return `${maj + 1}.0.0`
  if (changeType === 'minor') return `${maj}.${min + 1}.0`
  return `${maj}.${min}.${pat + 1}`
}
