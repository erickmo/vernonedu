import { useCrmLogs } from '@/lib/api/lead'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import type { CrmLog } from '@/types/crmlog'

interface Props {
  leadId: string
}

export default function CrmLogList({ leadId }: Props) {
  const { data, isLoading } = useCrmLogs(leadId)

  if (isLoading) return <LoadingSpinner />
  const logs: CrmLog[] = data ?? []

  if (logs.length === 0) {
    return (
      <div className="text-sm text-neutral-400 py-6 text-center bg-neutral-50 rounded-lg">
        No CRM logs yet.
      </div>
    )
  }

  return (
    <ul className="space-y-3">
      {logs.map((log) => (
        <li
          key={log.id}
          className="bg-white border border-neutral-100 rounded-lg p-4"
        >
          <div className="flex items-center justify-between gap-2 mb-2">
            <span className="text-xs font-semibold uppercase tracking-wide text-brand-600">
              {log.contact_method}
            </span>
            <span className="text-xs text-neutral-500">
              {new Date(log.created_at).toLocaleString()}
            </span>
          </div>
          <p className="text-sm text-neutral-700 whitespace-pre-wrap">{log.response}</p>
          {log.follow_up_date && (
            <p className="mt-2 text-xs text-neutral-500">
              Follow-up: {new Date(log.follow_up_date).toLocaleDateString()}
            </p>
          )}
        </li>
      ))}
    </ul>
  )
}
