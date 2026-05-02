import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useBranches } from '@/lib/api/branch'
import type { Branch } from '@/types/branch'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'

const LIMIT = 50

const COLUMNS: Column<Branch>[] = [
  { header: 'Code', accessor: 'code' },
  { header: 'Name', accessor: 'name' },
  { header: 'City', accessor: 'city' },
  { header: 'Province', accessor: 'province' },
  {
    header: 'Active',
    accessor: 'is_active',
    cell: (r) => (
      <span
        className={
          r.is_active
            ? 'inline-flex px-2 py-0.5 rounded-full text-xs bg-emerald-50 text-emerald-700'
            : 'inline-flex px-2 py-0.5 rounded-full text-xs bg-neutral-100 text-neutral-500'
        }
      >
        {r.is_active ? 'Active' : 'Inactive'}
      </span>
    ),
  },
]

export default function Branches() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const { data, isLoading } = useBranches({ page, limit: LIMIT })

  return (
    <ListPageTemplate
      title="Branches"
      subtitle="Manage company branches"
      actions={
        <RoleGate action="create" resource="branch">
          <Button onClick={() => navigate('/internal/settings/branches/new')}>
            <Plus className="w-4 h-4" /> Add Branch
          </Button>
        </RoleGate>
      }
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/settings/branches/${r.id}/edit`)}
    />
  )
}
