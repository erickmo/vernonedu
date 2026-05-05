import type { CalendarEvent } from '@/types/calendar.types'
import { EVENT_TYPE_COLORS } from '@/types/calendar.types'

interface Props {
  event: CalendarEvent
}

export function EventDot({ event }: Props) {
  const color = EVENT_TYPE_COLORS[event.event_type] ?? '#999'
  return (
    <span
      title={event.title}
      style={{
        display: 'inline-block',
        width: 7,
        height: 7,
        borderRadius: '50%',
        backgroundColor: color,
        marginRight: 2,
        flexShrink: 0,
      }}
    />
  )
}
