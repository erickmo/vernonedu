import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Calendar, ClipboardList } from 'lucide-react'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'
import { useMySessions } from '@/lib/api/attendance'
import { formatDateTime } from '@/lib/utils/format'

const DAY_MS = 24 * 60 * 60 * 1000

function toISODate(d: Date): string {
  return d.toISOString().slice(0, 10)
}

function defaultRange(): { from: string; to: string } {
  const today = new Date()
  const day = today.getDay() // 0 = Sun
  const monday = new Date(today.getTime() - ((day + 6) % 7) * DAY_MS)
  const sunday = new Date(monday.getTime() + 6 * DAY_MS)
  return { from: toISODate(monday), to: toISODate(sunday) }
}

export default function MySessions() {
  const initial = useMemo(defaultRange, [])
  const [from, setFrom] = useState(initial.from)
  const [to, setTo] = useState(initial.to)
  const { data: sessions, isLoading, error } = useMySessions(from, to)

  return (
    <div>
      <PageHeader
        title="My Sessions"
        subtitle="Sessions assigned to you within the selected date range"
        breadcrumbs={[{ label: 'My Sessions' }]}
      />

      <div className="bg-white rounded-xl border border-neutral-100 p-4 mb-4 flex items-center gap-3 text-sm">
        <Calendar className="w-4 h-4 text-brand-600" />
        <label className="flex items-center gap-2">
          <span className="text-neutral-500">From</span>
          <input
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            className="border border-neutral-200 rounded-md px-2 py-1 text-sm"
          />
        </label>
        <label className="flex items-center gap-2">
          <span className="text-neutral-500">To</span>
          <input
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            className="border border-neutral-200 rounded-md px-2 py-1 text-sm"
          />
        </label>
      </div>

      {isLoading ? (
        <LoadingSpinner size="md" />
      ) : error ? (
        <p className="text-sm text-red-600">Failed to load sessions.</p>
      ) : !sessions || sessions.length === 0 ? (
        <p className="text-sm text-neutral-400">No sessions in this range.</p>
      ) : (
        <div className="bg-white rounded-xl border border-neutral-100 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 text-xs text-neutral-500 uppercase">
              <tr>
                <th className="text-left px-4 py-2 font-semibold">Date / Time</th>
                <th className="text-left px-4 py-2 font-semibold">Batch</th>
                <th className="text-left px-4 py-2 font-semibold">Room</th>
                <th className="text-left px-4 py-2 font-semibold">Status</th>
                <th className="text-right px-4 py-2 font-semibold">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {sessions.map((s) => (
                <tr key={s.id} className="hover:bg-neutral-50">
                  <td className="px-4 py-3 text-neutral-800">
                    {formatDateTime(s.scheduled_at)}
                  </td>
                  <td className="px-4 py-3 text-neutral-700">
                    {s.batch_name ?? s.batch_id}
                  </td>
                  <td className="px-4 py-3 text-neutral-700">
                    {s.room_name ?? s.room_id ?? '—'}
                  </td>
                  <td className="px-4 py-3">
                    <StatusBadge status={s.status} />
                  </td>
                  <td className="px-4 py-3 text-right">
                    <Link
                      to={`/internal/batches/${s.batch_id}/sessions/${s.id}/attendance`}
                      className="inline-flex items-center gap-1 text-xs font-medium text-brand-600 hover:text-brand-700"
                    >
                      <ClipboardList className="w-3.5 h-3.5" />
                      Mark Attendance
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
