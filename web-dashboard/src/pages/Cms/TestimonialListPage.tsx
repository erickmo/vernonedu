import { useNavigate } from 'react-router-dom'
import { Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { cmsService } from '@/services/cms.service'

interface Testimonial {
  id: string
  name?: string
  student_name?: string
  course_name?: string
  course?: string
  rating?: number
  is_featured?: boolean
  created_at?: string
  [key: string]: unknown
}

const columns: ColumnDef<Testimonial>[] = [
  {
    key: 'name',
    header: 'Nama',
    render: (_v, row) => (
      <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
        {row.student_name || row.name || '—'}
      </div>
    ),
  },
  {
    key: 'course_name',
    header: 'Kursus',
    render: (_v, row) => (
      <span>{row.course_name || row.course || '—'}</span>
    ),
  },
  {
    key: 'rating',
    header: 'Rating',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const val = row.rating ?? 0
      return (
        <span style={{ color: 'var(--color-warning)', fontWeight: 600 }}>
          {'★'.repeat(Math.min(val, 5))}{val > 0 ? ` ${val}/5` : '—'}
        </span>
      )
    },
  },
  {
    key: 'is_featured',
    header: 'Status',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const featured = row.is_featured === true
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: featured ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
          color: featured ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
        }}>
          {featured ? 'Featured' : 'Biasa'}
        </span>
      )
    },
  },
  {
    key: 'created_at',
    header: 'Tanggal',
    width: 160,
    render: (_v, row) => {
      if (!row.created_at) return '—'
      return new Date(row.created_at as string).toLocaleDateString('id-ID', {
        day: '2-digit', month: 'short', year: 'numeric',
      })
    },
  },
]

export default function TestimonialListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Testimonial>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/cms/testimonials/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Testimonial>
      title="Testimoni"
      addLabel="Tambah Testimoni"
      onAdd={() => navigate('/cms/testimonials/new')}
      queryKey="cms-testimonials"
      fetcher={async (_params) => {
        const raw = await cmsService.listTestimonials()
        const items = Array.isArray(raw) ? raw : (raw as any)?.items ?? []
        return { items, total: items.length, limit: 9999, offset: 0 }
      }}
      columns={columns}
      rowActions={rowActions}
      hidePagination
      searchPlaceholder="Cari testimoni..."
      emptyTitle="Belum ada testimoni"
      emptyDescription="Tambahkan testimoni siswa untuk ditampilkan di website publik."
      deleteConfig={{
        onDelete: (row) => cmsService.deleteTestimonial(row.id),
        dialogTitle: 'Hapus Testimoni?',
        dialogBody: (row) => `Testimoni dari "${row.student_name || row.name}" akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: (row) => `Testimoni dari "${row.student_name || row.name}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus testimoni',
      }}
    />
  )
}
