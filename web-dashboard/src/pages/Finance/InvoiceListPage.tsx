import { useNavigate } from 'react-router-dom'
import { CheckCircle, Send, XCircle } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { invoiceService } from '@/services/invoice.service'
import { toast } from '@/widgets/Toast/Toast'

interface Invoice {
  id: string
  invoice_number: string
  student_name: string
  student_email?: string
  batch_name?: string
  amount: number
  status: string
  due_date?: string
  created_at?: string
  [key: string]: unknown
}

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  draft:     { label: 'Draft',        bg: 'var(--color-surface-alt)',      color: 'var(--color-text-tertiary)' },
  sent:      { label: 'Terkirim',     bg: 'var(--color-info-light)',       color: 'var(--color-info-dark)' },
  paid:      { label: 'Lunas',        bg: 'var(--color-success-light)',    color: 'var(--color-success-dark)' },
  overdue:   { label: 'Jatuh Tempo',  bg: 'var(--color-warning-light)',    color: 'var(--color-warning-dark)' },
  cancelled: { label: 'Dibatalkan',   bg: 'var(--color-error-light)',      color: 'var(--color-error-dark)' },
}

function formatIDR(amount: number): string {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency', currency: 'IDR', minimumFractionDigits: 0,
  }).format(amount)
}

function formatDate(dateStr?: string): string {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
  }).format(new Date(dateStr))
}

function getInitials(name: string): string {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('')
}

const filterDefs: FilterDef[] = [
  {
    key: 'status',
    label: 'Status',
    type: 'select',
    options: [
      { label: 'Semua', value: '' },
      { label: 'Draft', value: 'draft' },
      { label: 'Terkirim', value: 'sent' },
      { label: 'Lunas', value: 'paid' },
      { label: 'Jatuh Tempo', value: 'overdue' },
      { label: 'Dibatalkan', value: 'cancelled' },
    ],
  },
]

const columns: ColumnDef<Invoice>[] = [
  {
    key: 'invoice_number',
    header: 'No. Invoice',
    sortable: true,
    width: 160,
    render: (_v, row) => (
      <span style={{ fontWeight: 700, fontFamily: 'var(--font-mono, monospace)', fontSize: 'var(--font-sm)' }}>
        {row.invoice_number || '—'}
      </span>
    ),
  },
  {
    key: 'student_name',
    header: 'Siswa',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 'var(--radius-full)',
          background: 'var(--color-primary-subtle)', display: 'flex',
          alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          color: 'var(--color-primary)', fontSize: 'var(--font-xs)', fontWeight: 600,
        }}>
          {getInitials(row.student_name || '?')}
        </div>
        <div>
          <div style={{ fontWeight: 600 }}>{row.student_name || '—'}</div>
          {row.student_email && (
            <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginTop: 1 }}>
              {row.student_email}
            </div>
          )}
        </div>
      </div>
    ),
  },
  {
    key: 'batch_name',
    header: 'Batch',
    sortable: true,
    width: 180,
    render: (_v, row) => row.batch_name || '—',
  },
  {
    key: 'amount',
    header: 'Jumlah',
    sortable: true,
    width: 160,
    align: 'right',
    render: (_v, row) => (
      <span style={{ fontWeight: 600 }}>{formatIDR(row.amount)}</span>
    ),
  },
  {
    key: 'status',
    header: 'Status',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const cfg = STATUS_CONFIG[row.status] || STATUS_CONFIG.draft
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: cfg.bg, color: cfg.color,
        }}>
          {cfg.label}
        </span>
      )
    },
  },
  {
    key: 'due_date',
    header: 'Jatuh Tempo',
    sortable: true,
    width: 140,
    render: (_v, row) => formatDate(row.due_date),
  },
  {
    key: 'created_at',
    header: 'Dibuat',
    sortable: true,
    width: 130,
    render: (_v, row) => formatDate(row.created_at),
  },
]

export default function InvoiceListPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const rowActions: RowActionDef<Invoice>[] = [
    {
      key: 'markPaid',
      label: 'Tandai Lunas',
      icon: <CheckCircle size={14} />,
      onClick: async (row) => {
        try {
          await invoiceService.markAsPaid(row.id)
          await queryClient.invalidateQueries({ queryKey: ['finance/invoices'] })
          toast.success(`Invoice ${row.invoice_number} ditandai lunas`)
        } catch {
          toast.error('Gagal menandai lunas')
        }
      },
      visible: (row) => row.status !== 'paid' && row.status !== 'cancelled',
    },
    {
      key: 'send',
      label: 'Kirim',
      icon: <Send size={14} />,
      onClick: async (row) => {
        try {
          await invoiceService.send(row.id)
          await queryClient.invalidateQueries({ queryKey: ['finance/invoices'] })
          toast.success(`Invoice ${row.invoice_number} berhasil dikirim`)
        } catch {
          toast.error('Gagal mengirim invoice')
        }
      },
      visible: (row) => row.status === 'draft',
    },
    {
      key: 'cancel',
      label: 'Batalkan',
      icon: <XCircle size={14} />,
      variant: 'danger',
      onClick: async (row) => {
        const reason = prompt('Alasan pembatalan:')
        if (reason === null) return
        try {
          await invoiceService.cancel(row.id, reason)
          await queryClient.invalidateQueries({ queryKey: ['finance/invoices'] })
          toast.success(`Invoice ${row.invoice_number} dibatalkan`)
        } catch {
          toast.error('Gagal membatalkan invoice')
        }
      },
      visible: (row) => row.status !== 'cancelled' && row.status !== 'paid',
    },
  ]

  return (
    <ListPageTemplate<Invoice>
      title="Invoice"
      addLabel="Buat Invoice Manual"
      onAdd={() => navigate('/finance/invoices/new')}
      queryKey="finance/invoices"
      fetcher={(params) => invoiceService.list(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/finance/invoices/${row.id}`)}
      searchPlaceholder="Cari invoice..."
      exportFilename="invoice"
      emptyTitle="Belum ada invoice"
      emptyDescription="Invoice akan otomatis dibuat saat siswa mendaftar ke batch kelas."
      helpTitle="Invoice"
      helpText="Invoice dibuat otomatis dari pendaftaran siswa. Anda juga dapat membuat invoice manual. Gunakan filter status untuk menemukan invoice yang perlu ditindaklanjuti."
      filterDefs={filterDefs}
    />
  )
}
