export const CONTACT_METHODS = ['call', 'whatsapp', 'email', 'meeting', 'other'] as const
export type ContactMethod = (typeof CONTACT_METHODS)[number]

export interface CrmLog {
  id: string
  lead_id: string
  contacted_by_id: string
  contact_method: string
  response: string
  follow_up_date: string | null
  created_at: string
}
