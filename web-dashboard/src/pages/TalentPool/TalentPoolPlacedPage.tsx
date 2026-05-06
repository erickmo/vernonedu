import { UserCheck } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { talentPoolService } from '@/services/talentpool.service'
import type { ListParams } from '@/services/createEntityService'

interface TalentPoolEntry {
  id: string
  student_name: string
  department_name?: string
  status?: string
  placement?: {
    company_name?: string
    position?: string
    start_date?: string
  }
  [key: string]: unknown
}

const columns: ColumnDef<TalentPoolEntry>[] = [
  {
    key: 'student_name',
    header: 'Nama',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: '50%',
          background: 'var(--color-success-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-success)', flexShrink: 0, fontSize: 'var(--font-sm)', fontWeight: 600,
        }}>
          {row.student_name?.charAt(0)?.toUpperCase() || '?'}
        </div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.student_name || '—'}
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
    key: 'placement_company',
    header: 'Perusahaan',
    width: 180,
    render: (_v, row) => (row.placement as any)?.company_name || '—',
  },
  {
    key: 'placement_position',
    header: 'Posisi',
    width: 160,
    render: (_v, row) => (row.placement as any)?.position || '—',
  },
  {
    key: 'placement_start_date',
    header: 'Tanggal Mulai',
    width: 140,
    render: (_v, row) => {
      const d = (row.placement as any)?.start_date
      return d ? new Date(d).toLocaleDateString('id-ID') : '—'
    },
  },
]

const rowActions: RowActionDef<TalentPoolEntry>[] = [
  {
    key: 'view',
    label: 'Lihat Detail',
    icon: <UserCheck size={14} />,
    onClick: () => {},
  },
]

export default function TalentPoolPlacedPage() {
  return (
    <ListPageTemplate<TalentPoolEntry>
      title="Ditempatkan"
      queryKey="talentpool-placed"
      fetcher={(params: ListParams) => talentPoolService.list({ ...params, status: 'placed' })}
      columns={columns}
      rowActions={rowActions}
      searchPlaceholder="Cari kandidat..."
      exportFilename="talentpool-ditempatkan"
      emptyTitle="Belum ada kandidat yang ditempatkan"
      emptyDescription="Kandidat akan muncul di sini setelah status diubah menjadi Ditempatkan."
      helpTitle="Ditempatkan"
      helpText="Daftar kandidat Program Karir yang telah berhasil ditempatkan di perusahaan partner."
    />
  )
}
