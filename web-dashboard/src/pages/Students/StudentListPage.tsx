import { useNavigate } from 'react-router-dom'
import { Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { studentService } from '@/services/student.service'

interface Student {
  id: string
  name: string
  email: string
  phone?: string
  is_active: boolean
  enrollment_count?: number
  created_at?: number
  updated_at?: number
}

const columns: ColumnDef<Student>[] = [
  {
    key: 'name',
    header: 'Nama Siswa',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 'var(--radius-full)',
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
          fontSize: 'var(--font-sm)', fontWeight: 600,
        }}>
          {row.name ? row.name.charAt(0).toUpperCase() : '?'}
        </div>
        <div>
          <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.name}</div>
          <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
            {row.email}
          </div>
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
    key: 'enrollment_count',
    header: 'Enrollment',
    sortable: true,
    width: 100,
    align: 'center',
    render: (_v, row) => row.enrollment_count ?? 0,
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
        {row.is_active ? 'Aktif' : 'Alumni'}
      </span>
    ),
  },
]

export default function StudentListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Student>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/students/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Student>
      title="Siswa"
      addLabel="Tambah Siswa"
      onAdd={() => navigate('/students/new')}
      queryKey="students"
      fetcher={(params) => studentService.list(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/students/${row.id}`)}
      searchPlaceholder="Cari siswa..."
      exportFilename="siswa"
      emptyTitle="Belum ada siswa"
      emptyDescription="Tambahkan siswa pertama untuk mulai mengelola data peserta."
      helpTitle="Siswa"
      helpText="Siswa adalah peserta yang terdaftar dalam kursus dan batch. Setiap siswa memiliki data pribadi, riwayat enrollment, dan sertifikat."
      deleteConfig={{
        onDelete: async (row) => {
          await studentService.delete(row.id)
        },
        dialogTitle: 'Hapus Siswa?',
        dialogBody: (row) => `${row.name} akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: (row) => `Siswa "${row.name}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus siswa',
      }}
    />
  )
}
