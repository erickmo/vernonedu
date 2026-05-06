export type MOUStatus = 'active' | 'expiring' | 'expired' | 'terminated'

export interface MOU {
  id: string
  partner_id: string
  document_number: string
  title: string
  start_date: string
  end_date?: string
  status: MOUStatus
  document_url?: string
  notes?: string
  created_at: string
  updated_at: string
}

export interface ExpiringMOU extends MOU {
  partner_name: string
}

export interface MOUPayload {
  document_number: string
  title: string
  start_date: string
  end_date?: string
  status: MOUStatus
  document_url?: string
  notes?: string
}

export interface Partner {
  id: string
  name: string
  type?: string
  contact_person?: string
  email?: string
  phone?: string
  address?: string
  mou_status?: MOUStatus | null
  group_id?: string
  is_active?: boolean
  [key: string]: unknown
}
