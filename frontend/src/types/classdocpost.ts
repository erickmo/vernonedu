export interface ClassDocPost {
  id: string
  batch_id: string
  session_id: string
  scheduled_at: string
  content_type: string
  caption: string
  media_url: string
  status: string
  post_url: string
  created_at: string
}

export interface ClassDocPostFilters {
  page?: number
  limit?: number
  status?: string
}
