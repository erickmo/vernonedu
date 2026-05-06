import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const cmsService = {
  listPages: () =>
    apiClient.get<any>('/cms/pages').then((r: any) => r?.data ?? r),

  getPage: (slug: string) =>
    apiClient.get<any>(`/cms/pages/${slug}`).then((r: any) => r?.data ?? r),

  updatePage: (slug: string, data: any) =>
    apiClient.put<any>(`/cms/pages/${slug}`, data),

  listArticles: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/cms/articles${buildQueryString(params)}`).then(r => extractPaginated(r)),

  createArticle: (data: any) =>
    apiClient.post<any>('/cms/articles', data),

  updateArticle: (id: string, data: any) =>
    apiClient.put<any>(`/cms/articles/${id}`, data),

  deleteArticle: (id: string) =>
    apiClient.delete(`/cms/articles/${id}`),

  listTestimonials: () =>
    apiClient.get<any>('/cms/testimonials').then((r: any) => r?.data ?? r),

  createTestimonial: (data: any) =>
    apiClient.post<any>('/cms/testimonials', data),

  updateTestimonial: (id: string, data: any) =>
    apiClient.put<any>(`/cms/testimonials/${id}`, data),

  deleteTestimonial: (id: string) =>
    apiClient.delete(`/cms/testimonials/${id}`),

  listFaq: (category?: string) => {
    const qs = category ? `?category=${category}` : ''
    return apiClient.get<any>(`/cms/faq${qs}`).then((r: any) => r?.data ?? r)
  },

  createFaq: (data: any) =>
    apiClient.post<any>('/cms/faq', data),

  updateFaq: (id: string, data: any) =>
    apiClient.put<any>(`/cms/faq/${id}`, data),

  deleteFaq: (id: string) =>
    apiClient.delete(`/cms/faq/${id}`),

  listMedia: () =>
    apiClient.get<any>('/cms/media').then((r: any) => r?.data ?? r),

  deleteMedia: (id: string) =>
    apiClient.delete(`/cms/media/${id}`),
}
