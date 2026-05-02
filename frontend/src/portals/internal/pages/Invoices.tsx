import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useFinanceInvoices } from '@/lib/api/invoice'
import type { Invoice, InvoiceStatus } from '@/types/invoice'
import { INVOICE_STATUSES } from '@/types/invoice'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'

const PAGE_SIZE = 20

export default function Invoices() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState<InvoiceStatus | ''>('')
  const [batchId, setBatchId] = useState('')

  const { data, isLoading } = useFinanceInvoices({
    page,
    limit: PAGE_SIZE,
    status: status || undefined,
    batch_id: batchId || undefined,
  })

  const columns: Column<Invoice>[] = [
    {
      header: 'Invoice #',
      accessor: 'number',
      cell: (row) => (
        <span className="font-mono text-xs text-neutral-700">{row.number}</span>
      ),
    },
    {
      header: 'Student / Batch',
      accessor: 'student_id',
      cell: (row) => (
        <span className="text-xs text-neutral-600 font-mono">
          {row.student_id?.slice(0, 8) ?? row.course_batch_id?.slice(0, 8) ?? '—'}
        </span>
      ),
    },
    {
      header: 'Amount',
      accessor: 'total',
      cell: (row) => (
        <span className="font-semibold text-neutral-800 font-mono">
          {formatCurrency(row.total)}
        </span>
      ),
    },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <StatusBadge status={row.status} variant="invoice" />,
    },
    {
      header: 'Due Date',
      accessor: 'due_date',
      cell: (row) => (
        <span className="text-xs text-neutral-500">{formatDate(row.due_date)}</span>
      ),
    },
  ]

  return (
    <ListPageTemplate
      title="Invoices"
      subtitle="Finance invoice management"
      actions={
        <button
          onClick={() => navigate('/internal/invoices/new')}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors"
        >
          <Plus className="w-4 h-4" /> New Invoice
        </button>
      }
      filters={
        <div className="flex items-center gap-2 flex-wrap">
          <select
            value={status}
            onChange={(e) => {
              setStatus(e.target.value as InvoiceStatus | '')
              setPage(1)
            }}
            className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
          >
            <option value="">All statuses</option>
            {INVOICE_STATUSES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
          <input
            type="text"
            placeholder="Filter by batch_id (UUID)"
            value={batchId}
            onChange={(e) => {
              setBatchId(e.target.value)
              setPage(1)
            }}
            className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white w-72"
          />
        </div>
      }
      columns={columns}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: PAGE_SIZE, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(row) => row.id}
      onRowClick={(row) => navigate(`/internal/invoices/${row.id}`)}
    />
  )
}
