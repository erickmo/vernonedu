import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { ChevronLeft, ChevronRight, Plus } from 'lucide-react'
import type { CalendarEvent } from '@/types/calendar.types'
import { calendarService } from '@/services/calendar.service'
import { CalendarGrid } from './CalendarGrid'
import { CalendarSidebar } from './CalendarSidebar'
import { EventFormModal } from './EventFormModal'
import styles from './CalendarPage.module.css'

const MONTHS = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember']

export default function CalendarPage() {
  const today = new Date()
  const [viewYear, setViewYear] = useState(today.getFullYear())
  const [viewMonth, setViewMonth] = useState(today.getMonth())
  const [selectedDate, setSelectedDate] = useState<Date | null>(null)
  const [modalEvent, setModalEvent] = useState<CalendarEvent | null | undefined>(undefined)

  const { data: events = [] } = useQuery({
    queryKey: ['calendar-events', viewYear, viewMonth + 1],
    queryFn: () => calendarService.listByMonth(viewYear, viewMonth + 1),
  })

  const prevMonth = () => {
    if (viewMonth === 0) { setViewMonth(11); setViewYear(y => y - 1) }
    else setViewMonth(m => m - 1)
    setSelectedDate(null)
  }

  const nextMonth = () => {
    if (viewMonth === 11) { setViewMonth(0); setViewYear(y => y + 1) }
    else setViewMonth(m => m + 1)
    setSelectedDate(null)
  }

  const selectedDayEvents: CalendarEvent[] = selectedDate
    ? events.filter(e => {
        const d = new Date(e.start_at)
        return d.getDate() === selectedDate.getDate() &&
               d.getMonth() === selectedDate.getMonth() &&
               d.getFullYear() === selectedDate.getFullYear()
      })
    : []

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <div className={styles.nav}>
          <button className={styles.navBtn} onClick={prevMonth}><ChevronLeft size={18} /></button>
          <h2 className={styles.title}>{MONTHS[viewMonth]} {viewYear}</h2>
          <button className={styles.navBtn} onClick={nextMonth}><ChevronRight size={18} /></button>
        </div>
        <button className={styles.btnAdd} onClick={() => setModalEvent(null)}>
          <Plus size={16} /> Event
        </button>
      </div>

      <div className={styles.body}>
        <div className={styles.gridWrap}>
          <CalendarGrid
            year={viewYear}
            month={viewMonth}
            events={events}
            selectedDate={selectedDate}
            onDayClick={setSelectedDate}
          />
        </div>

        {selectedDate && (
          <CalendarSidebar
            selectedDate={selectedDate}
            events={selectedDayEvents}
            onEdit={e => setModalEvent(e)}
            onClose={() => setSelectedDate(null)}
          />
        )}
      </div>

      {modalEvent !== undefined && (
        <EventFormModal
          event={modalEvent}
          defaultDate={selectedDate ?? undefined}
          onClose={() => setModalEvent(undefined)}
        />
      )}
    </div>
  )
}
