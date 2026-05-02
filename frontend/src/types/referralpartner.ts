export const COMMISSION_TYPES = ['percent', 'fixed'] as const
export type CommissionType = (typeof COMMISSION_TYPES)[number]

export interface ReferralPartner {
  id: string
  name: string
  contact_email: string
  referral_code: string
  commission_type: string
  commission_value: number
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface ReferralPartnerFilters {
  page?: number
  limit?: number
  is_active?: boolean
}

export interface Referral {
  id: string
  partner_id: string
  student_id: string
  enrollment_id: string
  student_name: string
  course_name: string
  commission_amount: number
  status: string
  created_at: string
}
