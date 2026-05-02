export interface Branch {
  id: string
  code: string
  name: string
  address: string
  city: string
  province: string
  phone: string
  email: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface BranchFilters {
  is_active?: boolean
  page?: number
  limit?: number
}

export interface PaginatedBranches {
  data: Branch[]
  total: number
  offset: number
  limit: number
}
