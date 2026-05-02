import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { BMCCanvas } from '@/types/bmc'
import type { UpdateBMCInput } from '@/schemas/bmc'

const BMC = '/bmc'

interface BMCResponse { data: BMCCanvas }

export function useBMC() {
  return useQuery({
    queryKey: ['bmc'],
    queryFn: () =>
      apiClient
        .get<BMCResponse>(BMC)
        .then((r) => r.data.data)
        .catch(() => null),
  })
}

export function useUpdateBMC() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateBMCInput) =>
      apiClient.put(BMC, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['bmc'] }),
  })
}
