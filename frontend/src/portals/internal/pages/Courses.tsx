import { useState } from 'react'
import { Plus } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useCourses, useCreateCourse, type Course } from '@/lib/api/catalog'
import { useDepartments } from '@/lib/api/identity'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'

const courseSchema = z.object({
  name: z.string().min(3, 'Name required'),
  code: z.string().min(2, 'Code required'),
  department_id: z.string().min(1, 'Department required'),
  description: z.string().min(10, 'Description required'),
  duration_days: z.coerce.number().min(1),
  format: z.enum(['online', 'offline', 'hybrid']),
  status: z.enum(['active', 'inactive']),
})

type CourseForm = z.infer<typeof courseSchema>

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
  const [page, setPage] = useState(1)
  const [open, setOpen] = useState(false)
  const LIMIT = 15

  const { data, isLoading } = useCourses({ page, limit: LIMIT })
  const createCourse = useCreateCourse()
  const { data: departments } = useDepartments()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<CourseForm>({
    resolver: zodResolver(courseSchema),
    defaultValues: { format: 'online', status: 'active', duration_days: 2 },
  })

  const onSubmit = async (form: CourseForm) => {
    try {
      await createCourse.mutateAsync(form)
      toast.success('Course created')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to create course')
    }
  }

  return (
    <div className="space-y-5">
      <PageHeader
        title="Courses"
        subtitle="Manage course catalog"
        breadcrumbs={[{ label: 'Courses' }]}
        actions={
          <button
            onClick={() => setOpen(true)}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            New Course
          </button>
        }
      />

      <DataTable
        columns={COLUMNS}
        data={data?.data ?? []}
        loading={isLoading}
        pagination={data ? { page, limit: LIMIT, total: data.total } : undefined}
        onPageChange={setPage}
        rowKey={(row) => row.id}
      />

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-50" />
          <Dialog.Content className="fixed left-1/2 top-1/2 z-50 -translate-x-1/2 -translate-y-1/2 w-full max-w-lg bg-white rounded-xl shadow-xl p-6 max-h-[90vh] overflow-y-auto">
            <Dialog.Title className="text-lg font-semibold text-neutral-900 mb-4">
              Create Course
            </Dialog.Title>

            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700">Course name</label>
                  <input
                    {...register('name')}
                    className="w-full px-3 py-2 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                  {errors.name && <p className="text-xs text-red-600">{errors.name.message}</p>}
                </div>
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700">Code</label>
                  <input
                    {...register('code')}
                    className="w-full px-3 py-2 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 font-mono"
                  />
                  {errors.code && <p className="text-xs text-red-600">{errors.code.message}</p>}
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-neutral-700">Department</label>
                <select
                  {...register('department_id')}
                  className="w-full px-3 py-2 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
                >
                  <option value="">Select department</option>
                  {(departments ?? []).map((d) => (
                    <option key={d.id} value={d.id}>{d.name}</option>
                  ))}
                </select>
                {errors.department_id && <p className="text-xs text-red-600">{errors.department_id.message}</p>}
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-neutral-700">Description</label>
                <textarea
                  {...register('description')}
                  rows={3}
                  className="w-full px-3 py-2 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none"
                />
                {errors.description && <p className="text-xs text-red-600">{errors.description.message}</p>}
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700">Duration (days)</label>
                  <input
                    {...register('duration_days')}
                    type="number"
                    min={1}
                    className="w-full px-3 py-2 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700">Format</label>
                  <select
                    {...register('format')}
                    className="w-full px-3 py-2 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
                  >
                    <option value="online">Online</option>
                    <option value="offline">Offline</option>
                    <option value="hybrid">Hybrid</option>
                  </select>
                </div>
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700">Status</label>
                  <select
                    {...register('status')}
                    className="w-full px-3 py-2 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
                  >
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-2">
                <Dialog.Close className="px-4 py-2 text-sm font-medium text-neutral-700 bg-neutral-100 rounded-lg hover:bg-neutral-200 transition-colors">
                  Cancel
                </Dialog.Close>
                <button
                  type="submit"
                  disabled={createCourse.isPending}
                  className="px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-50 transition-colors"
                >
                  {createCourse.isPending ? 'Creating...' : 'Create Course'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
