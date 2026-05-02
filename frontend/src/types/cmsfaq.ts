export const FAQ_CATEGORIES = ['general', 'enrollment', 'payment', 'certificate', 'other'] as const

export interface CmsFaq {
  id: string
  question: string
  answer: string
  category: string
  page_slugs: string[]
  sort_order: number
  created_at: string
  updated_at: string
}

export interface CmsFaqFilters {
  category?: string
  page_slug?: string
}
