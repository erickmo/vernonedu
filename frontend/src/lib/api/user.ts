import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { User, UserFilters, PaginatedUsers } from '@/types/user'
import type { CreateUserInput, UpdateUserInput } from '@/schemas/user'

const USERS = '/users'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

interface UserListResponse { data: User[]; total?: number }
interface UserSingleResponse { data: User }

export function useUsers(filters: UserFilters = {}) {
  const limit = filters.limit ?? 15
  const offset = toOffset(filters.page, limit)
  const params: Record<string, unknown> = { offset, limit }
  if (filters.name) params.name = filters.name
  const path = filters.name ? `${USERS}/search` : USERS

  return useQuery({
    queryKey: ['users', 'list', params, !!filters.name],
    queryFn: () =>
      apiClient.get<UserListResponse | PaginatedUsers>(path, { params }).then((r) => r.data),
  })
}

export function useUser(id: string | undefined) {
  return useQuery({
    queryKey: ['users', id],
    queryFn: () =>
      apiClient.get<UserSingleResponse>(`${USERS}/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })
}

export function useCreateUser() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateUserInput) =>
      apiClient.post(USERS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['users', 'list'] }),
  })
}

export function useUpdateUser(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateUserInput) =>
      apiClient.put(`${USERS}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['users', 'list'] })
      qc.invalidateQueries({ queryKey: ['users', id] })
    },
  })
}

export function useDeleteUser() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${USERS}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['users', 'list'] }),
  })
}
