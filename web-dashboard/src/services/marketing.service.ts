import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const marketingService = {
  getStats: () =>
    apiClient.get<any>('/marketing/stats').then((r: any) => r?.data ?? r),

  listPosts: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/marketing/posts${buildQueryString(params)}`).then(r => extractPaginated(r)),

  createPost: (data: any) =>
    apiClient.post<any>('/marketing/posts', data),

  updatePost: (id: string, data: any) =>
    apiClient.put<any>(`/marketing/posts/${id}`, data),

  submitPostUrl: (id: string, url: string) =>
    apiClient.put<any>(`/marketing/posts/${id}/submit-url`, { url }),

  deletePost: (id: string) =>
    apiClient.delete(`/marketing/posts/${id}`),

  listPr: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`/marketing/pr${buildQueryString(params)}`).then(r => extractPaginated(r)),

  createPr: (data: any) =>
    apiClient.post<any>('/marketing/pr', data),

  updatePr: (id: string, data: any) =>
    apiClient.put<any>(`/marketing/pr/${id}`, data),

  deletePr: (id: string) =>
    apiClient.delete(`/marketing/pr/${id}`),

  listReferralPartners: () =>
    apiClient.get<any>('/marketing/referral-partners').then((r: any) => r?.data ?? r),

  createReferralPartner: (data: any) =>
    apiClient.post<any>('/marketing/referral-partners', data),

  updateReferralPartner: (id: string, data: any) =>
    apiClient.put<any>(`/marketing/referral-partners/${id}`, data),

  getReferrals: (partnerId: string) =>
    apiClient.get<any>(`/marketing/referral-partners/${partnerId}/referrals`).then((r: any) => r?.data ?? r),
}
