export type InvestmentStatus = 'proposed' | 'approved' | 'rejected' | 'in_progress' | 'completed'

export interface InvestmentPlan {
  id: string
  title: string
  category: string
  proposed_by: string
  amount: number
  expected_roi: number
  actual_roi?: number
  status: InvestmentStatus
  notes?: string
  created_at?: string
  updated_at?: string
}

export interface InvestmentFilters {
  page?: number
  limit?: number
  status?: InvestmentStatus | ''
}

export interface PaginatedInvestments {
  data: InvestmentPlan[]
  total: number
  offset: number
  limit: number
}

export const INVESTMENT_STATUSES: InvestmentStatus[] = [
  'proposed', 'approved', 'rejected', 'in_progress', 'completed',
]

export const INVESTMENT_CATEGORIES = [
  'Equipment', 'Marketing', 'Technology', 'Real Estate', 'Other',
] as const
