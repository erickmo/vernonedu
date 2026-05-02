export interface Item {
  id: string
  business_id: string
  canvas_type: string
  section_id: string
  text: string
  note: string
  created_at?: string
  updated_at?: string
}

export interface ItemFilters {
  business_id: string
  canvas_type?: string
}
