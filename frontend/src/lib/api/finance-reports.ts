import { useQuery } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  BalanceSheetData,
  ProfitLossData,
  CashFlowData,
  GeneralLedgerData,
  TrialBalanceData,
  ReportPeriodFilter,
} from '@/types/financereport'

const REPORTS_BASE = '/finance/reports'
const QK_REPORTS = ['finance', 'reports'] as const

interface ReportEnvelope<T> {
  data: T
}

export function useBalanceSheet(filter: ReportPeriodFilter = {}) {
  return useQuery({
    queryKey: [...QK_REPORTS, 'balance-sheet', filter],
    queryFn: () =>
      apiClient
        .get<ReportEnvelope<BalanceSheetData>>(`${REPORTS_BASE}/balance-sheet`, {
          params: filter,
        })
        .then((r) => r.data.data),
  })
}

export function useProfitLoss(filter: ReportPeriodFilter = {}) {
  return useQuery({
    queryKey: [...QK_REPORTS, 'profit-loss', filter],
    queryFn: () =>
      apiClient
        .get<ReportEnvelope<ProfitLossData>>(`${REPORTS_BASE}/profit-loss`, {
          params: filter,
        })
        .then((r) => r.data.data),
  })
}

export function useCashFlow(filter: ReportPeriodFilter = {}) {
  return useQuery({
    queryKey: [...QK_REPORTS, 'cash-flow', filter],
    queryFn: () =>
      apiClient
        .get<ReportEnvelope<CashFlowData>>(`${REPORTS_BASE}/cash-flow`, {
          params: filter,
        })
        .then((r) => r.data.data),
  })
}

export function useGeneralLedger(
  account: string,
  filter: ReportPeriodFilter = {},
) {
  return useQuery({
    queryKey: [...QK_REPORTS, 'ledger', account, filter],
    queryFn: () =>
      apiClient
        .get<ReportEnvelope<GeneralLedgerData>>(`${REPORTS_BASE}/ledger`, {
          params: { account, ...filter },
        })
        .then((r) => r.data.data),
    enabled: !!account,
  })
}

export function useTrialBalance(filter: ReportPeriodFilter = {}) {
  return useQuery({
    queryKey: [...QK_REPORTS, 'trial-balance', filter],
    queryFn: () =>
      apiClient
        .get<ReportEnvelope<TrialBalanceData>>(`${REPORTS_BASE}/trial-balance`, {
          params: filter,
        })
        .then((r) => r.data.data),
  })
}
