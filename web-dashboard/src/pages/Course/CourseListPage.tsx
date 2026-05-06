import { useNavigate } from 'react-router-dom'
import { Pencil, BookOpen } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { courseService } from '@/services/course.service'

interface Course {
  id: string
  name: string
  description: string
  department_id: string
  department_name: string
  course_type: string
  is_active: boolean
  version_count?: number
  batch_count?: number
}

const columns: ColumnDef<Course>[] = [
  {
    key: 'name',
    header: 'Nama Kursus',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <BookOpen size={16} />
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
    key: 'department_name',
    header: 'Departemen',
    sortable: true,
    width: 160,
    render: (_v, row) => row.department_name || '—',
  },
  {
    key: 'course_type',
    header: 'Tipe',
    sortable: true,
    width: 140,
    render: (_v, row) => row.course_type || '—',
  },
  {
    key: 'version_count',
    header: 'Versi',
    sortable: true,
    width: 80,
    align: 'center',
    render: (_v, row) => row.version_count ?? 0,
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

export default function CourseListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Course>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/course/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Course>
      title="Kurikulum"
      addLabel="Tambah Kursus"
      onAdd={() => navigate('/course/new')}
      queryKey="courses"
      fetcher={(params) => courseService.list(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/course/${row.id}`)}
      searchPlaceholder="Cari kursus..."
      exportFilename="kurikulum"
      emptyTitle="Belum ada kursus"
      emptyDescription="Buat kursus pertama untuk mulai mengelola kurikulum."
      helpTitle="Kurikulum"
      helpText="Kurikulum mengelola kursus, versi silabus, modul pembelajaran, dan konten pendukung. Setiap kursus dapat memiliki beberapa versi silabus."
      deleteConfig={{
        onDelete: (row) => courseService.delete(row.id),
        dialogTitle: 'Hapus Kursus?',
        dialogBody: (row) => `${row.name} akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: (row) => `Kursus "${row.name}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus kursus',
      }}
    />
  )
}
