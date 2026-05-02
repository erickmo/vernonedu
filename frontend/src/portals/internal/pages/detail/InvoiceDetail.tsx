import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Check, X } from 'lucide-react'
import { toast } from 'sonner'
import {
  useFinanceInvoice,
  usePayFinanceInvoice,
  useCancelFinanceInvoice,
} from '@/lib/api/invoice'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

type ConfirmAction = 'pay' | 'cancel' | null

export default function InvoiceDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: invoice, isLoading } = useFinanceInvoice(id)
  const pay = usePayFinanceInvoice()
  const cancel = useCancelFinanceInvoice()
  const [confirmAction, setConfirmAction] = useState<ConfirmAction>(null)

  if (isLoading) return <LoadingSpinner size="lg" />
  if (!invoice) {
    return <div className="p-6 text-sm text-neutral-500">Invoice not found.</div>
  }

  const handleConfirm = async () => {
    try {
      if (confirmAction === 'pay') {
        await pay.mutateAsync(invoice.id)
        toast.success('Invoice marked as paid')
      } else if (confirmAction === 'cancel') {
        await cancel.mutateAsync(invoice.id)
        toast.success('Invoice cancelled')
      }
      setConfirmAction(null)
    } catch {
      toast.error('Action failed')
    }
  }

  const canAct = invoice.status !== 'paid' && invoice.status !== 'cancelled'

  return (
    <div className="max-w-3xl mx-auto py-8 px-4">
      <button
        onClick={() => navigate('/internal/invoices')}
        className="mb-4 text-sm text-neutral-500 hover:text-neutral-700"
      >
        ← Back to invoices
      </button>

      <div className="bg-white border border-neutral-200 rounded-xl p-6">
        <div className="flex items-start justify-between mb-6">
          <div>
            <p className="text-xs text-neutral-500 mb-1">Invoice Number</p>
            <h1 className="text-xl font-semibold font-mono text-neutral-900">{invoice.number}</h1>
          </div>
          <StatusBadge status={invoice.status} variant="invoice" />
        </div>

        <dl className="grid grid-cols-2 gap-4 text-sm">
          <Row label="Student ID" value={invoice.student_id ?? '—'} mono />
          <Row label="Course Batch ID" value={invoice.course_batch_id ?? '—'} mono />
          <Row label="Issued Date" value={formatDate(invoice.issued_date)} />
          <Row label="Due Date" value={formatDate(invoice.due_date)} />
          <Row label="Subtotal" value={formatCurrency(invoice.subtotal)} mono />
          <Row label="Tax" value={formatCurrency(invoice.tax_amount)} mono />
          <Row label="Total" value={formatCurrency(invoice.total)} mono bold />
          {invoice.paid_date && <Row label="Paid Date" value={formatDate(invoice.paid_date)} />}
        </dl>

        {invoice.items && invoice.items.length > 0 && (
          <div className="mt-6">
            <h2 className="text-sm font-medium text-neutral-700 mb-2">Line Items</h2>
            <table className="w-full text-sm">
              <thead className="text-xs text-neutral-500 border-b border-neutral-200">
                <tr>
                  <th className="text-left py-2">Description</th>
                  <th className="text-right py-2">Qty</th>
                  <th className="text-right py-2">Unit Price</th>
                  <th className="text-right py-2">Total</th>
                </tr>
              </thead>
              <tbody>
                {invoice.items.map((item, idx) => (
                  <tr key={idx} className="border-b border-neutral-100">
                    <td className="py-2">{item.description}</td>
                    <td className="text-right py-2 font-mono">{item.quantity}</td>
                    <td className="text-right py-2 font-mono">{formatCurrency(item.unit_price)}</td>
                    <td className="text-right py-2 font-mono">{formatCurrency(item.total)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {invoice.notes && (
          <div className="mt-6 p-3 bg-neutral-50 rounded-lg">
            <p className="text-xs text-neutral-500 mb-1">Notes</p>
            <p className="text-sm text-neutral-700">{invoice.notes}</p>
          </div>
        )}

        {canAct && (
          <div className="mt-6 flex items-center gap-2 pt-6 border-t border-neutral-200">
            <button
              onClick={() => setConfirmAction('pay')}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-emerald-700 bg-emerald-50 rounded-lg hover:bg-emerald-100"
            >
              <Check className="w-4 h-4" /> Mark Paid
            </button>
            <button
              onClick={() => setConfirmAction('cancel')}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-red-700 bg-red-50 rounded-lg hover:bg-red-100"
            >
              <X className="w-4 h-4" /> Cancel Invoice
            </button>
          </div>
        )}
      </div>

      <ConfirmDialog
        open={confirmAction !== null}
        title={confirmAction === 'pay' ? 'Mark as paid' : 'Cancel invoice'}
        description={
          confirmAction === 'pay'
            ? `Mark invoice ${invoice.number} as paid? This will trigger a journal entry.`
            : `Cancel invoice ${invoice.number}? This cannot be undone.`
        }
        confirmLabel={confirmAction === 'pay' ? 'Mark Paid' : 'Cancel Invoice'}
        destructive={confirmAction === 'cancel'}
        onConfirm={handleConfirm}
        onCancel={() => setConfirmAction(null)}
      />
    </div>
  )
}

function Row({
  label,
  value,
  mono,
  bold,
}: {
  label: string
  value: string
  mono?: boolean
  bold?: boolean
}) {
  return (
    <div>
      <dt className="text-xs text-neutral-500">{label}</dt>
      <dd
        className={[
          'mt-0.5',
          mono ? 'font-mono' : '',
          bold ? 'font-semibold text-neutral-900' : 'text-neutral-700',
        ].join(' ')}
      >
        {value}
      </dd>
    </div>
  )
}
