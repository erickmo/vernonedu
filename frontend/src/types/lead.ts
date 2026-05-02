export type LeadStatus = 'new' | 'contacted' | 'qualified' | 'converted' | 'lost'

export const LEAD_STATUSES: LeadStatus[] = [
  'new',
  'contacted',
  'qualified',
  'converted',
  'lost',
]

export const LEAD_SOURCES = [
  'website',
  'referral',
  'social',
  'event',
  'walkin',
  'other',
] as const

export type LeadSource = (typeof LEAD_SOURCES)[number]

export interface Lead {
  id: string
  name: string
  email: string
  phone: string
  interest: string
  source: string
  status: LeadStatus
  notes: string
  pic_id: string | null
  created_at: string
  updated_at: string
}

export interface LeadFilters {
  page?: number
  limit?: number
  status?: string
  source?: string
  interest?: string
}

export interface PaginatedLeads {
  data: Lead[]
  total: number
  offset: number
  limit: number
}
