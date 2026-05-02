// Chart of Accounts (CoA) — mirrors api/v1/finance/coa contract.

export const COA_ACCOUNT_TYPES = [
  'asset',
  'liability',
  'equity',
  'revenue',
  'expense',
] as const

export type CoaAccountType = (typeof COA_ACCOUNT_TYPES)[number]

export interface CoaAccount {
  id: string
  code: string
  name: string
  type: CoaAccountType
  parent_id?: string | null
  branch_id?: string | null
  is_active: boolean
  created_at?: string
  updated_at?: string
}

// Tree node — server may return flat list or pre-built tree.
export interface CoaTreeNode extends CoaAccount {
  children?: CoaTreeNode[]
}

export interface CoaListResponse {
  data: CoaAccount[]
}

export interface CreateCoaPayload {
  code: string
  name: string
  type: CoaAccountType
  parent_id?: string | null
  branch_id?: string | null
}

export interface UpdateCoaPayload {
  name: string
  is_active: boolean
}
