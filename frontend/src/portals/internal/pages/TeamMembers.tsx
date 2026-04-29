import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { toast } from 'sonner'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  useTeamMembersFull,
  useDeactivateUser,
  useDepartments,
  type TeamMember,
} from '@/lib/api/people'
import { formatDate } from '@/lib/utils/format'
import { Column } from '@/components/shared/DataTable'
import { cn } from '@/lib/utils/cn'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'

const EMPLOYMENT_STATUS_LABELS: Record<string, string> = {
  active: 'Active',
  inactive: 'Inactive',
  on_leave: 'On Leave',
}

export default function TeamMembers() {
  const navigate = useNavigate()
  const [confirmTarget, setConfirmTarget] = useState<TeamMember | null>(null)
  const { data = [], isLoading } = useTeamMembersFull()
  const { data: depts = [] } = useDepartments()
  const deactivate = useDeactivateUser()

  const deptMap = Object.fromEntries(depts.map((d) => [d.id, d.name]))

  const columns: Column<TeamMember>[] = [
    { header: 'Name', accessor: 'full_name' },
    {
      header: 'Role',
      accessor: 'role',
      cell: (row) => (
        <span className="text-sm capitalize">{row.role.replace(/_/g, ' ')}</span>
      ),
    },
    {
      header: 'Department',
      accessor: 'department_id',
      cell: (row) => (
        <span className="text-sm text-neutral-500">
          {row.department_id ? (deptMap[row.department_id] ?? '—') : '—'}
        </span>
      ),
    },
    {
      header: 'Status',
      accessor: 'employment_status',
      cell: (row) => (
        <span
          className={cn(
            'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
            row.employment_status === 'active'
              ? 'bg-emerald-50 text-emerald-700'
              : row.employment_status === 'on_leave'
              ? 'bg-amber-50 text-amber-700'
              : 'bg-neutral-100 text-neutral-500',
          )}
        >
          {EMPLOYMENT_STATUS_LABELS[row.employment_status]}
        </span>
      ),
    },
    {
      header: 'Facilitator',
      accessor: 'is_facilitator',
      cell: (row) =>
        row.is_facilitator ? (
          <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-brand-50 text-brand-700">
            Yes
          </span>
        ) : (
          <span className="text-neutral-400 text-sm">—</span>
        ),
    },
    {
      header: 'Joined',
      accessor: 'joined_at',
      cell: (row) => formatDate(row.joined_at),
    },
    {
      header: '',
      accessor: 'id',
      cell: (row) => (
        <Button variant="danger" size="sm" onClick={() => setConfirmTarget(row)}>
          Deactivate
        </Button>
      ),
    },
  ]

  return (
    <>
      <ListPageTemplate
        title="Team Members"
        subtitle={isLoading ? 'Loading…' : `${data.length} member${data.length !== 1 ? 's' : ''}`}
        actions={
          <Button variant="primary" onClick={() => navigate('/internal/team-members/new')}>
            <Plus className="w-4 h-4" />
            Add Member
          </Button>
        }
        columns={columns}
        data={data}
        loading={isLoading}
        pagination={{ page: 1, limit: 100, total: data.length }}
        onPageChange={() => {}}
        rowKey={(row) => row.id}
        onRowClick={(row) => navigate(`/internal/team-members/${row.id}`)}
      />

      <ConfirmDialog
        open={confirmTarget !== null}
        title="Deactivate Team Member"
        description={`Are you sure you want to deactivate ${confirmTarget?.full_name ?? ''}? This action cannot be undone.`}
        confirmLabel="Deactivate"
        destructive
        onConfirm={() => {
          if (!confirmTarget) return
          deactivate.mutate(confirmTarget.user_id, {
            onSuccess: () => toast.success('User deactivated'),
            onError: () => toast.error('Failed to deactivate'),
          })
          setConfirmTarget(null)
        }}
        onCancel={() => setConfirmTarget(null)}
      />
    </>
  )
}
