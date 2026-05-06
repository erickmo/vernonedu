import { useNavigate } from 'react-router-dom'
import { Pencil, User } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { leadService } from '@/services/lead.service'

interface Lead {
  id: string
  name: string
  email: string
  phone: string
  source: { id: string; name: string } | null
  status: string
  notes: string
  created_at: number
}

const STATUS_COLORS: Record<string, { bg: string; text: string }> = {
  new: { bg: 'var(--color-info-light)', text: 'var(--color-info-dark)' },
  contacted: { bg: 'var(--color-warning-light)', text: 'var(--color-warning-dark)' },
  interested: { bg: 'var(--color-primary-light)', text: 'var(--color-primary-dark)' },
  negotiating: { bg: 'var(--color-secondary-light)', text: 'var(--color-secondary-dark)' },
  enrolled: { bg: 'var(--color-success-light)', text: 'var(--color-success-dark)' },
  not_interested: { bg: 'var(--color-error-light)', text: 'var(--color-error-dark)' },
}

const columns: ColumnDef<Lead>[] = [
  {
    key: 'name',
    header: 'Nama',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <User size={16} />
        </div>
        <div>
          <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.name}</div>
          {row.email && (
            <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
              {row.email}
            </div>
          )}
        </div>
      </div>
    ),
  },
  {
    key: 'phone',
    header: 'Telepon',
    sortable: true,
    width: 140,
    render: (_v, row) => row.phone || '—',
  },
  {
    key: 'source',
    header: 'Sumber',
    width: 120,
    render: (_v, row) => row.source?.name ?? '—',
  },
  {
    key: 'status',
    header: 'Status',
    sortable: true,
    width: 120,
    render: (v, _row) => {
      const colors = STATUS_COLORS[v] || { bg: 'var(--color-surface-alt)', text: 'var(--color-text-tertiary)' }
      const label = v
        ?.split('_')
        .map((w: string) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(' ') || '—'
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: colors.bg,
          color: colors.text,
        }}>
          {label}
        </span>
      )
    },
  },
  {
    key: 'created_at',
    header: 'Dibuat',
    sortable: true,
    width: 100,
    align: 'center',
    render: (v, _row) =>
      v
        ? new Intl.DateTimeFormat('id-ID', {
            day: '2-digit',
            month: 'short',
            year: 'numeric',
          }).format(new Date(v * 1000))
        : '—',
  },
]

const filterDefs: FilterDef[] = [
  {
    key: 'status',
    label: 'Status',
    type: 'select',
    options: [
      { label: 'Baru', value: 'new' },
      { label: 'Dihubungi', value: 'contacted' },
      { label: 'Tertarik', value: 'interested' },
      { label: 'Negosiasi', value: 'negotiating' },
      { label: 'Terdaftar', value: 'enrolled' },
      { label: 'Tidak Tertarik', value: 'not_interested' },
    ],
  },
]

export default function LeadListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Lead>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/leads/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Lead>
      title="Leads"
      addLabel="Tambah Lead"
      onAdd={() => navigate('/leads/new')}
      queryKey="leads"
      fetcher={(params) => leadService.list(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/leads/${row.id}`)}
      searchPlaceholder="Cari leads..."
      exportFilename="leads"
      emptyTitle="Belum ada leads"
      emptyDescription="Tambahkan lead baru untuk mulai mengelola prospek pelanggan."
      helpTitle="Leads"
      helpText="Leads adalah prospek pelanggan yang belum terdaftar sebagai siswa. Anda dapat melacak minat, sumber, dan status kontak mereka untuk mengkonversi menjadi pendaftaran."
      deleteConfig={{
        onDelete: (row) => leadService.delete(row.id) as Promise<void>,
        dialogTitle: 'Hapus Lead?',
        dialogBody: (row) => `${row.name} akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: (row) => `Lead "${row.name}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus lead',
      }}
      filterDefs={filterDefs}
    />
  )
}
