import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { usePartners, type Partner } from '@/lib/api/businessops'
import { formatDate } from '@/lib/utils/format'
import { Column } from '@/components/shared/DataTable'
import { cn } from '@/lib/utils/cn'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'

const PARTNER_TYPE_LABELS: Record<Partner['type'], string> = {
  university: 'University',
  vendor: 'Vendor',
  sponsor: 'Sponsor',
  franchise_candidate: 'Franchise Candidate',
  community: 'Community',
  other: 'Other',
}

const COLUMNS: Column<Partner>[] = [
  { header: 'Name', accessor: 'name' },
  {
    header: 'Type',
    accessor: 'type',
    cell: (row) => (
      <span className="text-sm">{PARTNER_TYPE_LABELS[row.type]}</span>
    ),
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (row) => (
      <span
        className={cn(
          'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
          row.status === 'active'
            ? 'bg-emerald-50 text-emerald-700'
            : row.status === 'lead'
            ? 'bg-amber-50 text-amber-700'
            : 'bg-neutral-100 text-neutral-500',
        )}
      >
        {row.status.charAt(0).toUpperCase() + row.status.slice(1)}
      </span>
    ),
  },
  {
    header: 'Contact',
    accessor: 'contact_name',
    cell: (row) => (
      <span className="text-sm text-neutral-500">{row.contact_name ?? '—'}</span>
    ),
  },
  {
    header: 'Created',
    accessor: 'created_at',
    cell: (row) => formatDate(row.created_at),
  },
]

export default function Partners() {
  const navigate = useNavigate()
  const { data = [], isLoading } = usePartners()

  return (
    <ListPageTemplate
      title="Partners"
      subtitle={isLoading ? 'Loading…' : `${data.length} partner${data.length !== 1 ? 's' : ''}`}
      actions={
        <Button variant="primary" onClick={() => navigate('/internal/partners/new')}>
          <Plus className="w-4 h-4" />
          Add Partner
        </Button>
      }
      columns={COLUMNS}
      data={data}
      loading={isLoading}
      pagination={{ page: 1, limit: 100, total: data.length }}
      onPageChange={() => {}}
      rowKey={(row) => row.id}
      onRowClick={(row) => navigate(`/internal/partners/${row.id}`)}
    />
  )
}
