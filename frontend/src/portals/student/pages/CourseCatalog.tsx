import { useState } from 'react'
import { Monitor, MapPin, Layers } from 'lucide-react'
import { useCourses, type Course } from '@/lib/api/catalog'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'

const FORMAT_ICON = {
  online: Monitor,
  offline: MapPin,
  hybrid: Layers,
} as const

const FORMAT_COLOR = {
  online: 'bg-brand-50 text-brand-700',
  offline: 'bg-amber-50 text-amber-700',
  hybrid: 'bg-violet-50 text-violet-700',
} as const

const COLUMNS: Column<Course>[] = [
  { header: 'Code', accessor: 'code', cell: (row) => <span className="font-mono text-xs text-neutral-500">{row.code}</span> },
  { header: 'Name', accessor: 'name' },
  { header: 'Description', accessor: 'description', cell: (row) => <span className="text-xs text-neutral-500 line-clamp-1">{row.description}</span> },
  {
    header: 'Format',
    accessor: 'format',
    cell: (row) => {
      const Icon = FORMAT_ICON[row.format] ?? Monitor
      const fmtColor = FORMAT_COLOR[row.format] ?? 'bg-neutral-100 text-neutral-600'
      return (
        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${fmtColor}`}>
          <Icon className="w-3 h-3" />
          {row.format}
        </span>
      )
    },
  },
  {
    header: 'Duration',
    accessor: 'duration_days',
    cell: (row) => <span className="text-xs font-mono text-neutral-500">{row.duration_days}d</span>,
  },
]

export default function CourseCatalog() {
  const [search, setSearch] = useState('')

  const { data: coursesData, isLoading } = useCourses({
    search: search || undefined,
    status: 'active',
  })

  const courses = coursesData?.data ?? []

  return (
    <ListPageTemplate
      title="Course Catalog"
      subtitle="Browse available training programs"
      search={{
        value: search,
        onChange: setSearch,
        placeholder: 'Search courses…',
      }}
      columns={COLUMNS}
      data={courses}
      loading={isLoading}
      pagination={{ page: 1, limit: 100, total: courses.length }}
      onPageChange={() => {}}
      rowKey={(row) => row.id}
    />
  )
}
