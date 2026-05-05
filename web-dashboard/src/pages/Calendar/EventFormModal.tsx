import { useState, useEffect } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import type { CalendarEvent, EventType, CreateCalendarEventPayload } from '@/types/calendar.types'
import { calendarService } from '@/services/calendar.service'
import styles from './CalendarPage.module.css'

const EVENT_TYPES: { value: EventType; label: string }[] = [
  { value: 'class_session',        label: 'Sesi Kelas' },
  { value: 'staff_meeting',        label: 'Rapat Staff' },
  { value: 'admin_deadline',       label: 'Deadline Admin' },
  { value: 'payment_due',          label: 'Jatuh Tempo' },
  { value: 'facilitator_schedule', label: 'Jadwal Fasilitator' },
  { value: 'partner_meeting',      label: 'Rapat Partner' },
]

interface Props {
  event: CalendarEvent | null
  defaultDate?: Date
  onClose: () => void
}

function toDatetimeLocal(iso: string) {
  return iso.slice(0, 16)
}

function toISO(local: string) {
  return new Date(local).toISOString()
}

export function EventFormModal({ event, defaultDate, onClose }: Props) {
  const queryClient = useQueryClient()
  const isEdit = event !== null

  const defaultStart = defaultDate
    ? new Date(defaultDate.getFullYear(), defaultDate.getMonth(), defaultDate.getDate(), 9, 0).toISOString()
    : new Date().toISOString()
  const defaultEnd = defaultDate
    ? new Date(defaultDate.getFullYear(), defaultDate.getMonth(), defaultDate.getDate(), 10, 0).toISOString()
    : new Date().toISOString()

  const [title, setTitle] = useState(event?.title ?? '')
  const [description, setDescription] = useState(event?.description ?? '')
  const [eventType, setEventType] = useState<EventType>(event?.event_type ?? 'staff_meeting')
  const [startAt, setStartAt] = useState(toDatetimeLocal(event?.start_at ?? defaultStart))
  const [endAt, setEndAt] = useState(toDatetimeLocal(event?.end_at ?? defaultEnd))
  const [isAllDay, setIsAllDay] = useState(event?.is_all_day ?? false)
  const [location, setLocation] = useState(event?.location ?? '')
  const [error, setError] = useState('')

  useEffect(() => {
    if (event) {
      setTitle(event.title)
      setDescription(event.description ?? '')
      setEventType(event.event_type)
      setStartAt(toDatetimeLocal(event.start_at))
      setEndAt(toDatetimeLocal(event.end_at))
      setIsAllDay(event.is_all_day)
      setLocation(event.location ?? '')
    }
  }, [event])

  const mutation = useMutation({
    mutationFn: (payload: CreateCalendarEventPayload) =>
      isEdit ? calendarService.update(event!.id, payload) : calendarService.create(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['calendar-events'] })
      onClose()
    },
    onError: () => setError('Gagal menyimpan event. Coba lagi.'),
  })

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!title.trim()) { setError('Judul wajib diisi'); return }
    mutation.mutate({
      title: title.trim(),
      description: description || undefined,
      event_type: eventType,
      start_at: toISO(startAt),
      end_at: toISO(endAt),
      is_all_day: isAllDay,
      location: location || undefined,
    })
  }

  return (
    <div className={styles.modalOverlay} onClick={onClose}>
      <div className={styles.modal} onClick={e => e.stopPropagation()}>
        <div className={styles.modalHeader}>
          <h3>{isEdit ? 'Edit Event' : 'Event Baru'}</h3>
          <button className={styles.closeBtn} onClick={onClose}>×</button>
        </div>
        <form className={styles.modalForm} onSubmit={handleSubmit}>
          <label>
            Judul *
            <input value={title} onChange={e => setTitle(e.target.value)} required />
          </label>
          <label>
            Tipe Event *
            <select value={eventType} onChange={e => setEventType(e.target.value as EventType)}>
              {EVENT_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
            </select>
          </label>
          <label>
            <input type="checkbox" checked={isAllDay} onChange={e => setIsAllDay(e.target.checked)} />
            &nbsp;Sepanjang hari
          </label>
          {!isAllDay && (
            <>
              <label>
                Mulai *
                <input type="datetime-local" value={startAt} onChange={e => setStartAt(e.target.value)} required />
              </label>
              <label>
                Selesai *
                <input type="datetime-local" value={endAt} onChange={e => setEndAt(e.target.value)} required />
              </label>
            </>
          )}
          <label>
            Lokasi
            <input value={location} onChange={e => setLocation(e.target.value)} placeholder="Ruangan / link meeting" />
          </label>
          <label>
            Deskripsi
            <textarea value={description} onChange={e => setDescription(e.target.value)} rows={3} />
          </label>
          {error && <p className={styles.formError}>{error}</p>}
          <div className={styles.modalActions}>
            <button type="button" className={styles.btnSecondary} onClick={onClose}>Batal</button>
            <button type="submit" className={styles.btnPrimary} disabled={mutation.isPending}>
              {mutation.isPending ? 'Menyimpan...' : 'Simpan'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
