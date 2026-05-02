import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useInvestments } from '@/lib/api/investment'
import type { InvestmentPlan, InvestmentStatus } from '@/types/investment'
import { INVESTMENT_STATUSES } from '@/types/investment'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import StatusBadge from '@/components/shared/StatusBadge'

const LIMIT = 15

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(amount)
}

const COLUMNS: Column<InvestmentPlan>[] = [
  { header: 'Title', accessor: 'title' },
  { header: 'Category', accessor: 'category', className: 'w-32' },
  {
    header: 'Amount', accessor: 'amount',
    cell: (r) => <span className="text-sm font-mono">{formatCurrency(r.amount)}</span>,
    className: 'w-40 text-right',
  },
  {
    header: 'Expected ROI', accessor: 'expected_roi',
    cell: (r) => <span className="text-sm">{r.expected_roi}%</span>,
    className: 'w-28 text-right',
  },
  {
    header: 'Status', accessor: 'status',
    cell: (r) => <StatusBadge status={r.status} />,
    className: 'w-32',
  },
]

export default function Investments() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState<InvestmentStatus | ''>('')
  const { data, isLoading } = useInvestments({ page, limit: LIMIT, status })

  return (
    <ListPageTemplate
      title="Investment Plans"
      subtitle="Proposals & ROI tracking"
      actions={
        <RoleGate action="create" resource="investment_plan">
          <Button onClick={() => navigate('/internal/investments/new')}>
            <Plus className="w-4 h-4" /> New Plan
          </Button>
        </RoleGate>
      }
      filterTabs={{
        tabs: [
          { label: 'All', value: '' },
          ...INVESTMENT_STATUSES.map((s) => ({ label: s, value: s })),
        ],
        active: status,
        onChange: (v) => { setStatus(v as InvestmentStatus | ''); setPage(1) },
      }}
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/investments/${r.id}`)}
    />
  )
}
