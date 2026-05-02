// Loose types matching backend report/analysis read models.
// Kept permissive so backend can evolve without TS breakage.

export interface ReportPeriodFilter {
  from?: string // YYYY-MM-DD
  to?: string
  branch_id?: string
  period?: string // monthly | quarterly | yearly | custom
  month?: number
  year?: number
}

export interface BalanceSheetLine {
  AccountCode?: string
  AccountName?: string
  AccountType?: string
  ParentCode?: string
  Balance?: number
}

export interface BalanceSheetData {
  Assets?: BalanceSheetLine[]
  Liabilities?: BalanceSheetLine[]
  Equity?: BalanceSheetLine[]
  TotalAssets?: number
  TotalLiab?: number
  TotalEquity?: number
  IsBalanced?: boolean
}

export interface PLLine {
  AccountCode?: string
  AccountName?: string
  ParentCode?: string
  Amount?: number
}

export interface ProfitLossData {
  Revenue?: PLLine[]
  HPP?: PLLine[]
  OpExpenses?: PLLine[]
  TotalRevenue?: number
  TotalHPP?: number
  GrossProfit?: number
  TotalOpExpense?: number
  NetProfit?: number
}

export interface CashFlowLine {
  Description?: string
  Amount?: number
}

export interface CashFlowData {
  Operating?: CashFlowLine[]
  Investing?: CashFlowLine[]
  Financing?: CashFlowLine[]
  NetOperating?: number
  NetInvesting?: number
  NetFinancing?: number
  OpeningBalance?: number
  NetChange?: number
  ClosingBalance?: number
}

export interface LedgerEntry {
  Date?: string
  ReferenceNo?: string
  Description?: string
  Debit?: number
  Credit?: number
  RunningBalance?: number
}

export interface GeneralLedgerData {
  AccountCode?: string
  AccountName?: string
  OpeningBalance?: number
  Entries?: LedgerEntry[]
  TotalDebit?: number
  TotalCredit?: number
  ClosingBalance?: number
}

export interface TrialBalanceLine {
  AccountCode?: string
  AccountName?: string
  AccountType?: string
  Debit?: number
  Credit?: number
}

export interface TrialBalanceData {
  Lines?: TrialBalanceLine[]
  TotalDebit?: number
  TotalCredit?: number
  IsBalanced?: boolean
}

// --- Analysis ---

export interface RatioMetric {
  current?: number
  previous?: number
  change?: number
  change_pct?: number
  trend?: string
}

export interface FinancialRatios {
  profit_margin?: RatioMetric
  expense_ratio?: RatioMetric
  revenue_per_student?: RatioMetric
  cost_per_student?: RatioMetric
  avg_batch_profitability?: RatioMetric
  collection_rate?: RatioMetric
  days_sales_outstanding?: RatioMetric
  revenue_growth_rate?: RatioMetric
}

export interface RevenueByGroup {
  group_key?: string
  revenue?: number
  pct_of_total?: number
  batch_count?: number
  avg_per_batch?: number
  trend?: string
}

export interface RevenueAnalysis {
  monthly_trend?: Array<Record<string, number | string>>
  by_group?: RevenueByGroup[]
  total_revenue?: number
  group_by?: string
}

export interface CostByGroup {
  category?: string
  amount?: number
  pct_of_total?: number
  vs_previous?: number
  trend?: string
}

export interface CostAnalysis {
  monthly_trend?: Array<Record<string, number | string>>
  by_category?: CostByGroup[]
  total_cost?: number
}

export interface BatchProfitItem {
  batch_id?: string
  batch_code?: string
  course_name?: string
  revenue?: number
  expense?: number
  commission?: number
  profit?: number
  margin_pct?: number
}

export interface BatchProfitResult {
  items?: BatchProfitItem[]
  avg_margin?: number
  sort?: string
}

export interface CashForecastMonth {
  month?: string
  opening_cash?: number
  inflow?: number
  outflow?: number
  closing_cash?: number
}

export interface CashEvent {
  date?: string
  event_type?: string
  description?: string
  amount?: number
  status?: string
}

export interface CashForecast {
  current_cash?: number
  months?: CashForecastMonth[]
  upcoming_events?: CashEvent[]
}

export interface FinancialAlert {
  level?: string
  code?: string
  message?: string
  count?: number
  amount?: number
}

export interface FinancialSuggestion {
  icon?: string
  message?: string
  amount?: number
  detail?: string
}

// --- Budget vs Actual ---

export interface BudgetItem {
  category?: string
  is_pendapatan?: boolean
  anggaran?: number
  realisasi?: number
}

// --- Commission ---

export interface CommissionConfig {
  course_creator_pct?: number
  dept_leader_pct?: number
  op_leader_pct?: number
  facilitator_pct?: number
  // permissive for backend evolution
  [key: string]: unknown
}
