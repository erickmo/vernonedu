export interface User {
  id: string
  name: string
  email: string
  roles: string[]
  created_at?: string
  updated_at?: string
}

export interface UserFilters {
  page?: number
  limit?: number
  name?: string
}

export interface PaginatedUsers {
  data: User[]
  total: number
  offset: number
  limit: number
}
