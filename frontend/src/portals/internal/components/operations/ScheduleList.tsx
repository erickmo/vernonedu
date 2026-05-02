import { MapPin } from 'lucide-react'
import StatusBadge from '@/components/shared/StatusBadge'
import EmptyState from '@/components/shared/EmptyState'
import { formatDateTime } from '@/lib/utils/format'
import type { BatchSchedule } from '@/types/coursebatch'

interface Props {
  schedules: BatchSchedule[] | undefined
  loading?: boolean
  /** Optional lookup maps for friendly labels (id → display name). */
  moduleNames?: Record<string, string>
  roomNames?: Record<string, string>
}

export default function ScheduleList({
  schedules,
  loading,
  moduleNames,
  roomNames,
}: Props) {
  if (loading) {
    return <p className="text-sm text-neutral-400">Loading schedules…</p>
  }
  if (!schedules || schedules.length === 0) {
    return (
      <EmptyState
        title="Belum ada jadwal"
        description="Tambahkan sesi pertama untuk batch ini."
      />
    )
  }

  return (
    <div className="overflow-hidden rounded-xl border border-neutral-100">
      <table className="w-full text-sm">
        <thead className="bg-neutral-50 text-neutral-500">
          <tr>
            <th className="text-left font-medium px-4 py-2">When</th>
            <th className="text-left font-medium px-4 py-2">Module</th>
            <th className="text-left font-medium px-4 py-2">Room</th>
            <th className="text-left font-medium px-4 py-2">Duration</th>
            <th className="text-left font-medium px-4 py-2">Status</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-neutral-100 bg-white">
          {schedules.map((s) => (
            <tr key={s.id}>
              <td className="px-4 py-3 text-neutral-800">
                {formatDateTime(s.scheduled_at)}
              </td>
              <td className="px-4 py-3 text-neutral-700">
                {s.module_id
                  ? (moduleNames?.[s.module_id] ?? truncId(s.module_id))
                  : '—'}
              </td>
              <td className="px-4 py-3 text-neutral-700">
                {s.room_id ? (
                  <span className="inline-flex items-center gap-1">
                    <MapPin className="w-3.5 h-3.5 text-neutral-400" />
                    {roomNames?.[s.room_id] ?? truncId(s.room_id)}
                  </span>
                ) : (
                  '—'
                )}
              </td>
              <td className="px-4 py-3 text-neutral-700">
                {s.duration_minutes} min
              </td>
              <td className="px-4 py-3">
                <StatusBadge status={s.status || 'scheduled'} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function truncId(id: string): string {
  return id.length > 12 ? `${id.slice(0, 8)}…` : id
}
