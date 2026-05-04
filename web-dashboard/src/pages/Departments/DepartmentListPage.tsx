import { useNavigate } from 'react-router-dom'
import { Pencil, Building2 } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { departmentService } from '@/services/department.service'

interface Department {
  id: string
  name: string
  description: string
  leader_id: string
  leader_name?: string
  is_active: boolean
  course_count?: number
  batch_upcoming?: number
  batch_ongoing?: number
  batch_completed?: number
  paid_enrollment_count?: number
}

const columns: ColumnDef<Department>[] = [
  {
    key: 'name',
    header: 'Nama Departemen',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Building2 size={16} />
        </div>
        <div>
          <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.name}</div>
          {row.description && (
            <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
              {row.description.length > 80 ? row.description.slice(0, 80) + '...' : row.description}
            </div>
          )}
        </div>
      </div>
    ),
  },
  {
    key: 'leader_name',
    header: 'Kepala Dept.',
    sortable: true,
    width: 160,
    render: (_v, row) => row.leader_name || '—',
  },
  {
    key: 'course_count',
    header: 'Kursus',
    sortable: true,
    width: 80,
    align: 'center',
    render: (_v, row) => row.course_count ?? 0,
  },
  {
    key: 'batch_ongoing',
    header: 'Batch Aktif',
    width: 100,
    align: 'center',
    render: (_v, row) => {
      const total = (row.batch_upcoming ?? 0) + (row.batch_ongoing ?? 0)
      return total > 0 ? (
        <span style={{
          display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 'var(--font-sm)',
        }}>
          {row.batch_ongoing ?? 0}
          {row.batch_upcoming ? (
            <span style={{ color: 'var(--color-text-tertiary)' }}>
              (+{row.batch_upcoming} mendatang)
            </span>
          ) : null}
        </span>
      ) : '—'
    },
  },
  {
    key: 'is_active',
    header: 'Status',
    width: 90,
    align: 'center',
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

export default function DepartmentListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Department>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/pengembangan/departments/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Department>
      title="Departemen"
      addLabel="Tambah Departemen"
      onAdd={() => navigate('/pengembangan/departments/new')}
      queryKey="departments"
      fetcher={(params) => departmentService.list(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/pengembangan/departments/${row.id}`)}
      searchPlaceholder="Cari departemen..."
      exportFilename="departemen"
      emptyTitle="Belum ada departemen"
      emptyDescription="Buat departemen pertama untuk mulai mengelola kursus."
      helpTitle="Departemen"
      helpText="Departemen mengelola kursus, batch, dan fasilitator. Setiap departemen dipimpin oleh Kepala Departemen yang ditunjuk oleh Education Leader."
      deleteConfig={{
        onDelete: (row) => departmentService.delete(row.id),
        dialogTitle: 'Hapus Departemen?',
        dialogBody: (row) => `${row.name} akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: (row) => `Departemen "${row.name}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus departemen',
      }}
    />
  )
}
