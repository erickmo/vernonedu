export const PARTNER_TYPES = [
  'corporate',
  'government',
  'ngo',
  'university',
  'school',
  'community',
  'other',
] as const
export type PartnerType = (typeof PARTNER_TYPES)[number]

export const PARTNER_STATUSES = ['active', 'inactive', 'prospect'] as const
export type PartnerStatus = (typeof PARTNER_STATUSES)[number]

export interface Partner {
  id: string
  name: string
  type: PartnerType
  status: PartnerStatus
  group_id?: string | null
  contact_name: string
  contact_email: string
  contact_phone: string
  address: string
  notes: string
  created_at: string
  updated_at: string
}

export interface PartnerFilters {
  type?: PartnerType | ''
  status?: PartnerStatus | ''
  search?: string
  page?: number
  limit?: number
}

export interface PaginatedPartners {
  data: Partner[]
  total: number
  offset: number
  limit: number
}

export interface PartnerGroup {
  id: string
  name: string
  description: string
  created_at: string
  updated_at: string
}
