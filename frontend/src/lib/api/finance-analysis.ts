import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  FinancialRatios,
  RevenueAnalysis,
  CostAnalysis,
  BatchProfitResult,
  CashForecast,
  FinancialAlert,
  FinancialSuggestion,
  BudgetItem,
  CommissionConfig,
  ReportPeriodFilter,
} from '@/types/financereport'

const ANALYSIS_BASE = '/finance/analysis'
const COMMISSION_BASE = '/settings/commission'
const BUDGET_BASE = '/accounting/budget-vs-actual'

const QK_ANALYSIS = ['finance', 'analysis'] as const
const QK_COMMISSION = ['finance', 'commission'] as const
const QK_BUDGET = ['finance', 'budget-vs-actual'] as const

interface Envelope<T> {
  data: T
}

interface AnalysisFilter extends ReportPeriodFilter {
  group_by?: string
  sort?: string
  limit?: number
  months?: number
  comparison?: string
}

export function useFinancialRatios(filter: AnalysisFilter = {}) {
  return useQuery({
    queryKey: [...QK_ANALYSIS, 'ratios', filter],
    queryFn: () =>
      apiClient
        .get<Envelope<FinancialRatios>>(`${ANALYSIS_BASE}/ratios`, { params: filter })
        .then((r) => r.data.data),
  })
}

export function useRevenueAnalysis(filter: AnalysisFilter = {}) {
  return useQuery({
    queryKey: [...QK_ANALYSIS, 'revenue', filter],
    queryFn: () =>
      apiClient
        .get<Envelope<RevenueAnalysis>>(`${ANALYSIS_BASE}/revenue`, { params: filter })
        .then((r) => r.data.data),
  })
}

export function useCostAnalysis(filter: AnalysisFilter = {}) {
  return useQuery({
    queryKey: [...QK_ANALYSIS, 'costs', filter],
    queryFn: () =>
      apiClient
        .get<Envelope<CostAnalysis>>(`${ANALYSIS_BASE}/costs`, { params: filter })
        .then((r) => r.data.data),
  })
}

export function useBatchProfitability(filter: AnalysisFilter = {}) {
  return useQuery({
    queryKey: [...QK_ANALYSIS, 'batch-profit', filter],
    queryFn: () =>
      apiClient
        .get<Envelope<BatchProfitResult>>(`${ANALYSIS_BASE}/batch-profit`, {
          params: filter,
        })
        .then((r) => r.data.data),
  })
}

export function useCashForecast(filter: AnalysisFilter = {}) {
  return useQuery({
    queryKey: [...QK_ANALYSIS, 'cash-forecast', filter],
    queryFn: () =>
      apiClient
        .get<Envelope<CashForecast>>(`${ANALYSIS_BASE}/cash-forecast`, {
          params: filter,
        })
        .then((r) => r.data.data),
  })
}

export function useFinancialAlerts() {
  return useQuery({
    queryKey: [...QK_ANALYSIS, 'alerts'],
    queryFn: () =>
      apiClient
        .get<Envelope<FinancialAlert[]>>(`${ANALYSIS_BASE}/alerts`)
        .then((r) => r.data.data ?? []),
  })
}

export function useFinancialSuggestions() {
  return useQuery({
    queryKey: [...QK_ANALYSIS, 'suggestions'],
    queryFn: () =>
      apiClient
        .get<Envelope<FinancialSuggestion[]>>(`${ANALYSIS_BASE}/suggestions`)
        .then((r) => r.data.data ?? []),
  })
}

// --- Commission ---

export function useCommissionConfig() {
  return useQuery({
    queryKey: [...QK_COMMISSION, 'config'],
    queryFn: () =>
      apiClient
        .get<Envelope<CommissionConfig>>(COMMISSION_BASE)
        .then((r) => r.data.data),
  })
}

export function useUpdateCommissionConfig() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (payload: CommissionConfig) =>
      apiClient.put<Envelope<CommissionConfig>>(COMMISSION_BASE, payload).then((r) => r.data.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: QK_COMMISSION }),
  })
}

// --- Budget vs Actual ---

interface BudgetFilter {
  month?: number
  year?: number
}

export function useBudgetVsActual(filter: BudgetFilter = {}) {
  return useQuery({
    queryKey: [...QK_BUDGET, filter],
    queryFn: () =>
      apiClient
        .get<Envelope<BudgetItem[]>>(BUDGET_BASE, { params: filter })
        .then((r) => r.data.data ?? []),
  })
}
