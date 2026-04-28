import { Building2 } from 'lucide-react'
import { useDepartments, type Department } from '@/lib/api/people'
import { formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'

const COLUMNS: Column<Department>[] = [
  { header: 'Name', accessor: 'name' },
  {
    header: 'Status',
    accessor: 'is_active',
    cell: (row) => (
      <span
        className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
          row.is_active
            ? 'bg-emerald-50 text-emerald-700'
            : 'bg-neutral-100 text-neutral-500'
        }`}
      >
        {row.is_active ? 'Active' : 'Inactive'}
      </span>
    ),
  },
  {
    header: 'Created',
    accessor: 'created_at',
    cell: (row) => formatDate(row.created_at),
  },
]

export default function Departments() {
  const { data = [], isLoading } = useDepartments()

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<Building2 className="w-5 h-5 text-brand-600" />}
        title="Departments"
        description={`${data.length} department${data.length !== 1 ? 's' : ''}`}
      />
      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
        <DataTable
          columns={COLUMNS}
          data={data}
          loading={isLoading}
          rowKey={(row) => row.id}
        />
      </div>
    </div>
  )
}
