export const ARTICLE_STATUSES = ['draft', 'published', 'archived'] as const
export type ArticleStatus = (typeof ARTICLE_STATUSES)[number]

export const ARTICLE_CATEGORIES = ['news', 'tips', 'success_story', 'announcement', 'other'] as const

export interface CmsArticle {
  id: string
  title: string
  slug: string
  category: string
  content: string
  featured_image_url: string
  status: string
  author_id: string
  published_at: string | null
  created_at: string
  updated_at: string
}

export interface CmsArticleFilters {
  page?: number
  limit?: number
  category?: string
  status?: string
}

export interface PaginatedCmsArticles {
  data: CmsArticle[]
  total: number
  offset: number
  limit: number
}
