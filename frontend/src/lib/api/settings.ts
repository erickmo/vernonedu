import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { Holiday } from '@/types/holiday'
import type { CreateHolidayInput } from '@/schemas/holiday'

const HOLIDAYS_BASE = '/settings/holidays'

interface HolidayListResponse {
  data: Holiday[]
}

export function useHolidays(year: number) {
  return useQuery({
    queryKey: ['holidays', 'list', year],
    queryFn: () =>
      apiClient
        .get<HolidayListResponse>(HOLIDAYS_BASE, { params: { year } })
        .then((r) => r.data.data ?? []),
  })
}

export function useCreateHoliday() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateHolidayInput) =>
      apiClient.post(HOLIDAYS_BASE, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['holidays', 'list'] }),
  })
}

export function useDeleteHoliday() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`${HOLIDAYS_BASE}/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['holidays', 'list'] }),
  })
}
