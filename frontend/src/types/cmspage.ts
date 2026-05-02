export const CMS_PAGE_TYPES = ['home', 'program', 'segment', 'about', 'contact', 'other'] as const
export type CmsPageType = (typeof CMS_PAGE_TYPES)[number]

export interface CmsPage {
  slug: string
  type: string
  title: string
  subtitle: string
  content: Record<string, unknown> | null
  hero_image_url: string
  seo: Record<string, unknown> | null
  updated_at: string
}

export interface CmsPageFilters {
  type?: string
}
