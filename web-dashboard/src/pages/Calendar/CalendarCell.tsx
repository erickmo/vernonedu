import type { CalendarEvent } from '@/types/calendar.types'
import { EventDot } from './EventDot'
import styles from './CalendarPage.module.css'

interface Props {
  day: number
  events: CalendarEvent[]
  isToday: boolean
  isSelected: boolean
  onClick: () => void
}

export function CalendarCell({ day, events, isToday, isSelected, onClick }: Props) {
  const className = isToday
    ? styles.cellToday
    : isSelected
    ? styles.cellSelected
    : styles.cell

  return (
    <div className={className} onClick={onClick}>
      <span className={styles.cellDay}>{day}</span>
      {events.length > 0 && (
        <div className={styles.cellDots}>
          {events.slice(0, 5).map(e => (
            <EventDot key={e.id} event={e} />
          ))}
          {events.length > 5 && (
            <span className={styles.cellMore}>+{events.length - 5}</span>
          )}
        </div>
      )}
    </div>
  )
}
