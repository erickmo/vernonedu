import { apiClient } from './api.client'
import { buildQueryString, extractPaginated, type ListParams } from './createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

export const courseBatchService = {
  list: (params?: ListParams): Promise<PaginatedResponse<any>> =>
    apiClient.get<unknown>(`course-batches${buildQueryString(params)}`).then(r => extractPaginated(r)),

  getById: (batchId: string) =>
    apiClient.get<any>(`course-batches/${batchId}`).then((r: any) => r?.data ?? r),

  create: (data: {
    pricing: number
    paymentMethod: string
    minStudents: number
    maxStudents: number
    [key: string]: unknown
  }) =>
    apiClient.post<any>('course-batches', data),

  update: (batchId: string, data: unknown) =>
    apiClient.put<any>(`course-batches/${batchId}`, data),

  delete: (batchId: string) =>
    apiClient.delete(`course-batches/${batchId}`),

  assignFacilitator: (batchId: string, facilitatorId: string) =>
    apiClient.put<any>(`course-batches/${batchId}/facilitator`, { facilitator_id: facilitatorId }),
}
