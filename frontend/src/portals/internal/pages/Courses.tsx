import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useMasterCourses } from '@/lib/api/curriculum'
import type { MasterCourse, MasterCourseStatus } from '@/types/mastercourse'
import { FIELDS } from '@/schemas/mastercourse'
import { Column } from '@/components/shared/DataTable'
import StatusBadge from '@/components/shared/StatusBadge'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'

const LIMIT = 15

const COLUMNS: Column<MasterCourse>[] = [
  { header: 'Code', accessor: 'course_code', className: 'font-mono text-xs w-28' },
  { header: 'Name', accessor: 'course_name' },
  { header: 'Field', accessor: 'field' },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => <StatusBadge status={r.status} />,
  },
]

export default function Courses() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [field, setField] = useState<string>('')
  const [status, setStatus] = useState<MasterCourseStatus | ''>('')

  const { data, isLoading } = useMasterCourses({
    page,
    limit: LIMIT,
    search: search || undefined,
    field: field || undefined,
    status: status || undefined,
  })

  return (
    <ListPageTemplate
      title="Courses"
      subtitle="Manage curriculum master courses"
      actions={
        <RoleGate action="create" resource="mastercourse">
          <Button onClick={() => navigate('/internal/courses/new')}>
            <Plus className="w-4 h-4" /> Add Course
          </Button>
        </RoleGate>
      }
      search={{
        value: search,
        onChange: (v) => { setPage(1); setSearch(v) },
        placeholder: 'Search code or name',
      }}
      filters={
        <div className="flex gap-2">
          <select
            value={field}
            onChange={(e) => { setPage(1); setField(e.target.value) }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg"
          >
            <option value="">All fields</option>
            {FIELDS.map((f) => <option key={f} value={f}>{f}</option>)}
          </select>
          <select
            value={status}
            onChange={(e) => { setPage(1); setStatus(e.target.value as MasterCourseStatus | '') }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg"
          >
            <option value="">All status</option>
            <option value="active">Active</option>
            <option value="archived">Archived</option>
          </select>
        </div>
      }
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/courses/${r.id}`)}
    />
  )
}
