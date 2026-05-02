import { z } from 'zod'
import { COMMISSION_TYPES } from '@/types/referralpartner'

export const createReferralPartnerSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(200),
  contact_email: z
    .string()
    .max(200)
    .optional()
    .default('')
    .refine((v) => !v || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v), 'Invalid email'),
  referral_code: z.string().min(1, 'Referral code wajib').max(50),
  commission_type: z.enum(COMMISSION_TYPES as unknown as [string, ...string[]]),
  commission_value: z.number().min(0, 'Min 0'),
})

export const updateReferralPartnerSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(200),
  contact_email: z
    .string()
    .max(200)
    .optional()
    .default('')
    .refine((v) => !v || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v), 'Invalid email'),
  commission_type: z.enum(COMMISSION_TYPES as unknown as [string, ...string[]]),
  commission_value: z.number().min(0, 'Min 0'),
  is_active: z.boolean().optional(),
})

export type CreateReferralPartnerInput = z.infer<typeof createReferralPartnerSchema>
export type UpdateReferralPartnerInput = z.infer<typeof updateReferralPartnerSchema>
