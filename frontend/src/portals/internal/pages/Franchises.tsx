import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus, ArrowRight } from 'lucide-react'
import { toast } from 'sonner'
import {
  useFranchisees,
  useRoyaltyRecords,
  useMarkRoyaltyPaid,
  type Franchisee,
  type RoyaltyRecord,
} from '@/lib/api/franchise'
import { formatCurrency } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import StatusBadge from '@/components/shared/StatusBadge'
import TableCard from '@/components/shared/TableCard'
import FilterTabs from '@/components/shared/FilterTabs'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import CreateFranchiseeModal from '@/portals/internal/components/CreateFranchiseeModal'
import Button from '@/components/ui/Button'

// ── Constants ─────────────────────────────────────────────────────────────────

const TABS = [
  { label: 'Franchisees', value: 'Franchisees' },
  { label: 'Royalty', value: 'Royalty' },
]

// ── Page ──────────────────────────────────────────────────────────────────────

export default function Franchises() {
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState('Franchisees')
  const [selectedFranchisee, setSelectedFranchisee] = useState<Franchisee | null>(null)
  const [dialogOpen, setDialogOpen] = useState(false)
  const { data: franchisees = [], isLoading } = useFranchisees()

  const handleViewRoyalty = (franchisee: Franchisee) => {
    setSelectedFranchisee(franchisee)
    setActiveTab('Royalty')
  }

  const subtitle = isLoading
    ? 'Loading…'
    : `${franchisees.length} franchisee${franchisees.length !== 1 ? 's' : ''}`

  const franchiseeColumns: Column<Franchisee>[] = [
    { header: 'Name', accessor: 'name' },
    { header: 'Branch Name', accessor: 'branch_name' },
    { header: 'Location', accessor: 'location' },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <StatusBadge status={row.status} variant="franchisee" />,
    },
    {
      header: '',
      accessor: 'id',
      className: 'text-right',
      cell: (row) => (
        <button
          onClick={() => handleViewRoyalty(row)}
          className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-brand-600 border border-brand-200 rounded-lg hover:bg-brand-50 transition-colors"
        >
          View Royalty
          <ArrowRight className="w-3 h-3" />
        </button>
      ),
    },
  ]

  return (
    <div className="space-y-5">
      <FilterTabs tabs={TABS} active={activeTab} onChange={setActiveTab} />

      {activeTab === 'Franchisees' ? (
        <ListPageTemplate
          title="Franchises"
          subtitle={subtitle}
          actions={
            <Button onClick={() => setDialogOpen(true)}>
              <Plus className="w-4 h-4" />
              Add Franchisee
            </Button>
          }
          columns={franchiseeColumns}
          data={franchisees}
          loading={isLoading}
          pagination={{ page: 1, limit: franchisees.length || 1, total: franchisees.length }}
          onPageChange={() => {}}
          rowKey={(row) => row.id}
          onRowClick={(row) => navigate(`/internal/franchises/${row.id}`)}
        />
      ) : (
        <RoyaltySection selectedFranchisee={selectedFranchisee} />
      )}

      <CreateFranchiseeModal open={dialogOpen} onOpenChange={setDialogOpen} />
    </div>
  )
}

// ── Royalty Section ───────────────────────────────────────────────────────────

function RoyaltySection({ selectedFranchisee }: { selectedFranchisee: Franchisee | null }) {
  const { data, isLoading } = useRoyaltyRecords(selectedFranchisee?.id ?? '')
  const markPaid = useMarkRoyaltyPaid()

  const handleMarkPaid = async (id: string) => {
    try {
      await markPaid.mutateAsync(id)
      toast.success('Royalty record marked as paid')
    } catch {
      toast.error('Failed to mark as paid')
    }
  }

  const royaltyColumns: Column<RoyaltyRecord>[] = [
    { header: 'Period', accessor: 'period' },
    {
      header: 'Gross Revenue',
      accessor: 'gross_revenue',
      cell: (row) => (
        <span className="font-mono text-sm">{formatCurrency(row.gross_revenue)}</span>
      ),
    },
    {
      header: 'Total Royalty',
      accessor: 'total_royalty',
      cell: (row) => (
        <span className="font-mono text-sm">{formatCurrency(row.total_royalty)}</span>
      ),
    },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <StatusBadge status={row.status} variant="royalty" />,
    },
    {
      header: '',
      accessor: 'id',
      className: 'text-right',
      cell: (row) =>
        row.status !== 'paid' ? (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => handleMarkPaid(row.id)}
            loading={markPaid.isPending}
          >
            Mark Paid
          </Button>
        ) : null,
    },
  ]

  if (!selectedFranchisee) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center">
        <p className="text-sm text-neutral-500">
          Select a franchisee to view royalty records
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-5">
      <PageHeader
        title="Royalty Records"
        subtitle={`Showing records for ${selectedFranchisee.name}`}
        actions={<StatusBadge status={selectedFranchisee.status} variant="franchisee" />}
      />

      <TableCard>
        <DataTable
          columns={royaltyColumns}
          data={data ?? []}
          loading={isLoading}
          rowKey={(row) => row.id}
        />
      </TableCard>
    </div>
  )
}
