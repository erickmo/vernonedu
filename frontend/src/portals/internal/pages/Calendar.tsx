import { useState } from 'react'
import { Plus, Trash2, MapPin } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  useCalendarEvents,
  useCreateCalendarEvent,
  useDeleteCalendarEvent,
  type CalendarEvent,
} from '@/lib/api/businessops'
import { formatDate } from '@/lib/utils/format'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const EVENT_TYPE_LABELS: Record<CalendarEvent['event_type'], string> = {
  class_session: 'Class Session',
  staff_meeting: 'Staff Meeting',
  admin_deadline: 'Admin Deadline',
  payment_due: 'Payment Due',
  facilitator_schedule: 'Facilitator Schedule',
  partner_meeting: 'Partner Meeting',
}

const EVENT_TYPE_OPTIONS: CalendarEvent['event_type'][] = [
  'class_session',
  'staff_meeting',
  'admin_deadline',
  'payment_due',
  'facilitator_schedule',
  'partner_meeting',
]

const EVENT_TYPE_BADGE_CLASS: Record<CalendarEvent['event_type'], string> = {
  class_session: 'bg-brand-50 text-brand-700',
  staff_meeting: 'bg-violet-50 text-violet-700',
  admin_deadline: 'bg-red-50 text-red-700',
  payment_due: 'bg-amber-50 text-amber-700',
  facilitator_schedule: 'bg-emerald-50 text-emerald-700',
  partner_meeting: 'bg-sky-50 text-sky-700',
}

const eventSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  event_type: z.enum([
    'class_session',
    'staff_meeting',
    'admin_deadline',
    'payment_due',
    'facilitator_schedule',
    'partner_meeting',
  ]),
  start_at: z.string().min(1, 'Start time is required'),
  end_at: z.string().min(1, 'End time is required'),
  location: z.string().optional(),
  is_all_day: z.boolean(),
})

type EventForm = z.infer<typeof eventSchema>

export default function Calendar() {
  const [open, setOpen] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<CalendarEvent | null>(null)
  const { data = [], isLoading } = useCalendarEvents()
  const createEvent = useCreateCalendarEvent()
  const deleteEvent = useDeleteCalendarEvent()

  const sorted = [...data].sort(
    (a, b) => new Date(a.start_at).getTime() - new Date(b.start_at).getTime(),
  )

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<EventForm>({
    resolver: zodResolver(eventSchema),
    defaultValues: { event_type: 'class_session', is_all_day: false },
  })

  const onSubmit = async (form: EventForm) => {
    try {
      await createEvent.mutateAsync(form)
      toast.success('Event created')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to create event')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Calendar"
        subtitle={isLoading ? 'Loading…' : `${sorted.length} event${sorted.length !== 1 ? 's' : ''}`}
        actions={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            New Event
          </button>
        }
      />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] divide-y divide-neutral-50">
        {isLoading ? (
          <div className="py-12 text-center text-sm text-neutral-400">Loading…</div>
        ) : sorted.length === 0 ? (
          <div className="py-12 text-center text-sm text-neutral-400">No events yet.</div>
        ) : (
          sorted.map((event) => (
            <div
              key={event.id}
              className="flex items-center justify-between px-5 py-4 hover:bg-neutral-50 transition-colors"
            >
              <div className="space-y-0.5 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium text-neutral-900 truncate">
                    {event.title}
                  </span>
                </div>
                <div className="flex items-center gap-3 text-xs text-neutral-500">
                  <span>{formatDate(event.start_at)}</span>
                  {event.location && (
                    <span className="flex items-center gap-1">
                      <MapPin className="w-3 h-3" />
                      {event.location}
                    </span>
                  )}
                </div>
              </div>

              <div className="flex items-center gap-3 ml-4 shrink-0">
                <span
                  className={cn(
                    'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
                    EVENT_TYPE_BADGE_CLASS[event.event_type],
                  )}
                >
                  {EVENT_TYPE_LABELS[event.event_type]}
                </span>
                <button
                  onClick={() => setDeleteTarget(event)}
                  className="text-neutral-400 hover:text-red-500 transition-colors"
                  aria-label="Delete event"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-50" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">
              New Event
            </Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Title <span className="text-red-500">*</span>
                </label>
                <input
                  {...register('title')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.title && (
                  <p className="text-xs text-red-500 mt-1">{errors.title.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Event Type
                </label>
                <select
                  {...register('event_type')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  {EVENT_TYPE_OPTIONS.map((t) => (
                    <option key={t} value={t}>
                      {EVENT_TYPE_LABELS[t]}
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">
                    Start <span className="text-red-500">*</span>
                  </label>
                  <input
                    {...register('start_at')}
                    type="datetime-local"
                    className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                  {errors.start_at && (
                    <p className="text-xs text-red-500 mt-1">{errors.start_at.message}</p>
                  )}
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">
                    End <span className="text-red-500">*</span>
                  </label>
                  <input
                    {...register('end_at')}
                    type="datetime-local"
                    className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                  {errors.end_at && (
                    <p className="text-xs text-red-500 mt-1">{errors.end_at.message}</p>
                  )}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Location
                </label>
                <input
                  {...register('location')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="is_all_day"
                  {...register('is_all_day')}
                  className="rounded border-neutral-300 text-brand-600 focus:ring-brand-500"
                />
                <label htmlFor="is_all_day" className="text-sm text-neutral-700">
                  All day
                </label>
              </div>

              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => { setOpen(false); reset() }}
                  className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={createEvent.isPending}
                  className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50 transition-colors"
                >
                  {createEvent.isPending ? 'Creating…' : 'Create Event'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      <ConfirmDialog
        open={deleteTarget !== null}
        title="Delete Event"
        description={`Are you sure you want to delete "${deleteTarget?.title ?? ''}"? This action cannot be undone.`}
        confirmLabel="Delete"
        destructive
        onConfirm={() => {
          if (!deleteTarget) return
          deleteEvent.mutate(deleteTarget.id, {
            onSuccess: () => toast.success('Event deleted'),
            onError: () => toast.error('Failed to delete event'),
          })
          setDeleteTarget(null)
        }}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  )
}
