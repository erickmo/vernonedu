import { Briefcase } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { jobVacancyService } from '@/services/jobvacancy.service'
import type { ListParams } from '@/services/createEntityService'

interface Lowongan {
  id: string
  title: string
  company_name?: string
  department_name?: string
  location?: string
  status?: string
  created_at?: string
  [key: string]: unknown
}

const columns: ColumnDef<Lowongan>[] = [
  {
    key: 'title',
    header: 'Posisi',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: '50%',
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0, fontSize: 'var(--font-sm)', fontWeight: 600,
        }}>
          {row.title?.charAt(0)?.toUpperCase() || '?'}
        </div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.title || '—'}
        </div>
      </div>
    ),
  },
  {
    key: 'company_name',
    header: 'Perusahaan',
    sortable: true,
    width: 180,
    render: (_v, row) => row.company_name || '—',
  },
  {
    key: 'department_name',
    header: 'Departemen',
    sortable: true,
    width: 160,
    render: (_v, row) => row.department_name || '—',
  },
  {
    key: 'location',
    header: 'Lokasi',
    width: 140,
    render: (_v, row) => row.location || '—',
  },
  {
    key: 'status',
    header: 'Status',
    width: 120,
    render: (_v, row) => row.status || '—',
  },
  {
    key: 'created_at',
    header: 'Dibuat',
    sortable: true,
    width: 140,
    render: (_v, row) => row.created_at ? new Date(row.created_at).toLocaleDateString('id-ID') : '—',
  },
]

const rowActions: RowActionDef<Lowongan>[] = [
  {
    key: 'view',
    label: 'Lihat Detail',
    icon: <Briefcase size={14} />,
    onClick: () => {},
  },
]

function fetchLowongan(params: ListParams) {
  return jobVacancyService.list(params)
}

export default function TalentPoolLowonganPage() {
  return (
    <ListPageTemplate<Lowongan>
      title="Lowongan"
      queryKey="talentpool-lowongan"
      fetcher={fetchLowongan}
      columns={columns}
      rowActions={rowActions}
      searchPlaceholder="Cari lowongan..."
      exportFilename="talentpool-lowongan"
      emptyTitle="Belum ada lowongan"
      emptyDescription="Lowongan dari perusahaan partner akan muncul di sini."
      helpTitle="Lowongan"
      helpText="Daftar lowongan pekerjaan dari perusahaan partner untuk kandidat Talent Pool."
    />
  )
}
