export interface CmsMedia {
  id: string
  url: string
  file_name: string
  file_type: string
  file_size: number
  uploaded_by: string
  created_at: string
}

export interface CmsMediaFilters {
  page?: number
  limit?: number
}

export interface PaginatedCmsMedia {
  data: CmsMedia[]
  total: number
  offset: number
  limit: number
}
