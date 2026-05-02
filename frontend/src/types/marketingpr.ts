export const PR_TYPES = ['interview', 'press_release', 'event', 'podcast', 'other'] as const
export const PR_STATUSES = ['draft', 'scheduled', 'completed', 'cancelled'] as const

export interface MarketingPr {
  id: string
  title: string
  type: string
  scheduled_at: string
  media_venue: string
  pic_id: string | null
  pic_name: string
  status: string
  notes: string
  created_at: string
  updated_at: string
}

export interface MarketingPrFilters {
  page?: number
  limit?: number
  status?: string
  type?: string
}
