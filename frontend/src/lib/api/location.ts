import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { Building, BuildingFilters, PaginatedBuildings } from '@/types/building'
import type { Room, RoomAvailability } from '@/types/room'
import type { CreateBuildingInput, UpdateBuildingInput } from '@/schemas/building'
import type { CreateRoomInput, UpdateRoomInput } from '@/schemas/room'

const BUILDINGS = '/buildings'
const ROOMS = '/rooms'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface BuildingSingleResponse { data: Building }
interface RoomListResponse { data: Room[]; total?: number }
interface RoomSingleResponse { data: Room }
interface RoomAvailabilityResponse { data: RoomAvailability }

// ── Buildings ─────────────────────────────────────────────────────────────

export function useBuildings(filters: BuildingFilters = {}) {
  const limit = filters.limit ?? 15
  const offset = toOffset(filters.page, limit)
  const params = { offset, limit }
  return useQuery({
    queryKey: ['buildings', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedBuildings>(BUILDINGS, { params }).then((r) => r.data),
  })
}

export function useBuilding(id: string | undefined) {
  return useQuery({
    queryKey: ['buildings', id],
    queryFn: () =>
      apiClient
        .get<BuildingSingleResponse>(`${BUILDINGS}/${id}`)
        .then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateBuilding() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateBuildingInput) =>
      apiClient.post(BUILDINGS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['buildings', 'list'] }),
  })
}

export function useUpdateBuilding(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateBuildingInput) =>
      apiClient.put(`${BUILDINGS}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['buildings', 'list'] })
      qc.invalidateQueries({ queryKey: ['buildings', id] })
    },
  })
}

export function useDeleteBuilding() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${BUILDINGS}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['buildings', 'list'] }),
  })
}

// ── Rooms ─────────────────────────────────────────────────────────────────

export function useRooms(buildingId: string | undefined) {
  return useQuery({
    queryKey: ['rooms', 'list', buildingId],
    queryFn: () =>
      apiClient
        .get<RoomListResponse>(ROOMS, { params: { building_id: buildingId } })
        .then((r) => r.data.data ?? []),
    enabled: !!buildingId,
  })
}

export function useRoom(id: string | undefined) {
  return useQuery({
    queryKey: ['rooms', id],
    queryFn: () =>
      apiClient.get<RoomSingleResponse>(`${ROOMS}/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateRoom(buildingId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateRoomInput) =>
      apiClient.post(ROOMS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['rooms', 'list', buildingId] }),
  })
}

export function useUpdateRoom(buildingId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (args: { roomId: string; input: UpdateRoomInput }) =>
      apiClient.put(`${ROOMS}/${args.roomId}`, args.input).then((r) => r.data),
    onSuccess: (_d, { roomId }) => {
      qc.invalidateQueries({ queryKey: ['rooms', 'list', buildingId] })
      qc.invalidateQueries({ queryKey: ['rooms', roomId] })
    },
  })
}

export function useDeleteRoom(buildingId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (roomId: string) =>
      apiClient.delete(`${ROOMS}/${roomId}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['rooms', 'list', buildingId] }),
  })
}

export function useRoomAvailability(
  roomId: string | undefined,
  range: { from: string; to: string } | undefined,
) {
  return useQuery({
    queryKey: ['rooms', roomId, 'availability', range?.from, range?.to],
    queryFn: () =>
      apiClient
        .get<RoomAvailabilityResponse>(`${ROOMS}/${roomId}/availability`, {
          params: { from: range!.from, to: range!.to },
        })
        .then((r) => r.data.data),
    enabled: !!roomId && !!range?.from && !!range?.to,
  })
}
