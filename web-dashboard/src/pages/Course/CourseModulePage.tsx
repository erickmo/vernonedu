import { useNavigate, useParams } from 'react-router-dom'
import { Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { courseModuleService } from '@/services/course-module.service'
import type { CourseModule } from '@/services/course-module.service'

const columns: ColumnDef<CourseModule>[] = [
  {
    key: 'order',
    header: '#',
    width: 48,
    align: 'center',
    render: (_v, row) => row.order,
  },
  {
    key: 'title',
    header: 'Judul Modul',
    sortable: true,
    render: (_v, row) => (
      <div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.title}</div>
        {row.description && (
          <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
            {row.description.length > 80 ? row.description.slice(0, 80) + '...' : row.description}
          </div>
        )}
      </div>
    ),
  },
  {
    key: 'tools',
    header: 'Tools',
    width: 80,
    align: 'center',
    render: (_v, row) => row.tools?.length ?? 0,
  },
  {
    key: 'requirements',
    header: 'Prasyarat',
    width: 100,
    align: 'center',
    render: (_v, row) => row.requirements?.length ?? 0,
  },
]

export default function CourseModulePage() {
  const navigate = useNavigate()
  const { courseId, versionId } = useParams<{ courseId: string; versionId: string }>()

  const rowActions: RowActionDef<CourseModule>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => console.log('edit module', row.id),
    },
  ]

  return (
    <ListPageTemplate<CourseModule>
      title="Modul Kursus"
      queryKey={`course-modules-${versionId}`}
      fetcher={(params) => courseModuleService.list(versionId!, params)}
      columns={columns}
      rowActions={rowActions}
      hidePagination={true}
      searchPlaceholder="Cari modul..."
      emptyTitle="Belum ada modul"
      emptyDescription="Tambah modul pertama untuk versi kursus ini."
      helpText="Modul adalah unit pembelajaran dalam sebuah versi kursus. Setiap modul berisi tools yang dibutuhkan dan prasyarat yang harus dipenuhi peserta."
      deleteConfig={{
        onDelete: (row) => courseModuleService.delete(row.id),
        dialogTitle: 'Hapus Modul?',
        dialogBody: (row) => `Modul "${row.title}" akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: (row) => `Modul "${row.title}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus modul',
      }}
      actions={
        <button
          onClick={() => navigate(courseId ? `/course/${courseId}` : -1 as any)}
          style={{
            background: 'none', border: '1px solid var(--color-border)',
            borderRadius: 'var(--radius-md)', padding: '6px 14px',
            fontSize: 'var(--font-sm)', cursor: 'pointer', color: 'var(--color-text-secondary)',
          }}
        >
          Kembali
        </button>
      }
    />
  )
}
