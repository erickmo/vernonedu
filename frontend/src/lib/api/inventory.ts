import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { Item, ItemFilters } from '@/types/item'
import type { CreateItemInput, UpdateItemInput } from '@/schemas/item'

const ITEMS = '/items'

interface ItemListResponse { data: Item[] }
interface ItemSingleResponse { data: Item }

export function useItems(filters: ItemFilters | undefined) {
  return useQuery({
    queryKey: ['items', 'list', filters?.business_id, filters?.canvas_type],
    queryFn: () =>
      apiClient
        .get<ItemListResponse>(ITEMS, {
          params: {
            business_id: filters!.business_id,
            ...(filters!.canvas_type ? { canvas_type: filters!.canvas_type } : {}),
          },
        })
        .then((r) => r.data.data ?? []),
    enabled: !!filters?.business_id,
  })
}

export function useItem(id: string | undefined) {
  return useQuery({
    queryKey: ['items', id],
    queryFn: () =>
      apiClient.get<ItemSingleResponse>(`${ITEMS}/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateItem() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateItemInput) =>
      apiClient.post(ITEMS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['items', 'list'] }),
  })
}

export function useUpdateItem(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateItemInput) =>
      apiClient.put(`${ITEMS}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['items', 'list'] })
      qc.invalidateQueries({ queryKey: ['items', id] })
    },
  })
}

export function useDeleteItem() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${ITEMS}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['items', 'list'] }),
  })
}
