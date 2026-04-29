import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  useTeamMembersFull,
  useCreateTeamMember,
  useDeactivateUser,
  useDepartments,
  type TeamMember,
} from '@/lib/api/people'
import { formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const EMPLOYMENT_STATUS_LABELS: Record<string, string> = {
  active: 'Active',
  inactive: 'Inactive',
  on_leave: 'On Leave',
}

const ROLE_OPTIONS = [
  'ceo', 'finance', 'academic_leader', 'dept_leader',
  'course_creator', 'vernonedu_admin', 'admin', 'facilitator',
] as const

const memberSchema = z.object({
  full_name: z.string().min(2, 'Name required'),
  phone: z.string().min(8, 'Phone required'),
  role: z.enum(ROLE_OPTIONS),
  department_id: z.string().optional(),
  employment_status: z.enum(['active', 'inactive', 'on_leave']),
  is_facilitator: z.boolean(),
})

type MemberForm = z.infer<typeof memberSchema>

export default function TeamMembers() {
  const navigate = useNavigate()
  const [open, setOpen] = useState(false)
  const [confirmTarget, setConfirmTarget] = useState<TeamMember | null>(null)
  const { data = [], isLoading } = useTeamMembersFull()
  const { data: depts = [] } = useDepartments()
  const createMember = useCreateTeamMember()
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
        <button
          onClick={() => setConfirmTarget(row)}
          className="text-xs text-red-500 hover:text-red-700 font-medium"
        >
          Deactivate
        </button>
      ),
    },
  ]

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<MemberForm>({
    resolver: zodResolver(memberSchema),
    defaultValues: { employment_status: 'active', is_facilitator: false },
  })

  const onSubmit = async (form: MemberForm) => {
    try {
      await createMember.mutateAsync(form)
      toast.success('Team member added')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to add member')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Team Members"
        subtitle={isLoading ? 'Loading…' : `${data.length} member${data.length !== 1 ? 's' : ''}`}
        actions={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add Member
          </button>
        }
      />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
        <DataTable
          columns={columns}
          data={data}
          loading={isLoading}
          rowKey={(row) => row.id}
          onRowClick={(row) => navigate(`/internal/team-members/${row.id}`)}
        />
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-50" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">
              Add Team Member
            </Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Full Name
                </label>
                <input
                  {...register('full_name')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.full_name && (
                  <p className="text-xs text-red-500 mt-1">{errors.full_name.message}</p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Phone
                </label>
                <input
                  {...register('phone')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.phone && (
                  <p className="text-xs text-red-500 mt-1">{errors.phone.message}</p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Role
                </label>
                <select
                  {...register('role')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  {ROLE_OPTIONS.map((r) => (
                    <option key={r} value={r}>
                      {r.replace(/_/g, ' ')}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Department
                </label>
                <select
                  {...register('department_id')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  <option value="">None</option>
                  {depts.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Employment Status
                </label>
                <select
                  {...register('employment_status')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                  <option value="on_leave">On Leave</option>
                </select>
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="is_facilitator"
                  {...register('is_facilitator')}
                  className="rounded border-neutral-300 text-brand-600 focus:ring-brand-500"
                />
                <label htmlFor="is_facilitator" className="text-sm text-neutral-700">
                  Is Facilitator
                </label>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => { setOpen(false); reset() }}
                  className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={createMember.isPending}
                  className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50 transition-colors"
                >
                  {createMember.isPending ? 'Adding…' : 'Add Member'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

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
    </div>
  )
}
