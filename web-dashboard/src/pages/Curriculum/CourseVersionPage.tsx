import { useParams, useNavigate } from 'react-router-dom'
import { Clock } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { apiClient } from '@/services/api.client'

interface Version {
  id: string
  version_number: string
  description: string
  is_approved: boolean
  created_at: number
}

const columns: ColumnDef<Version>[] = [
  {
    key: 'version_number',
    header: 'Nomor Versi',
    sortable: true,
    width: 120,
    render: (v, _row) => (
      <span style={{ fontWeight: 600, color: 'var(--color-primary)' }}>
        v{v}
      </span>
    ),
  },
  {
    key: 'description',
    header: 'Deskripsi',
    sortable: true,
    render: (_v, row) => (
      <div style={{ fontSize: 'var(--font-sm)' }}>
        {row.description || '—'}
      </div>
    ),
  },
  {
    key: 'is_approved',
    header: 'Status Persetujuan',
    sortable: true,
    width: 140,
    align: 'center',
    render: (_v, row) => (
      <span style={{
        display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
        fontSize: 'var(--font-xs)', fontWeight: 600,
        background: row.is_approved ? 'var(--color-success-light)' : 'var(--color-warning-light)',
        color: row.is_approved ? 'var(--color-success-dark)' : 'var(--color-warning-dark)',
      }}>
        {row.is_approved ? 'Disetujui' : 'Draft'}
      </span>
    ),
  },
  {
    key: 'created_at',
    header: 'Dibuat',
    sortable: true,
    width: 120,
    render: (v, _row) => {
      if (!v) return '—'
      return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit', month: 'short', year: 'numeric',
      }).format(new Date(v * 1000))
    },
  },
]

export default function CourseVersionPage() {
  const { courseId } = useParams<{ courseId: string }>()
  const navigate = useNavigate()

  const { data: course } = useQuery({
    queryKey: ['course', courseId],
    queryFn: () => apiClient.get<any>(`/curriculum/courses/${courseId}`).then(r => (r as any).data ?? r),
  })

  const rowActions: RowActionDef<Version>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Clock size={14} />,
      onClick: (row) => navigate(`/curriculum/${courseId}/versions/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Version>
      title={`Versi Silabus - ${course?.name ?? 'Kursus'}`}
      addLabel="Tambah Versi"
      onAdd={() => navigate(`/curriculum/${courseId}/versions/new`)}
      queryKey={['course-versions', courseId].join('-')}
      fetcher={async (params) => {
        const res = await apiClient.get<any>(`/curriculum/versions?course_id=${courseId}${buildQS(params)}`)
        return (res as any).data ?? res
      }}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/curriculum/${courseId}/versions/${row.id}/edit`)}
      searchPlaceholder="Cari versi..."
      exportFilename="versi-silabus"
      emptyTitle="Belum ada versi silabus"
      emptyDescription="Buat versi silabus pertama untuk kursus ini."
      helpTitle="Versi Silabus"
      helpText="Versi silabus berisi modul pembelajaran dan konten yang akan digunakan dalam batch kelas. Setiap perubahan silabus memerlukan persetujuan dari Kepala Departemen."
    />
  )
}

function buildQS(params?: Record<string, any>): string {
  if (!params) return ''
  const q = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') q.set(k, String(v))
  })
  const s = q.toString()
  return s ? `&${s}` : ''
}
