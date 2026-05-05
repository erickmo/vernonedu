import type { CalendarEvent } from '@/types/calendar.types'
import { CalendarCell } from './CalendarCell'
import styles from './CalendarPage.module.css'

const DAYS = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']

interface Props {
  year: number
  month: number
  events: CalendarEvent[]
  selectedDate: Date | null
  onDayClick: (date: Date) => void
}

function getDaysInMonth(year: number, month: number) {
  return new Date(year, month + 1, 0).getDate()
}

function getFirstDayOfMonth(year: number, month: number) {
  return new Date(year, month, 1).getDay()
}

function groupEventsByDay(events: CalendarEvent[], year: number, month: number): Map<number, CalendarEvent[]> {
  const map = new Map<number, CalendarEvent[]>()
  for (const e of events) {
    const d = new Date(e.start_at)
    if (d.getFullYear() === year && d.getMonth() === month) {
      const day = d.getDate()
      if (!map.has(day)) map.set(day, [])
      map.get(day)!.push(e)
    }
  }
  return map
}

export function CalendarGrid({ year, month, events, selectedDate, onDayClick }: Props) {
  const today = new Date()
  const daysInMonth = getDaysInMonth(year, month)
  const firstDay = getFirstDayOfMonth(year, month)
  const eventsByDay = groupEventsByDay(events, year, month)

  const cells: (number | null)[] = [
    ...Array(firstDay).fill(null),
    ...Array.from({ length: daysInMonth }, (_, i) => i + 1),
  ]

  return (
    <div className={styles.grid}>
      {DAYS.map(d => (
        <div key={d} className={styles.dayLabel}>{d}</div>
      ))}
      {cells.map((day, i) => {
        if (!day) return <div key={i} className={styles.cellEmpty} />
        const isToday = day === today.getDate() && month === today.getMonth() && year === today.getFullYear()
        const isSelected = selectedDate != null &&
          day === selectedDate.getDate() &&
          month === selectedDate.getMonth() &&
          year === selectedDate.getFullYear()
        return (
          <CalendarCell
            key={i}
            day={day}
            events={eventsByDay.get(day) ?? []}
            isToday={isToday}
            isSelected={isSelected}
            onClick={() => onDayClick(new Date(year, month, day))}
          />
        )
      })}
    </div>
  )
}
