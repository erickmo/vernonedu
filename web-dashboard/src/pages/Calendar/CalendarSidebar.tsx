import { useMutation, useQueryClient } from '@tanstack/react-query'
import type { CalendarEvent } from '@/types/calendar.types'
import { EVENT_TYPE_COLORS, EVENT_TYPE_LABELS } from '@/types/calendar.types'
import { calendarService } from '@/services/calendar.service'
import styles from './CalendarPage.module.css'

const MONTHS = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember']
const DAYS_FULL = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu']

interface Props {
  selectedDate: Date
  events: CalendarEvent[]
  onEdit: (event: CalendarEvent) => void
  onClose: () => void
}

function formatTime(iso: string) {
  const d = new Date(iso)
  return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
}

export function CalendarSidebar({ selectedDate, events, onEdit, onClose }: Props) {
  const queryClient = useQueryClient()
  const deleteMutation = useMutation({
    mutationFn: calendarService.delete,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['calendar-events'] }),
  })

  const label = `${DAYS_FULL[selectedDate.getDay()]}, ${selectedDate.getDate()} ${MONTHS[selectedDate.getMonth()]}`

  return (
    <aside className={styles.sidebar}>
      <div className={styles.sidebarHeader}>
        <h3 className={styles.sidebarTitle}>{label}</h3>
        <button className={styles.closeBtn} onClick={onClose} aria-label="Tutup">×</button>
      </div>

      {events.length === 0 ? (
        <p className={styles.sidebarEmpty}>Tidak ada event</p>
      ) : (
        <ul className={styles.eventList}>
          {events.map(e => (
            <li key={e.id} className={styles.eventItem}>
              <span
                className={styles.eventTypeBar}
                style={{ backgroundColor: EVENT_TYPE_COLORS[e.event_type] }}
              />
              <div className={styles.eventBody}>
                <span className={styles.eventTitle}>{e.title}</span>
                <span className={styles.eventTime}>
                  {e.is_all_day ? 'Sepanjang hari' : `${formatTime(e.start_at)} – ${formatTime(e.end_at)}`}
                </span>
                <span className={styles.eventTypeLabel}>{EVENT_TYPE_LABELS[e.event_type]}</span>
              </div>
              {e.source_domain === null && (
                <div className={styles.eventActions}>
                  <button className={styles.actionBtn} onClick={() => onEdit(e)}>Edit</button>
                  <button
                    className={`${styles.actionBtn} ${styles.actionBtnDanger}`}
                    onClick={() => deleteMutation.mutate(e.id)}
                  >
                    Hapus
                  </button>
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </aside>
  )
}
