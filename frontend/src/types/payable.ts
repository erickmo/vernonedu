// Payable (AP) — accounts payable record. Mirrors api/v1/finance/payables.

export const PAYABLE_TYPES = [
  'facilitator_fee',
  'commission',
  'referral',
  'vendor',
  'other',
] as const
export type PayableType = (typeof PAYABLE_TYPES)[number] | string

export const PAYABLE_STATUSES = [
  'pending',
  'approved',
  'paid',
  'cancelled',
] as const
export type PayableStatus = (typeof PAYABLE_STATUSES)[number]

export interface Payable {
  id: string
  type: PayableType
  recipient_id: string
  recipient_name: string
  batch_id?: string | null
  branch_id?: string | null
  amount: number
  status: PayableStatus
  notes?: string
  payment_proof?: string
  account_code?: string
  created_at?: string
  paid_at?: string | null
}

export interface PayableListFilters {
  type?: string
  status?: PayableStatus
  batch_id?: string
  recipient_id?: string
  date_from?: string
  date_to?: string
  offset?: number
  limit?: number
}

export interface PayableListResponse {
  data: Payable[]
  total?: number
  offset?: number
  limit?: number
}

export interface CreatePayablePayload {
  type: string
  recipient_id: string
  recipient_name: string
  batch_id?: string
  branch_id?: string
  amount: number
  notes?: string
}

export interface PayPayablePayload {
  payment_proof?: string
  account_code?: string
}
