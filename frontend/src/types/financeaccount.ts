// FinanceAccount — bank/cash account record (CoA leaf used for cash & bank).
// API: backend currently routes this through /finance/coa with type=asset
// and a sub-classification stored in code/name. We expose a thin alias so
// the UI can treat them as a separate domain (banks/cash registers).

import type { CoaAccount, CreateCoaPayload, UpdateCoaPayload } from './coa'

export const FINANCE_ACCOUNT_KINDS = ['bank', 'cash'] as const
export type FinanceAccountKind = (typeof FINANCE_ACCOUNT_KINDS)[number]

export interface FinanceAccount extends CoaAccount {
  // FinanceAccount is a CoA row scoped to bank/cash usage. Backend keeps
  // the same shape as CoaAccount; this alias documents intent.
  kind?: FinanceAccountKind
}

export type CreateFinanceAccountPayload = CreateCoaPayload
export type UpdateFinanceAccountPayload = UpdateCoaPayload

export interface FinanceAccountListResponse {
  data: FinanceAccount[]
}
