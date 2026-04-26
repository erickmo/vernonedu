import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface Student {
  id: string
  name: string
  email: string
  phone: string
  source: 'b2c' | 'b2b'
  partner_id?: string
  created_at: string
}

export interface TeamMember {
  id: string
  name: string
  email: string
  role: string
  department_id: string
  status: 'active' | 'inactive'
}

export interface Department {
  id: string
  name: string
  code: string
}

export interface FacilitatorProposal {
  id: string
  name: string
  email: string
  specialization: string
  status: 'pending' | 'approved' | 'rejected'
  proposed_by: string
  created_at: string
}

export interface FeeTier {
  id: string
  name: string
  min_students: number
  discount_percent: number
}

export interface StudentFilters {
  source?: 'b2c' | 'b2b'
  partner_id?: string
  search?: string
  page?: number
  limit?: number
}

export interface TeamMemberFilters {
  department_id?: string
  role?: string
  page?: number
  limit?: number
}

export interface FacilitatorProposalFilters {
  status?: string
  page?: number
  limit?: number
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
}

// ── Auth hooks ─────────────────────────────────────────────────────────────

export function useLogin() {
  return useMutation({
    mutationFn: (payload: { email: string; password: string }) =>
      apiClient.post<{ access_token: string; user: { id: string; email: string; role: string; name: string } }>('/auth/login', payload).then((r) => r.data),
  })
}

export function useRegister() {
  return useMutation({
    mutationFn: (payload: { name: string; email: string; phone: string; password: string }) =>
      apiClient.post('/auth/register', payload).then((r) => r.data),
  })
}

export function useCurrentUser() {
  return useQuery({
    queryKey: ['auth', 'me'],
    queryFn: () => apiClient.get('/auth/me').then((r) => r.data),
  })
}

// ── Student hooks ──────────────────────────────────────────────────────────

export function useStudents(filters: StudentFilters = {}) {
  return useQuery({
    queryKey: ['students', filters],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Student>>('/students', { params: filters }).then((r) => r.data),
  })
}

export function useStudent(id: string) {
  return useQuery({
    queryKey: ['students', id],
    queryFn: () => apiClient.get<Student>(`/students/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreateStudent() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<Student, 'id' | 'created_at'>) =>
      apiClient.post<Student>('/students', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['students'] }),
  })
}

export function useUpdateStudentProfile() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, ...payload }: Partial<Student> & { id: string }) =>
      apiClient.patch<Student>(`/students/${id}`, payload).then((r) => r.data),
    onSuccess: (_data, vars) => {
      qc.invalidateQueries({ queryKey: ['students', vars.id] })
      qc.invalidateQueries({ queryKey: ['students'] })
    },
  })
}

// ── Team member hooks ──────────────────────────────────────────────────────

export function useTeamMembers(filters: TeamMemberFilters = {}) {
  return useQuery({
    queryKey: ['team-members', filters],
    queryFn: () =>
      apiClient.get<PaginatedResponse<TeamMember>>('/team-members', { params: filters }).then((r) => r.data),
  })
}

export function useCreateTeamMember() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<TeamMember, 'id'>) =>
      apiClient.post<TeamMember>('/team-members', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['team-members'] }),
  })
}

// ── Department hooks ───────────────────────────────────────────────────────

export function useDepartments() {
  return useQuery({
    queryKey: ['departments'],
    queryFn: () => apiClient.get<Department[]>('/departments').then((r) => r.data),
  })
}

export function useCreateDepartment() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Omit<Department, 'id'>) =>
      apiClient.post<Department>('/departments', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['departments'] }),
  })
}

// ── Facilitator proposal hooks ─────────────────────────────────────────────

export function useFacilitatorProposals(filters: FacilitatorProposalFilters = {}) {
  return useQuery({
    queryKey: ['facilitator-proposals', filters],
    queryFn: () =>
      apiClient
        .get<PaginatedResponse<FacilitatorProposal>>('/facilitators/proposals', { params: filters })
        .then((r) => r.data),
  })
}

export function useCreateFacilitatorProposal() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: Pick<FacilitatorProposal, 'name' | 'email' | 'specialization'>) =>
      apiClient.post<FacilitatorProposal>('/facilitators/proposals', payload).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['facilitator-proposals'] }),
  })
}

export function useApproveFacilitatorProposal() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, action }: { id: string; action: 'approve' | 'reject'; note?: string }) =>
      apiClient.post(`/facilitators/proposals/${id}/${action}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['facilitator-proposals'] }),
  })
}

// ── Fee tier hooks ─────────────────────────────────────────────────────────

export function useFeeTiers() {
  return useQuery({
    queryKey: ['fee-tiers'],
    queryFn: () => apiClient.get<FeeTier[]>('/fee-tiers').then((r) => r.data),
  })
}
