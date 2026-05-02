export interface DesignThinking {
  id: string
  name: string
  created_at?: string
  updated_at?: string
}

export interface DesignThinkingFilters {
  page?: number
  limit?: number
  name?: string
}
