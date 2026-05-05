import { apiClient } from './api.client'
import type { CalendarEvent, CreateCalendarEventPayload } from '@/types/calendar.types'

interface ListCalendarEventsResult {
  data: CalendarEvent[]
}

export const calendarService = {
  listByMonth: (year: number, month: number): Promise<CalendarEvent[]> =>
    apiClient
      .get<ListCalendarEventsResult>(`/calendar/events?year=${year}&month=${month}`)
      .then(res => (res as ListCalendarEventsResult).data ?? []),

  getById: (id: string): Promise<CalendarEvent> =>
    apiClient.get<CalendarEvent>(`/calendar/events/${id}`),

  create: (data: CreateCalendarEventPayload): Promise<void> =>
    apiClient.post<void>('/calendar/events', data),

  update: (id: string, data: CreateCalendarEventPayload): Promise<void> =>
    apiClient.put<void>(`/calendar/events/${id}`, data),

  delete: (id: string): Promise<void> =>
    apiClient.delete(`/calendar/events/${id}`),
}
