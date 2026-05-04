import { useNavigate } from 'react-router-dom'
import { Handshake } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef } from '@/widgets/DataTable/DataTable'
import { partnerService } from '@/services/partner.service'

interface Partner {
  id: string
  name: string
  type?: string
  contact_person?: string
  contact_email?: string
  mou_status?: 'active' | 'expired' | 'none'
  [key: string]: unknown
}

const MOU_STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:  { label: 'Aktif',    bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  expired: { label: 'Kedaluwarsa', bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  none:    { label: 'Tidak Ada', bg: 'var(--color-surface-alt)',   color: 'var(--color-text-tertiary)' },
}

const columns: ColumnDef<Partner>[] = [
  {
    key: 'name',
    header: 'Nama Partner',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Handshake size={16} />
        </div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.name || '—'}
        </div>
      </div>
    ),
  },
  {
    key: 'type',
    header: 'Jenis',
    width: 140,
    align: 'center',
    render: (_v, row) => {
      if (!row.type) return '—'
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: 'var(--color-info-light)', color: 'var(--color-info-dark)',
        }}>
          {row.type}
        </span>
      )
    },
  },
  {
    key: 'contact_person',
    header: 'Kontak',
    width: 220,
    render: (_v, row) => (
      <div>
        <div style={{ fontWeight: 500 }}>{row.contact_person || '—'}</div>
        {row.contact_email && (
          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginTop: 1 }}>
            {row.contact_email}
          </div>
        )}
      </div>
    ),
  },
  {
    key: 'mou_status',
    header: 'MOU Status',
    width: 130,
    align: 'center',
    render: (_v, row) => {
      const status = row.mou_status || 'none'
      const cfg = MOU_STATUS_CONFIG[status] || MOU_STATUS_CONFIG.none
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: cfg.bg, color: cfg.color,
        }}>
          {cfg.label}
        </span>
      )
    },
  },
]

export default function PartnerListPage() {
  const navigate = useNavigate()

  return (
    <ListPageTemplate<Partner>
      title="Partner"
      addLabel="Tambah Partner"
      onAdd={() => navigate('/partners/new')}
      queryKey="partners"
      fetcher={(params) => partnerService.list(params)}
      columns={columns}
      onRowClick={(row) => navigate(`/partners/${row.id}`)}
      searchPlaceholder="Cari partner..."
      exportFilename="partner"
      emptyTitle="Belum ada partner"
      emptyDescription="Tambahkan partner untuk mengelola kolaborasi dan MOU."
      helpTitle="Partner"
      helpText="Partner adalah perusahaan atau institusi eksternal yang berkolaborasi dalam program kursus, proyek, atau talent pool."
    />
  )
}
