import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Budget Types ───────────────────────────────────────────────────────────

export interface BudgetTemplateItem {
  id: string
  course_id: string
  label: string
  category?: string
  preset_amount: number
  overridable: boolean
  created_at: string
  updated_at: string
}

export interface BatchBudgetItem {
  id: string
  course_batch_id: string
  template_ref_id?: string
  label: string
  category?: string
  planned_amount: number
  overridable: boolean
  class_id?: string
  created_by: string
  created_at: string
  updated_at: string
}

export interface BudgetRealization {
  id: string
  batch_budget_item_id: string
  class_id?: string
  actual_amount: number
  description: string
  spent_at: string
  proof_url?: string
  recorded_by: string
  created_at: string
  updated_at: string
}

export interface BatchBudgetSummary {
  items: Array<{
    item: BatchBudgetItem
    actual: number
    variance: number
  }>
  total_planned: number
  total_actual: number
  total_variance: number
}

// ── Budget Hooks ───────────────────────────────────────────────────────────

export function useBudgetTemplates(courseId: string) {
  return useQuery({
    queryKey: ['budget-templates', courseId],
    queryFn: () =>
      apiClient
        .get<BudgetTemplateItem[]>(`/courses/${courseId}/budget-templates`)
        .then((r) => r.data),
    enabled: !!courseId,
  })
}

export function useCreateBudgetTemplate(courseId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: { label: string; category?: string; preset_amount: number; overridable: boolean }) =>
      apiClient
        .post<BudgetTemplateItem>(`/courses/${courseId}/budget-templates`, input)
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['budget-templates', courseId] }),
  })
}

export function useBatchBudgetItems(batchId: string) {
  return useQuery({
    queryKey: ['batch-budget-items', batchId],
    queryFn: () =>
      apiClient
        .get<BatchBudgetItem[]>(`/batches/${batchId}/budget-items`)
        .then((r) => r.data),
    enabled: !!batchId,
  })
}

export function useBatchBudgetSummary(batchId: string) {
  return useQuery({
    queryKey: ['batch-budget-summary', batchId],
    queryFn: () =>
      apiClient
        .get<BatchBudgetSummary>(`/batches/${batchId}/budget-summary`)
        .then((r) => r.data),
    enabled: !!batchId,
  })
}

export function useCreateBatchBudgetItem(batchId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: { label: string; planned_amount: number; category?: string }) =>
      apiClient
        .post<BatchBudgetItem>(`/batches/${batchId}/budget-items`, input)
        .then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['batch-budget-items', batchId] })
      qc.invalidateQueries({ queryKey: ['batch-budget-summary', batchId] })
    },
  })
}

export function useBudgetRealizations(itemId: string) {
  return useQuery({
    queryKey: ['budget-realizations', itemId],
    queryFn: () =>
      apiClient
        .get<BudgetRealization[]>(`/budget-items/${itemId}/realizations`)
        .then((r) => r.data),
    enabled: !!itemId,
  })
}

export function useCreateRealization(itemId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: { actual_amount: number; description: string; spent_at: string }) =>
      apiClient
        .post<BudgetRealization>(`/budget-items/${itemId}/realizations`, input)
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['budget-realizations', itemId] }),
  })
}

// ── Profit Split Types ─────────────────────────────────────────────────────

export interface GlobalSettings {
  id: string
  vernonedu_pct: string
  course_creator_pct: string
  dept_leader_pct: string
  updated_by: string
  updated_at: string
}

export interface CourseOverride {
  id: string
  course_id: string
  vernonedu_pct: string
  course_creator_pct: string
  dept_leader_pct: string
  overridden_by: string
  overridden_at: string
  created_at: string
  updated_at: string
}

export interface ExtraRevenue {
  id: string
  course_batch_id: string
  label: string
  amount: string
  added_by: string
  approval_status: 'pending' | 'approved' | 'rejected'
  approved_by?: string
  approved_at?: string
  created_at: string
  updated_at: string
}

// ── Profit Split Hooks ─────────────────────────────────────────────────────

export function useGlobalSettings() {
  return useQuery({
    queryKey: ['profit-split-settings'],
    queryFn: () =>
      apiClient.get<GlobalSettings>('/profit-split/settings').then((r) => r.data),
  })
}

export function useUpdateGlobalSettings() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: { vernonedu_pct: string; course_creator_pct: string; dept_leader_pct: string }) =>
      apiClient.put<GlobalSettings>('/profit-split/settings', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['profit-split-settings'] }),
  })
}

export function useCourseOverride(courseId: string) {
  return useQuery({
    queryKey: ['profit-split-override', courseId],
    queryFn: () =>
      apiClient
        .get<CourseOverride>(`/profit-split/overrides/${courseId}`)
        .then((r) => r.data),
    enabled: !!courseId,
  })
}

export function useCreateCourseOverride() {
  return useMutation({
    mutationFn: (input: { course_id: string; vernonedu_pct: string; course_creator_pct: string; dept_leader_pct: string }) =>
      apiClient.post<CourseOverride>('/profit-split/overrides', input).then((r) => r.data),
  })
}

export function useAddExtraRevenue() {
  return useMutation({
    mutationFn: (input: { course_batch_id: string; label: string; amount: string }) =>
      apiClient.post<ExtraRevenue>('/profit-split/extra-revenue', input).then((r) => r.data),
  })
}

export function useApproveExtraRevenue() {
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/profit-split/extra-revenue/${id}/approve`).then((r) => r.data),
  })
}

export function useRejectExtraRevenue() {
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/profit-split/extra-revenue/${id}/reject`).then((r) => r.data),
  })
}
