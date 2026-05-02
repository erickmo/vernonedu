import { useState } from 'react'
import {
  usePayables,
  useApprovePayable,
  usePayPayable,
  useCancelPayable,
} from '@/lib/api/payable'
import {
  PAYABLE_STATUSES,
  PAYABLE_TYPES,
  type Payable,
  type PayableStatus,
} from '@/types/payable'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import RoleGate from '@/components/shared/RoleGate'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import ConfirmDialog from '@/components/shared/ConfirmDialog'

const PAGE_SIZE = 20

const STATUS_BADGE: Record<PayableStatus, string> = {
  pending: 'bg-amber-100 text-amber-800',
  approved: 'bg-blue-100 text-blue-800',
  paid: 'bg-emerald-100 text-emerald-800',
  cancelled: 'bg-gray-100 text-gray-600',
}

type ConfirmAction = 'approve' | 'pay' | 'cancel'

interface ConfirmState {
  action: ConfirmAction
  payable: Payable
}

export default function Payables() {
  const [page, setPage] = useState(1)
  const [type, setType] = useState('')
  const [status, setStatus] = useState<PayableStatus | ''>('')
  const [batchId, setBatchId] = useState('')
  const [confirm, setConfirm] = useState<ConfirmState | null>(null)

  const { data, isLoading } = usePayables({
    type: type || undefined,
    status: status || undefined,
    batch_id: batchId || undefined,
    offset: (page - 1) * PAGE_SIZE,
    limit: PAGE_SIZE,
  })

  const approveMut = useApprovePayable()
  const payMut = usePayPayable()
  const cancelMut = useCancelPayable()

  const rows = data?.data ?? []
  const total = data?.total ?? rows.length

  const onConfirm = () => {
    if (!confirm) return
    const id = confirm.payable.id
    const opts = { onSettled: () => setConfirm(null) }
    if (confirm.action === 'approve') approveMut.mutate(id, opts)
    else if (confirm.action === 'pay') payMut.mutate({ id }, opts)
    else cancelMut.mutate(id, opts)
  }

  const confirmTitle =
    confirm?.action === 'approve'
      ? 'Approve payable?'
      : confirm?.action === 'pay'
        ? 'Mark payable as paid?'
        : 'Cancel payable?'

  const confirmMsg = confirm
    ? `${confirm.payable.recipient_name} • ${formatCurrency(confirm.payable.amount)}`
    : ''

  return (
    <div className="space-y-4">
      <PageHeader
        title="Payables"
        subtitle="Hutang ke fasilitator, vendor, partner. Approve → Pay alur kerja."
      />

      <div className="flex items-center gap-2 flex-wrap">
        <select
          value={type}
          onChange={(e) => {
            setType(e.target.value)
            setPage(1)
          }}
          className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
        >
          <option value="">All types</option>
          {PAYABLE_TYPES.map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </select>
        <select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value as PayableStatus | '')
            setPage(1)
          }}
          className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
        >
          <option value="">All statuses</option>
          {PAYABLE_STATUSES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
        <input
          type="text"
          value={batchId}
          onChange={(e) => {
            setBatchId(e.target.value)
            setPage(1)
          }}
          placeholder="Filter batch_id (UUID)"
          className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white w-72 font-mono"
        />
      </div>

      <div className="bg-white border border-neutral-200 rounded-lg overflow-hidden">
        {isLoading ? (
          <div className="py-12 flex justify-center">
            <LoadingSpinner size="md" />
          </div>
        ) : rows.length === 0 ? (
          <div className="py-12 text-center text-sm text-neutral-500">
            No payables match this filter.
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 border-b border-neutral-200">
              <tr className="text-left text-xs text-neutral-500 uppercase">
                <th className="px-4 py-2">Created</th>
                <th className="px-4 py-2">Recipient</th>
                <th className="px-4 py-2">Type</th>
                <th className="px-4 py-2">Status</th>
                <th className="px-4 py-2 text-right">Amount</th>
                <th className="px-4 py-2 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((p) => (
                <tr key={p.id} className="border-b border-neutral-100">
                  <td className="px-4 py-2 text-xs text-neutral-500">
                    {p.created_at ? formatDate(p.created_at) : '—'}
                  </td>
                  <td className="px-4 py-2">{p.recipient_name}</td>
                  <td className="px-4 py-2 text-xs text-neutral-500">{p.type}</td>
                  <td className="px-4 py-2">
                    <span
                      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize ${STATUS_BADGE[p.status] ?? 'bg-gray-100 text-gray-700'}`}
                    >
                      {p.status}
                    </span>
                  </td>
                  <td className="px-4 py-2 text-right font-mono font-semibold">
                    {formatCurrency(p.amount)}
                  </td>
                  <td className="px-4 py-2 text-right">
                    <div className="flex justify-end gap-1">
                      {p.status === 'pending' && (
                        <RoleGate action="update" resource="payable">
                          <button
                            type="button"
                            onClick={() => setConfirm({ action: 'approve', payable: p })}
                            className="px-2 py-1 text-xs text-blue-700 hover:bg-blue-50 rounded"
                          >
                            Approve
                          </button>
                        </RoleGate>
                      )}
                      {(p.status === 'pending' || p.status === 'approved') && (
                        <RoleGate action="update" resource="payable">
                          <button
                            type="button"
                            onClick={() => setConfirm({ action: 'pay', payable: p })}
                            className="px-2 py-1 text-xs text-emerald-700 hover:bg-emerald-50 rounded"
                          >
                            Pay
                          </button>
                        </RoleGate>
                      )}
                      {p.status !== 'paid' && p.status !== 'cancelled' && (
                        <RoleGate action="delete" resource="payable">
                          <button
                            type="button"
                            onClick={() => setConfirm({ action: 'cancel', payable: p })}
                            className="px-2 py-1 text-xs text-red-700 hover:bg-red-50 rounded"
                          >
                            Cancel
                          </button>
                        </RoleGate>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <div className="flex items-center justify-between text-xs text-neutral-500">
        <span>
          Showing {rows.length} of {total}
        </span>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1}
            className="px-3 py-1 border border-neutral-200 rounded disabled:opacity-50"
          >
            Prev
          </button>
          <button
            type="button"
            onClick={() => setPage((p) => p + 1)}
            disabled={rows.length < PAGE_SIZE}
            className="px-3 py-1 border border-neutral-200 rounded disabled:opacity-50"
          >
            Next
          </button>
        </div>
      </div>

      <ConfirmDialog
        open={!!confirm}
        title={confirmTitle}
        description={confirmMsg}
        confirmLabel={confirm?.action === 'cancel' ? 'Cancel payable' : 'Confirm'}
        destructive={confirm?.action === 'cancel'}
        onConfirm={onConfirm}
        onCancel={() => setConfirm(null)}
      />
    </div>
  )
}
