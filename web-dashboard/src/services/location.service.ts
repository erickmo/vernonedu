import { apiClient } from './api.client'

export const locationService = {
  listBuildings: (params?: { search?: string; offset?: number; limit?: number }) => {
    const qs = new URLSearchParams()
    if (params?.search) qs.set('search', params.search)
    if (params?.offset !== undefined) qs.set('offset', String(params.offset))
    if (params?.limit !== undefined) qs.set('limit', String(params.limit))
    const query = qs.toString() ? `?${qs}` : ''
    return apiClient.get<any>(`/buildings${query}`).then(r => (r as any).data ?? r)
  },

  getBuilding: (id: string) =>
    apiClient.get<any>(`/buildings/${id}`).then(r => (r as any).data ?? r),

  createBuilding: (data: any) =>
    apiClient.post<{ id: string; message: string }>('/buildings', data),

  updateBuilding: (id: string, data: any) =>
    apiClient.put<any>(`/buildings/${id}`, data),

  deleteBuilding: (id: string) =>
    apiClient.delete(`/buildings/${id}`),

  listRooms: (buildingId?: string) => {
    const qs = buildingId ? `?building_id=${buildingId}` : ''
    return apiClient.get<any>(`/rooms${qs}`).then(r => (r as any).data ?? r)
  },

  createRoom: (data: any) =>
    apiClient.post<any>('/rooms', data),

  updateRoom: (id: string, data: any) =>
    apiClient.put<any>(`/rooms/${id}`, data),

  deleteRoom: (id: string) =>
    apiClient.delete(`/rooms/${id}`),

  getRoomAvailability: (id: string, from: string, to: string) =>
    apiClient.get<any>(`/rooms/${id}/availability?from=${from}&to=${to}`).then(r => (r as any).data ?? r),
}
