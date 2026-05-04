import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const cmsService = {
  listPages: () =>
    apiClient.get<any>('/cms/pages').then(r => (r as any).data ?? r),

  getPage: (slug: string) =>
    apiClient.get<any>(`/cms/pages/${slug}`).then(r => (r as any).data ?? r),

  updatePage: (slug: string, data: any) =>
    apiClient.put<any>(`/cms/pages/${slug}`, data),

  listArticles: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/cms/articles${qs}`).then(r => (r as any).data ?? r)
  },

  createArticle: (data: any) =>
    apiClient.post<any>('/cms/articles', data),

  updateArticle: (id: string, data: any) =>
    apiClient.put<any>(`/cms/articles/${id}`, data),

  deleteArticle: (id: string) =>
    apiClient.delete(`/cms/articles/${id}`),

  listTestimonials: () =>
    apiClient.get<any>('/cms/testimonials').then(r => (r as any).data ?? r),

  createTestimonial: (data: any) =>
    apiClient.post<any>('/cms/testimonials', data),

  updateTestimonial: (id: string, data: any) =>
    apiClient.put<any>(`/cms/testimonials/${id}`, data),

  deleteTestimonial: (id: string) =>
    apiClient.delete(`/cms/testimonials/${id}`),

  listFaq: (category?: string) => {
    const qs = category ? `?category=${category}` : ''
    return apiClient.get<any>(`/cms/faq${qs}`).then(r => (r as any).data ?? r)
  },

  createFaq: (data: any) =>
    apiClient.post<any>('/cms/faq', data),

  updateFaq: (id: string, data: any) =>
    apiClient.put<any>(`/cms/faq/${id}`, data),

  deleteFaq: (id: string) =>
    apiClient.delete(`/cms/faq/${id}`),

  listMedia: () =>
    apiClient.get<any>('/cms/media').then(r => (r as any).data ?? r),

  deleteMedia: (id: string) =>
    apiClient.delete(`/cms/media/${id}`),
}

function buildQS(params?: Record<string, any>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') q.set(k, String(v))
  })
  const s = q.toString()
  return s ? `?${s}` : ''
}
