import { Link } from 'react-router-dom'
import { ClipboardList } from 'lucide-react'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'
import { useBatchSessions } from '@/lib/api/attendance'
import { formatDateTime } from '@/lib/utils/format'

interface SessionsListProps {
  batchId: string
}

export default function SessionsList({ batchId }: SessionsListProps) {
  const { data: sessions, isLoading, error } = useBatchSessions(batchId)

  if (isLoading) return <LoadingSpinner size="md" />
  if (error) {
    return (
      <p className="text-sm text-red-600">
        Failed to load sessions.
      </p>
    )
  }
  if (!sessions || sessions.length === 0) {
    return <p className="text-sm text-neutral-400">No sessions yet.</p>
  }

  return (
    <div className="bg-white rounded-xl border border-neutral-100 overflow-hidden">
      <table className="w-full text-sm">
        <thead className="bg-neutral-50 text-xs text-neutral-500 uppercase">
          <tr>
            <th className="text-left px-4 py-2 font-semibold">Date / Time</th>
            <th className="text-left px-4 py-2 font-semibold">Module</th>
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
                {s.module_name ?? s.module_id ?? '—'}
              </td>
              <td className="px-4 py-3 text-neutral-700">
                {s.room_name ?? s.room_id ?? '—'}
              </td>
              <td className="px-4 py-3">
                <StatusBadge status={s.status} />
              </td>
              <td className="px-4 py-3 text-right">
                <Link
                  to={`/internal/batches/${batchId}/sessions/${s.id}/attendance`}
                  className="inline-flex items-center gap-1 text-xs font-medium text-brand-600 hover:text-brand-700"
                >
                  <ClipboardList className="w-3.5 h-3.5" />
                  Attendance
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
