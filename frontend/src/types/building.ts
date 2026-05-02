export interface Building {
  id: string
  name: string
  address: string
  description: string
  room_count?: number
  created_at: string
  updated_at: string
}

export interface BuildingFilters {
  page?: number
  limit?: number
}

export interface PaginatedBuildings {
  data: Building[]
  total: number
  offset: number
  limit: number
}
