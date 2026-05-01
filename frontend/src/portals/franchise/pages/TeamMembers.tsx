import { useState, useMemo } from 'react'
import { useTeamMembers, type TeamMember } from '@/lib/api/team_member'
import { formatDate } from '@/lib/utils/format'
import { Column } from '@/components/shared/DataTable'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'
import ListPageTemplate from '@/components/templates/ListPageTemplate'

const TEAM_TABS: SubNavItem[] = [
  { label: 'All', value: '' },
  { label: 'Facilitators', value: 'facilitator' },
  { label: 'Staff', value: 'staff' },
]

const COLUMNS: Column<TeamMember>[] = [
  {
    header: '',
    accessor: 'full_name',
    className: 'w-10',
    cell: (row) => (
      <div className="w-8 h-8 rounded-full bg-violet-100 flex items-center justify-center text-xs font-bold text-violet-700">
        {row.full_name.charAt(0).toUpperCase()}
      </div>
    ),
  },
  { header: 'Name', accessor: 'full_name' },
  { header: 'Phone', accessor: 'phone' },
  {
    header: 'Role',
    accessor: 'is_facilitator',
    cell: (row) => (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${row.is_facilitator ? 'bg-violet-100 text-violet-700' : 'bg-neutral-100 text-neutral-600'}`}>
        {row.is_facilitator ? 'Facilitator' : 'Staff'}
      </span>
    ),
  },
  {
    header: 'Status',
    accessor: 'employment_status',
    cell: (row) => {
      const colors: Record<string, string> = {
        active: 'bg-emerald-100 text-emerald-700',
        inactive: 'bg-neutral-100 text-neutral-500',
        on_leave: 'bg-amber-100 text-amber-700',
      }
      return (
        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${colors[row.employment_status] ?? 'bg-neutral-100 text-neutral-700'}`}>
          {row.employment_status.replace('_', ' ')}
        </span>
      )
    },
  },
  {
    header: 'Joined',
    accessor: 'joined_at',
    cell: (row) => <span className="text-xs text-neutral-500">{formatDate(row.joined_at)}</span>,
  },
]

export default function TeamMembers() {
  const [activeTab, setActiveTab] = useState('')

  const handleTabChange = useMemo(() => (v: string) => setActiveTab(v), [])

  useSubNav(TEAM_TABS, activeTab, handleTabChange)

  const { data: members = [], isLoading } = useTeamMembers()

  const filtered =
    activeTab === 'facilitator'
      ? members.filter((m) => m.is_facilitator)
      : activeTab === 'staff'
        ? members.filter((m) => !m.is_facilitator)
        : members

  return (
    <ListPageTemplate
      title="Team Members"
      subtitle="VernonEdu staff and facilitators"
      columns={COLUMNS}
      data={filtered}
      loading={isLoading}
      pagination={{ page: 1, limit: 100, total: filtered.length }}
      onPageChange={() => {}}
      rowKey={(row) => row.id}
    />
  )
}
