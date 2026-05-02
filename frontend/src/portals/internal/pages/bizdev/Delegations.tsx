import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useDelegations } from '@/lib/api/delegation'
import type { Delegation, DelegationStatus, DelegationType } from '@/types/delegation'
import { DELEGATION_STATUSES, DELEGATION_TYPES } from '@/types/delegation'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import StatusBadge from '@/components/shared/StatusBadge'

const LIMIT = 15

const COLUMNS: Column<Delegation>[] = [
  { header: 'Title', accessor: 'title' },
  { header: 'Type', accessor: 'type', className: 'w-40' },
  { header: 'Assigned To', accessor: 'assigned_to_name', className: 'w-40' },
  { header: 'Priority', accessor: 'priority', className: 'w-24' },
  {
    header: 'Status', accessor: 'status',
    cell: (r) => <StatusBadge status={r.status} />,
    className: 'w-32',
  },
]

export default function Delegations() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState<DelegationStatus | ''>('')
  const [type, setType] = useState<DelegationType | ''>('')
  const [assignedTo, setAssignedTo] = useState('')
  const { data, isLoading } = useDelegations({
    page, limit: LIMIT, status, type,
    assigned_to_id: assignedTo || undefined,
  })

  return (
    <ListPageTemplate
      title="Delegations"
      subtitle="Tasks, requests, and assignments"
      actions={
        <RoleGate action="create" resource="delegation">
          <Button onClick={() => navigate('/internal/delegations/new')}>
            <Plus className="w-4 h-4" /> New Delegation
          </Button>
        </RoleGate>
      }
      filterTabs={{
        tabs: [
          { label: 'All', value: '' },
          ...DELEGATION_STATUSES.map((s) => ({ label: s, value: s })),
        ],
        active: status,
        onChange: (v) => { setStatus(v as DelegationStatus | ''); setPage(1) },
      }}
      filters={
        <div className="flex gap-2">
          <select
            value={type}
            onChange={(e) => { setType(e.target.value as DelegationType | ''); setPage(1) }}
            className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
          >
            <option value="">All types</option>
            {DELEGATION_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
          </select>
          <input
            type="text"
            value={assignedTo}
            onChange={(e) => { setAssignedTo(e.target.value); setPage(1) }}
            placeholder="Assigned To ID…"
            className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
          />
        </div>
      }
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/delegations/${r.id}`)}
    />
  )
}
