export interface Canvas {
  id: string
  name: string
  created_at?: string
  updated_at?: string
}

export interface CanvasFilters {
  page?: number
  limit?: number
  name?: string
}
