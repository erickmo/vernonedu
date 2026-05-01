import { useQuery } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface TeamMember {
  id: string
  user_id: string
  full_name: string
  phone: string
  department_id?: string
  employment_status: 'active' | 'inactive' | 'on_leave'
  joined_at: string
  is_facilitator: boolean
  created_at: string
  updated_at: string
}

export interface FeeTier {
  id: string
  name: string
  amount_per_class?: number
  amount_per_course?: number
  is_active: boolean
  created_by: string
  created_at: string
  updated_at: string
}

// ── Hooks ──────────────────────────────────────────────────────────────────

export function useTeamMembers() {
  return useQuery({
    queryKey: ['team-members'],
    queryFn: () =>
      apiClient.get<TeamMember[]>('/team-members').then((r) => r.data),
  })
}

export function useFeeTiers() {
  return useQuery({
    queryKey: ['fee-tiers'],
    queryFn: () =>
      apiClient.get<FeeTier[]>('/fee-tiers').then((r) => r.data),
  })
}
