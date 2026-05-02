import { z } from 'zod'
import { PARTNER_TYPES, PARTNER_STATUSES } from '@/types/partner'

export const partnerSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(200),
  type: z.enum(PARTNER_TYPES),
  status: z.enum(PARTNER_STATUSES).default('prospect'),
  group_id: z.string().uuid().optional().nullable(),
  contact_name: z.string().max(200).default(''),
  contact_email: z.union([z.literal(''), z.string().email('Email tidak valid')]).default(''),
  contact_phone: z.string().max(30).default(''),
  address: z.string().max(500).default(''),
  notes: z.string().max(2000).default(''),
})

export const createPartnerSchema = partnerSchema
export const updatePartnerSchema = partnerSchema

export const partnerGroupSchema = z.object({
  name: z.string().min(1, 'Name wajib').max(100),
  description: z.string().max(500).default(''),
})

export type CreatePartnerInput = z.infer<typeof createPartnerSchema>
export type UpdatePartnerInput = z.infer<typeof updatePartnerSchema>
export type PartnerGroupInput = z.infer<typeof partnerGroupSchema>
