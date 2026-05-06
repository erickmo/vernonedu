import { useNavigate } from 'react-router-dom'
import { Pencil, Tag } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { leadSourceService, type LeadSource } from '@/services/lead-source.service'

const columns: ColumnDef<LeadSource>[] = [
  {
    key: 'name',
    header: 'Nama Sumber',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Tag size={16} />
        </div>
        <span style={{ fontWeight: 600 }}>{row.name}</span>
      </div>
    ),
  },
  {
    key: 'is_active',
    header: 'Status',
    width: 120,
    render: (_v, row) => (
      <span style={{
        display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
        fontSize: 'var(--font-xs)', fontWeight: 600,
        background: row.is_active ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
        color: row.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
      }}>
        {row.is_active ? 'Aktif' : 'Nonaktif'}
      </span>
    ),
  },
]

export default function LeadSourceListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<LeadSource>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/settings/lead-sources/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<LeadSource>
      title="Sumber Lead"
      addLabel="Tambah Sumber"
      onAdd={() => navigate('/settings/lead-sources/new')}
      queryKey="lead-sources"
      fetcher={(params) => leadSourceService.list(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/settings/lead-sources/${row.id}/edit`)}
      searchPlaceholder="Cari sumber..."
      exportFilename="lead-sources"
      emptyTitle="Belum ada sumber lead"
      emptyDescription="Tambahkan sumber untuk melacak dari mana prospek mengetahui layanan Anda."
      helpTitle="Sumber Lead"
      helpText="Sumber lead adalah kategori asal prospek (contoh: Referral, Website). Digunakan saat membuat atau mengedit lead."
      deleteConfig={{
        onDelete: (row) => leadSourceService.delete(row.id) as Promise<void>,
        dialogTitle: 'Hapus Sumber Lead?',
        dialogBody: (row) => `"${row.name}" akan dihapus. Lead yang sudah menggunakan sumber ini tidak akan terpengaruh.`,
        successMessage: (row) => `Sumber "${row.name}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus sumber lead',
      }}
      hidePagination
    />
  )
}
