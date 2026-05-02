import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useBuildings } from '@/lib/api/location'
import type { Building } from '@/types/building'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'

const LIMIT = 15

const COLUMNS: Column<Building>[] = [
  { header: 'Name', accessor: 'name' },
  { header: 'Address', accessor: 'address' },
  {
    header: 'Rooms',
    accessor: 'room_count',
    cell: (r) => <span className="text-sm">{r.room_count ?? 0}</span>,
    className: 'w-24',
  },
]

export default function Buildings() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)

  const { data, isLoading } = useBuildings({ page, limit: LIMIT })

  return (
    <ListPageTemplate
      title="Buildings"
      subtitle="Manage locations and rooms"
      actions={
        <RoleGate action="create" resource="building">
          <Button onClick={() => navigate('/internal/buildings/new')}>
            <Plus className="w-4 h-4" /> Add Building
          </Button>
        </RoleGate>
      }
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/buildings/${r.id}`)}
    />
  )
}
