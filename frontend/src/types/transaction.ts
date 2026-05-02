// Finance Transaction — manual or auto-posted journal-aware transaction.
// Mirrors api/v1/finance/transactions contract.

export const TRANSACTION_SOURCES = [
  'manual',
  'enrollment',
  'invoice',
  'payable',
  'commission',
  'attendance',
  'system',
] as const

export type TransactionSource = (typeof TRANSACTION_SOURCES)[number] | string

export interface FinanceTransaction {
  id: string
  description: string
  account_debit_id: string
  account_credit_id: string
  amount: number
  reference?: string
  branch_id?: string
  attachment_url?: string
  source?: TransactionSource
  created_by?: string
  created_at?: string
}

export interface TransactionListFilters {
  account_id?: string
  branch_id?: string
  source?: string
  date_from?: string
  date_to?: string
  offset?: number
  limit?: number
}

export interface TransactionListResponse {
  data: FinanceTransaction[]
  total?: number
  offset?: number
  limit?: number
}

export interface CreateTransactionPayload {
  description: string
  account_debit_id: string
  account_credit_id: string
  amount: number
  reference?: string
  branch_id: string
  attachment_url?: string
}
