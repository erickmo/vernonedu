import { apiClient } from './api.client'

export const locationService = {
  listBuildings: () =>
    apiClient.get<any>('/locations/buildings').then(r => (r as any).data ?? r),

  getBuilding: (id: string) =>
    apiClient.get<any>(`/locations/buildings/${id}`).then(r => (r as any).data ?? r),

  createBuilding: (data: any) =>
    apiClient.post<any>('/locations/buildings', data),

  updateBuilding: (id: string, data: any) =>
    apiClient.put<any>(`/locations/buildings/${id}`, data),

  listRooms: (buildingId?: string) => {
    const qs = buildingId ? `?building_id=${buildingId}` : ''
    return apiClient.get<any>(`/locations/rooms${qs}`).then(r => (r as any).data ?? r)
  },

  createRoom: (data: any) =>
    apiClient.post<any>('/locations/rooms', data),

  updateRoom: (id: string, data: any) =>
    apiClient.put<any>(`/locations/rooms/${id}`, data),
}
