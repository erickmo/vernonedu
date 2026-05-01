import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useCourses, type Course } from '@/lib/api/catalog'
import StatusBadge from '@/components/shared/StatusBadge'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import CreateCourseModal from '@/portals/internal/components/CreateCourseModal'

const LIMIT = 15

const COLUMNS: Column<Course>[] = [
  { header: 'Code', accessor: 'code', className: 'font-mono text-xs w-24' },
  { header: 'Name', accessor: 'name' },
  { header: 'Format', accessor: 'format', cell: (row) => <span className="capitalize">{row.format}</span> },
  { header: 'Duration', accessor: 'duration_days', cell: (row) => `${row.duration_days} days` },
  {
    header: 'Status',
    accessor: 'status',
    cell: (row) => <StatusBadge status={row.status} />,
  },
]

export default function Courses() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [open, setOpen] = useState(false)

  const { data, isLoading } = useCourses({ page, limit: LIMIT })

  return (
    <>
      <ListPageTemplate
        title="Courses"
        subtitle="Manage course catalog"
        actions={<Button onClick={() => setOpen(true)}><Plus className="w-4 h-4" />Add Course</Button>}
        columns={COLUMNS}
        data={data?.data ?? []}
        loading={isLoading}
        pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
        onPageChange={setPage}
        rowKey={(row) => row.id}
        onRowClick={(row) => navigate(`/internal/courses/${row.id}`)}
      />
      <CreateCourseModal open={open} onOpenChange={setOpen} />
    </>
  )
}
