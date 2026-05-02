export const MOU_STATUSES = ['draft', 'active', 'expired', 'terminated'] as const
export type MouStatus = (typeof MOU_STATUSES)[number]

export interface Mou {
  id: string
  partner_id: string
  partner_name?: string
  title: string
  description: string
  start_date: string
  end_date: string
  document_url: string
  status: MouStatus
  created_at: string
  updated_at: string
}

export interface ExpiringMou extends Mou {
  days_until_expiry: number
}
