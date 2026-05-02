export const POST_PLATFORMS = ['instagram', 'tiktok', 'facebook', 'linkedin', 'twitter', 'youtube'] as const
export type PostPlatform = (typeof POST_PLATFORMS)[number]

export const POST_STATUSES = ['draft', 'scheduled', 'published', 'cancelled'] as const
export type PostStatus = (typeof POST_STATUSES)[number]

export const POST_CONTENT_TYPES = ['image', 'video', 'reel', 'story', 'carousel', 'text'] as const
export type PostContentType = (typeof POST_CONTENT_TYPES)[number]

export interface MarketingPost {
  id: string
  platforms: string[]
  scheduled_at: string
  content_type: string
  caption: string
  media_url: string
  batch_id: string | null
  status: string
  post_url: string
  created_by: string
  created_at: string
  updated_at: string
}

export interface MarketingPostFilters {
  page?: number
  limit?: number
  platform?: string
  status?: string
  month?: string
}
