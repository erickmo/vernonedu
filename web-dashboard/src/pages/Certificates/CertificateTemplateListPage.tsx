import { useNavigate } from 'react-router-dom'
import { Pencil, FileText } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { certificateService } from '@/services/certificate.service'
import { QK } from '@/services/query-keys'

interface CertificateTemplate {
  id: string
  name: string
  type: string
  created_at?: string
  [key: string]: unknown
}

const TYPE_LABELS: Record<string, string> = {
  participant: 'Peserta',
  competency: 'Kompetensi',
}

function formatDate(dateStr?: string): string {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
  }).format(new Date(dateStr))
}

const columns: ColumnDef<CertificateTemplate>[] = [
  {
    key: 'name',
    header: 'Nama Template',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <FileText size={16} />
        </div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.name}</div>
      </div>
    ),
  },
  {
    key: 'type',
    header: 'Jenis',
    width: 140,
    align: 'center',
    render: (_v, row) => {
      const label = TYPE_LABELS[row.type] || row.type
      const isCompetency = row.type === 'competency'
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: isCompetency ? 'var(--color-success-light)' : 'var(--color-info-light)',
          color: isCompetency ? 'var(--color-success-dark)' : 'var(--color-info-dark)',
        }}>
          {label}
        </span>
      )
    },
  },
  {
    key: 'created_at',
    header: 'Dibuat',
    sortable: true,
    width: 140,
    render: (_v, row) => formatDate(row.created_at),
  },
]

export default function CertificateTemplateListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<CertificateTemplate>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/certificates/templates/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<CertificateTemplate>
      title="Template Sertifikat"
      addLabel="Tambah Template"
      onAdd={() => navigate('/certificates/templates/new')}
      queryKey={QK.certificateTemplates}
      fetcher={(params) => certificateService.getTemplates(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/certificates/templates/${row.id}/edit`)}
      searchPlaceholder="Cari template..."
      exportFilename="template-sertifikat"
      hidePagination
      emptyTitle="Belum ada template"
      emptyDescription="Buat template sertifikat untuk menstandardisasi penerbitan sertifikat."
      helpTitle="Template Sertifikat"
      helpText="Template sertifikat digunakan sebagai dasar penerbitan sertifikat peserta dan kompetensi. Buat template dengan desain HTML yang sesuai kebutuhan."
    />
  )
}
