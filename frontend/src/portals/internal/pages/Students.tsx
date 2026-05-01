import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useStudents, type Student } from '@/lib/api/identity'
import { formatDate } from '@/lib/utils/format'
import { Column } from '@/components/shared/DataTable'
import { cn } from '@/lib/utils/cn'
import AvatarInitial from '@/components/shared/AvatarInitial'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import CreateStudentModal from '@/portals/internal/components/CreateStudentModal'

const SOURCE_FILTERS = [
  { label: 'All', value: '' },
  { label: 'B2C', value: 'b2c' },
  { label: 'B2B', value: 'b2b' },
]

const LIMIT = 15

const COLUMNS: Column<Student>[] = [
  {
    header: '',
    accessor: 'name',
    className: 'w-10',
    cell: (row) => <AvatarInitial name={row.name} />,
  },
  { header: 'Name', accessor: 'name' },
  { header: 'Email', accessor: 'email' },
  { header: 'Phone', accessor: 'phone' },
  {
    header: 'Source',
    accessor: 'source',
    cell: (row) => (
      <span
        className={cn(
          'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
          row.source === 'b2b' ? 'bg-violet-50 text-violet-700' : 'bg-brand-50 text-brand-700',
        )}
      >
        {row.source.toUpperCase()}
      </span>
    ),
  },
  {
    header: 'Joined',
    accessor: 'created_at',
    cell: (row) => (
      <span className="text-xs text-neutral-500 font-mono">{formatDate(row.created_at)}</span>
    ),
  },
]

export default function Students() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [sourceFilter, setSourceFilter] = useState<'' | 'b2c' | 'b2b'>('')
  const [search, setSearch] = useState('')
  const [open, setOpen] = useState(false)

  const { data, isLoading } = useStudents({
    source: sourceFilter || undefined,
    search: search || undefined,
    page,
    limit: LIMIT,
  })

  return (
    <>
      <ListPageTemplate
        title="Students"
        subtitle="Manage registered students"
        actions={
          <Button onClick={() => setOpen(true)}>
            <Plus className="w-4 h-4" />
            Add Student
          </Button>
        }
        search={{
          value: search,
          onChange: (v) => { setSearch(v); setPage(1) },
          placeholder: 'Search by name or email…',
        }}
        filterTabs={{
          tabs: SOURCE_FILTERS,
          active: sourceFilter,
          onChange: (v) => { setSourceFilter(v as '' | 'b2c' | 'b2b'); setPage(1) },
        }}
        columns={COLUMNS}
        data={data?.data ?? []}
        loading={isLoading}
        pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
        onPageChange={setPage}
        rowKey={(row) => row.id}
        onRowClick={(row) => navigate(`/internal/students/${row.id}`)}
      />
      <CreateStudentModal open={open} onOpenChange={setOpen} />
    </>
  )
}
