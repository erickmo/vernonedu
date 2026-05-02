export type CommissionBasis = 'profit' | 'revenue'

export interface CommissionConfig {
  op_leader_pct: number
  op_leader_basis: CommissionBasis
  dept_leader_pct: number
  dept_leader_basis: CommissionBasis
  course_creator_pct: number
  course_creator_basis: CommissionBasis
}
