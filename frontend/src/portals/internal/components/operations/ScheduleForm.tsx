import { useEffect, useMemo, useState } from 'react'
import { AlertTriangle } from 'lucide-react'
import FormModal from '@/components/shared/FormModal'
import { useBuildings, useRooms } from '@/lib/api/location'
import {
  createBatchScheduleSchema,
  type CreateBatchScheduleInput,
} from '@/schemas/batchschedule'
import type { BatchSchedule } from '@/types/coursebatch'

const DEFAULT_DURATION = 120 // minutes (2 hours)

interface Props {
  open: boolean
  onClose: () => void
  onSubmit: (input: CreateBatchScheduleInput) => Promise<void>
  loading?: boolean
  /** Existing schedules for client-side conflict warning. */
  existing?: BatchSchedule[]
}

interface FormState {
  module_id: string
  building_id: string
  room_id: string
  scheduled_at: string
  duration_minutes: number
  notes: string
}

const EMPTY: FormState = {
  module_id: '',
  building_id: '',
  room_id: '',
  scheduled_at: '',
  duration_minutes: DEFAULT_DURATION,
  notes: '',
}

export default function ScheduleForm({
  open,
  onClose,
  onSubmit,
  loading,
  existing,
}: Props) {
  const [state, setState] = useState<FormState>(EMPTY)
  const [errors, setErrors] = useState<Record<string, string>>({})

  const { data: buildingsRes } = useBuildings({ limit: 100 })
  const { data: rooms } = useRooms(state.building_id || undefined)

  useEffect(() => {
    if (open) {
      setState(EMPTY)
      setErrors({})
    }
  }, [open])

  const conflict = useMemo(
    () => detectRoomConflict(existing, state.room_id, state.scheduled_at, state.duration_minutes),
    [existing, state.room_id, state.scheduled_at, state.duration_minutes],
  )

  function setField<K extends keyof FormState>(key: K, value: FormState[K]) {
    setState((prev) => ({ ...prev, [key]: value }))
  }

  async function handleSubmit() {
    const payload: CreateBatchScheduleInput = {
      module_id: state.module_id,
      room_id: state.room_id,
      scheduled_at: state.scheduled_at,
      duration_minutes: state.duration_minutes,
      notes: state.notes,
    }
    const parsed = createBatchScheduleSchema.safeParse(payload)
    if (!parsed.success) {
      const next: Record<string, string> = {}
      for (const issue of parsed.error.issues) {
        const path = issue.path[0]
        if (typeof path === 'string') next[path] = issue.message
      }
      setErrors(next)
      return
    }
    setErrors({})
    await onSubmit(parsed.data)
  }

  return (
    <FormModal
      open={open}
      onOpenChange={(o) => !o && onClose()}
      title="Tambah Jadwal"
      onSubmit={handleSubmit}
      loading={loading}
      submitLabel="Save"
    >
      <Field label="Module ID (UUID)" error={errors.module_id}>
        <input
          type="text"
          value={state.module_id}
          onChange={(e) => setField('module_id', e.target.value)}
          placeholder="00000000-0000-0000-0000-000000000000"
          className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg font-mono"
        />
      </Field>

      <Field label="Gedung">
        <select
          value={state.building_id}
          onChange={(e) => {
            setField('building_id', e.target.value)
            setField('room_id', '')
          }}
          className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg"
        >
          <option value="">— Pilih gedung —</option>
          {buildingsRes?.data?.map((b) => (
            <option key={b.id} value={b.id}>
              {b.name}
            </option>
          ))}
        </select>
      </Field>

      <Field label="Ruangan" error={errors.room_id}>
        <select
          value={state.room_id}
          onChange={(e) => setField('room_id', e.target.value)}
          disabled={!state.building_id}
          className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg disabled:bg-neutral-50 disabled:text-neutral-400"
        >
          <option value="">— Pilih ruangan —</option>
          {rooms?.map((r) => (
            <option key={r.id} value={r.id}>
              {r.name}
              {r.capacity ? ` (cap ${r.capacity})` : ''}
            </option>
          ))}
        </select>
      </Field>

      <Field label="Waktu Mulai" error={errors.scheduled_at}>
        <input
          type="datetime-local"
          value={state.scheduled_at}
          onChange={(e) => setField('scheduled_at', e.target.value)}
          className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg"
        />
      </Field>

      <Field label="Durasi (menit)" error={errors.duration_minutes}>
        <input
          type="number"
          min={15}
          step={15}
          value={state.duration_minutes}
          onChange={(e) => setField('duration_minutes', Number(e.target.value))}
          className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg"
        />
      </Field>

      <Field label="Catatan (opsional)">
        <textarea
          value={state.notes}
          onChange={(e) => setField('notes', e.target.value)}
          rows={2}
          className="w-full px-3 py-2 text-sm border border-neutral-200 rounded-lg"
        />
      </Field>

      {conflict && (
        <div className="flex items-start gap-2 rounded-lg border border-amber-200 bg-amber-50 p-3 text-xs text-amber-800">
          <AlertTriangle className="w-4 h-4 mt-0.5 shrink-0" />
          <span>
            Jadwal di ruangan ini bertabrakan dengan sesi yang sudah ada. Backend akan
            menolak konflik — Anda bisa tetap submit untuk verifikasi.
          </span>
        </div>
      )}
    </FormModal>
  )
}

interface FieldProps {
  label: string
  error?: string
  children: React.ReactNode
}

function Field({ label, error, children }: FieldProps) {
  return (
    <div>
      <label className="block text-xs font-medium text-neutral-600 mb-1">{label}</label>
      {children}
      {error && <p className="mt-1 text-xs text-red-600">{error}</p>}
    </div>
  )
}

/** Returns true if the proposed slot overlaps an existing schedule in the same room. */
export function detectRoomConflict(
  existing: BatchSchedule[] | undefined,
  roomId: string,
  scheduledAtLocal: string,
  durationMinutes: number,
): boolean {
  if (!existing || !roomId || !scheduledAtLocal || !durationMinutes) return false
  const startMs = new Date(scheduledAtLocal).getTime()
  if (Number.isNaN(startMs)) return false
  const endMs = startMs + durationMinutes * 60_000

  return existing.some((s) => {
    if (s.room_id !== roomId) return false
    const otherStart = new Date(s.scheduled_at).getTime()
    if (Number.isNaN(otherStart)) return false
    const otherEnd = otherStart + (s.duration_minutes ?? 0) * 60_000
    return startMs < otherEnd && endMs > otherStart
  })
}
