import { apiClient } from './api.client'
import type { ListParams } from './createEntityService'

export const marketingService = {
  getStats: () =>
    apiClient.get<any>('/marketing/stats').then(r => (r as any).data ?? r),

  listPosts: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/marketing/posts${qs}`).then(r => (r as any).data ?? r)
  },

  createPost: (data: any) =>
    apiClient.post<any>('/marketing/posts', data),

  updatePost: (id: string, data: any) =>
    apiClient.put<any>(`/marketing/posts/${id}`, data),

  submitPostUrl: (id: string, url: string) =>
    apiClient.put<any>(`/marketing/posts/${id}/submit-url`, { url }),

  deletePost: (id: string) =>
    apiClient.delete(`/marketing/posts/${id}`),

  listPr: (params?: ListParams) => {
    const qs = buildQS(params)
    return apiClient.get<any>(`/marketing/pr${qs}`).then(r => (r as any).data ?? r)
  },

  createPr: (data: any) =>
    apiClient.post<any>('/marketing/pr', data),

  updatePr: (id: string, data: any) =>
    apiClient.put<any>(`/marketing/pr/${id}`, data),

  deletePr: (id: string) =>
    apiClient.delete(`/marketing/pr/${id}`),

  listReferralPartners: () =>
    apiClient.get<any>('/marketing/referral-partners').then(r => (r as any).data ?? r),

  createReferralPartner: (data: any) =>
    apiClient.post<any>('/marketing/referral-partners', data),

  updateReferralPartner: (id: string, data: any) =>
    apiClient.put<any>(`/marketing/referral-partners/${id}`, data),

  getReferrals: (partnerId: string) =>
    apiClient.get<any>(`/marketing/referral-partners/${partnerId}/referrals`).then(r => (r as any).data ?? r),
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
