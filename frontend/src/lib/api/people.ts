import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface Department {
  id: string
  name: string
  leader_id: string
  is_active: boolean
  created_by: string
  created_at: string
  updated_at: string
}

export interface TeamMember {
  id: string
  user_id: string
  full_name: string
  phone: string
  department_id?: string
  role: string
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

export interface FacilitatorProposal {
  id: string
  course_id: string
  proposed_by: string
  facilitator_id: string
  fee_tier_id: string
  fee_basis: 'per_class' | 'per_course' | 'both'
  dept_leader_status: 'pending' | 'approved' | 'rejected'
  dept_leader_reviewed_at?: string
  dept_leader_note?: string
  academic_leader_status: 'pending' | 'approved' | 'rejected'
  academic_leader_reviewed_at?: string
  academic_leader_note?: string
  final_status: 'pending' | 'approved' | 'rejected'
  created_at: string
  updated_at: string
}

// ── Department Hooks ───────────────────────────────────────────────────────

export function useDepartments() {
  return useQuery({
    queryKey: ['departments'],
    queryFn: () => apiClient.get<Department[]>('/departments').then((r) => r.data),
  })
}

// ── Team Member Hooks ──────────────────────────────────────────────────────

export function useTeamMembersFull() {
  return useQuery({
    queryKey: ['team-members-full'],
    queryFn: () => apiClient.get<TeamMember[]>('/team-members').then((r) => r.data),
  })
}

export interface CreateTeamMemberInput {
  full_name: string
  phone: string
  role: string
  department_id?: string
  employment_status: 'active' | 'inactive' | 'on_leave'
  is_facilitator: boolean
}

export function useCreateTeamMember() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateTeamMemberInput) =>
      apiClient.post<TeamMember>('/team-members', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['team-members-full'] }),
  })
}

export function useDeactivateUser() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (userId: string) =>
      apiClient.delete(`/users/${userId}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['team-members-full'] }),
  })
}

export function useFeeTiersFull() {
  return useQuery({
    queryKey: ['fee-tiers-full'],
    queryFn: () => apiClient.get<FeeTier[]>('/fee-tiers').then((r) => r.data),
  })
}

export interface CreateFeeTierInput {
  name: string
  amount_per_class?: number
  amount_per_course?: number
}

export function useCreateFeeTier() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateFeeTierInput) =>
      apiClient.post<FeeTier>('/fee-tiers', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['fee-tiers-full'] }),
  })
}

// ── Proposal Hooks ─────────────────────────────────────────────────────────

export function useProposal(id: string) {
  return useQuery({
    queryKey: ['proposal', id],
    queryFn: () =>
      apiClient.get<FacilitatorProposal>(`/facilitator-proposals/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export interface CreateProposalInput {
  course_id: string
  facilitator_id: string
  fee_tier_id: string
  fee_basis: 'per_class' | 'per_course' | 'both'
}

export function useCreateProposal() {
  return useMutation({
    mutationFn: (input: CreateProposalInput) =>
      apiClient.post<FacilitatorProposal>('/facilitator-proposals', input).then((r) => r.data),
  })
}

export interface ReviewInput {
  status: 'approved' | 'rejected'
  note?: string
}

export function useDeptLeaderReview() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, ...body }: ReviewInput & { id: string }) =>
      apiClient
        .post(`/facilitator-proposals/${id}/dept-review`, body)
        .then((r) => r.data),
    onSuccess: (_data, { id }) => qc.invalidateQueries({ queryKey: ['proposal', id] }),
  })
}

export function useAcademicLeaderReview() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, ...body }: ReviewInput & { id: string }) =>
      apiClient
        .post(`/facilitator-proposals/${id}/academic-review`, body)
        .then((r) => r.data),
    onSuccess: (_data, { id }) => qc.invalidateQueries({ queryKey: ['proposal', id] }),
  })
}
