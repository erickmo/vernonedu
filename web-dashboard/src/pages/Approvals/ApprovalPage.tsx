import { useQueryClient } from '@tanstack/react-query'
import { CheckCircle, XCircle } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { approvalService } from '@/services/approval.service'
import type { Approval } from '@/services/approval.service'
import { toast } from '@/widgets/Toast/Toast'

const QUERY_KEY = 'approvals'

const columns: ColumnDef<Approval>[] = [
  {
    key: 'type',
    header: 'Tipe',
    sortable: true,
    width: 160,
    render: (_v, row) => row.type || '—',
  },
  {
    key: 'subject',
    header: 'Subjek',
    sortable: true,
    render: (_v, row) => (
      <div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.subject}</div>
        {row.description && (
          <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
            {row.description.length > 80 ? row.description.slice(0, 80) + '...' : row.description}
          </div>
        )}
      </div>
    ),
  },
  {
    key: 'requester_name',
    header: 'Pemohon',
    sortable: true,
    width: 180,
    render: (_v, row) => row.requester_name || row.requester_id || '—',
  },
  {
    key: 'created_at',
    header: 'Tanggal',
    sortable: true,
    width: 140,
    render: (_v, row) =>
      row.created_at
        ? new Date(row.created_at * 1000).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
        : '—',
  },
  {
    key: 'status',
    header: 'Status',
    width: 120,
    align: 'center',
    render: () => (
      <span style={{
        display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
        fontSize: 'var(--font-xs)', fontWeight: 600,
        background: 'var(--color-warning-light)', color: 'var(--color-warning-dark)',
      }}>
        Menunggu
      </span>
    ),
  },
]

export default function ApprovalPage() {
  const queryClient = useQueryClient()

  const rowActions: RowActionDef<Approval>[] = [
    {
      key: 'approve',
      label: 'Setujui',
      icon: <CheckCircle size={14} />,
      onClick: async (row) => {
        try {
          await approvalService.approve(row.id)
          await queryClient.invalidateQueries({ queryKey: [QUERY_KEY] })
          toast.success(`Persetujuan "${row.subject}" berhasil disetujui`)
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menyetujui permintaan')
        }
      },
    },
    {
      key: 'reject',
      label: 'Tolak',
      icon: <XCircle size={14} />,
      variant: 'danger' as const,
      onClick: async (row) => {
        try {
          await approvalService.reject(row.id)
          await queryClient.invalidateQueries({ queryKey: [QUERY_KEY] })
          toast.success(`Permintaan "${row.subject}" berhasil ditolak`)
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menolak permintaan')
        }
      },
    },
  ]

  return (
    <ListPageTemplate<Approval>
      title="Persetujuan"
      queryKey={QUERY_KEY}
      fetcher={(params) => approvalService.list(params)}
      columns={columns}
      rowActions={rowActions}
      searchPlaceholder="Cari permintaan..."
      emptyTitle="Tidak ada persetujuan menunggu"
      emptyDescription="Semua permintaan persetujuan telah ditangani."
      helpTitle="Persetujuan"
      helpText="Daftar permintaan persetujuan yang memerlukan tindakan Anda."
      hidePagination={false}
    />
  )
}
