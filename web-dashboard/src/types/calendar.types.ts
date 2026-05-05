export type EventType =
  | 'class_session'
  | 'staff_meeting'
  | 'admin_deadline'
  | 'payment_due'
  | 'facilitator_schedule'
  | 'partner_meeting'

export interface CalendarEvent {
  id: string
  title: string
  description: string | null
  event_type: EventType
  start_at: string
  end_at: string
  is_all_day: boolean
  recurrence_rule: string | null
  location: string | null
  source_domain: string | null
  source_id: string | null
  created_by: string
  created_at: string
}

export const EVENT_TYPE_COLORS: Record<EventType, string> = {
  class_session:        '#3b82f6',
  staff_meeting:        '#22c55e',
  admin_deadline:       '#f97316',
  payment_due:          '#ef4444',
  facilitator_schedule: '#a855f7',
  partner_meeting:      '#14b8a6',
}

export const EVENT_TYPE_LABELS: Record<EventType, string> = {
  class_session:        'Sesi Kelas',
  staff_meeting:        'Rapat Staff',
  admin_deadline:       'Deadline Admin',
  payment_due:          'Jatuh Tempo',
  facilitator_schedule: 'Jadwal Fasilitator',
  partner_meeting:      'Rapat Partner',
}

export interface CreateCalendarEventPayload {
  title: string
  description?: string
  event_type: EventType
  start_at: string
  end_at: string
  is_all_day: boolean
  recurrence_rule?: string
  location?: string
}
