import { useQueryClient } from '@tanstack/react-query'
import { Check, X } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { apiClient } from '@/services/api.client'
import { toast } from '@/widgets/Toast/Toast'
import type { ListParams } from '@/services/createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

interface CourseVersionApproval {
  id: string
  course_name: string
  version: string
  type: string
  requester: string
  submitted_at: string
}

function formatDate(ts: string) {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(ts))
}

async function fetchPendingApprovals(_params: ListParams): Promise<PaginatedResponse<CourseVersionApproval>> {
  const r = await apiClient.get<any>('/approvals?type=course_version&status=pending')
  const raw = (r as any).data ?? r
  const items: CourseVersionApproval[] = Array.isArray(raw.items) ? raw.items : (Array.isArray(raw) ? raw : [])
  return { items, total: raw.total ?? items.length, offset: 0, limit: 9999 }
}

const columns: ColumnDef<CourseVersionApproval>[] = [
  {
    key: 'course_name',
    header: 'Nama Kursus',
    sortable: true,
    render: (_v, row) => (
      <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.course_name}</div>
    ),
  },
  {
    key: 'version',
    header: 'Versi',
    width: 100,
    render: (_v, row) => row.version || '—',
  },
  {
    key: 'type',
    header: 'Tipe',
    width: 140,
    render: (_v, row) => row.type || '—',
  },
  {
    key: 'requester',
    header: 'Pemohon',
    width: 160,
    render: (_v, row) => row.requester || '—',
  },
  {
    key: 'submitted_at',
    header: 'Diajukan',
    width: 160,
    render: (_v, row) => formatDate(row.submitted_at),
  },
]

export default function CourseApprovalsPage() {
  const queryClient = useQueryClient()

  const rowActions: RowActionDef<CourseVersionApproval>[] = [
    {
      key: 'approve',
      label: 'Setujui',
      icon: <Check size={14} />,
      onClick: async (row) => {
        try {
          await apiClient.put<any>(`/approvals/${row.id}/approve`, {})
          toast.success(`Versi kursus "${row.course_name}" telah disetujui`)
          await queryClient.invalidateQueries({ queryKey: ['course-approvals'] })
        } catch {
          toast.error('Gagal menyetujui permohonan')
        }
      },
    },
    {
      key: 'reject',
      label: 'Tolak',
      icon: <X size={14} />,
      variant: 'danger' as const,
      onClick: async (row) => {
        try {
          await apiClient.put<any>(`/approvals/${row.id}/reject`, { note: '' })
          toast.success(`Versi kursus "${row.course_name}" telah ditolak`)
          await queryClient.invalidateQueries({ queryKey: ['course-approvals'] })
        } catch {
          toast.error('Gagal menolak permohonan')
        }
      },
    },
  ]

  return (
    <ListPageTemplate<CourseVersionApproval>
      title="Persetujuan Kurikulum"
      queryKey="course-approvals"
      fetcher={fetchPendingApprovals}
      columns={columns}
      rowActions={rowActions}
      hidePagination={true}
      searchPlaceholder="Cari permohonan..."
      helpText="Daftar versi kursus yang memerlukan persetujuan Kepala Departemen."
      emptyTitle="Tidak ada yang perlu disetujui"
      emptyDescription="Semua versi kursus telah ditinjau."
    />
  )
}
