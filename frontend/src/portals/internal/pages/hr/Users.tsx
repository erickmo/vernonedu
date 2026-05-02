import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useUsers } from '@/lib/api/user'
import type { User } from '@/types/user'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'

const LIMIT = 15

const COLUMNS: Column<User>[] = [
  { header: 'Name', accessor: 'name' },
  { header: 'Email', accessor: 'email' },
  {
    header: 'Roles',
    accessor: 'roles',
    cell: (r) => (
      <span className="text-sm text-neutral-600">
        {(r.roles ?? []).map((x) => x.replace(/_/g, ' ')).join(', ')}
      </span>
    ),
  },
]

export default function Users() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')

  const { data, isLoading } = useUsers({ page, limit: LIMIT, name: search || undefined })
  const list = data as { data?: User[]; total?: number } | undefined
  const rows = list?.data ?? []
  const total = list?.total ?? rows.length

  return (
    <ListPageTemplate
      title="Users"
      subtitle="Manage staff accounts and roles"
      actions={
        <RoleGate action="create" resource="user">
          <Button onClick={() => navigate('/internal/users/new')}>
            <Plus className="w-4 h-4" /> Add User
          </Button>
        </RoleGate>
      }
      search={{ value: search, onChange: setSearch, placeholder: 'Search by name…' }}
      columns={COLUMNS}
      data={rows}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/users/${r.id}/edit`)}
    />
  )
}
