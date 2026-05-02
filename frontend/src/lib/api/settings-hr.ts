import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type { FacilitatorLevel } from '@/types/facilitatorlevel'
import type { CommissionConfig } from '@/types/commissionconfig'
import type { UpsertFacilitatorLevelsInput } from '@/schemas/facilitatorlevel'
import type { UpdateCommissionConfigInput } from '@/schemas/commissionconfig'

const COMMISSION = '/settings/commission'
const LEVELS = '/settings/facilitator-levels'

interface CommissionResponse { data: CommissionConfig }
interface LevelsResponse { data: FacilitatorLevel[] }

export function useCommissionConfig() {
  return useQuery({
    queryKey: ['settings', 'commission'],
    queryFn: () => apiClient.get<CommissionResponse>(COMMISSION).then((r) => r.data.data),
  })
}

export function useUpdateCommissionConfig() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateCommissionConfigInput) =>
      apiClient.put(COMMISSION, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['settings', 'commission'] }),
  })
}

export function useFacilitatorLevels() {
  return useQuery({
    queryKey: ['settings', 'facilitator-levels'],
    queryFn: () => apiClient.get<LevelsResponse>(LEVELS).then((r) => r.data.data ?? []),
  })
}

export function useUpsertFacilitatorLevels() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpsertFacilitatorLevelsInput) =>
      apiClient.put(LEVELS, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['settings', 'facilitator-levels'] }),
  })
}
