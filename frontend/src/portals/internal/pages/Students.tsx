import { useState } from 'react'
import { Plus, Users2 } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useStudents, useCreateStudent, type Student } from '@/lib/api/identity'
import { formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'

const studentSchema = z.object({
  name: z.string().min(2, 'Name required'),
  email: z.string().email('Valid email required'),
  phone: z.string().min(8, 'Phone required'),
  source: z.enum(['b2c', 'b2b']),
})

type StudentForm = z.infer<typeof studentSchema>

const COLUMNS: Column<Student>[] = [
  { header: 'Name', accessor: 'name' },
  { header: 'Email', accessor: 'email' },
  { header: 'Phone', accessor: 'phone' },
  {
    header: 'Source',
    accessor: 'source',
    cell: (row) => (
      <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
        row.source === 'b2b' ? 'bg-violet-100 text-violet-700' : 'bg-blue-100 text-blue-700'
      }`}>
        {row.source.toUpperCase()}
      </span>
    ),
  },
  {
    header: 'Joined',
    accessor: 'created_at',
    cell: (row) => formatDate(row.created_at),
  },
]

export default function Students() {
  const [page, setPage] = useState(1)
  const [sourceFilter, setSourceFilter] = useState<'' | 'b2c' | 'b2b'>('')
  const [open, setOpen] = useState(false)
  const LIMIT = 15

  const { data, isLoading } = useStudents({
    source: sourceFilter || undefined,
    page,
    limit: LIMIT,
  })

  const createStudent = useCreateStudent()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<StudentForm>({
    resolver: zodResolver(studentSchema),
    defaultValues: { source: 'b2c' },
  })

  const onSubmit = async (form: StudentForm) => {
    try {
      await createStudent.mutateAsync(form)
      toast.success('Student created')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to create student')
    }
  }

  return (
    <div className="space-y-5">
      <PageHeader
        title="Students"
        subtitle="Manage student records"
        breadcrumbs={[{ label: 'Students' }]}
        actions={
          <button
            onClick={() => setOpen(true)}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add Student
          </button>
        }
      />

      <div className="flex items-center gap-3">
        <div className="flex items-center gap-1 p-1 bg-neutral-100 rounded-lg">
          {([['', 'All'], ['b2c', 'B2C'], ['b2b', 'B2B']] as const).map(([val, label]) => (
            <button
              key={val}
              onClick={() => { setSourceFilter(val); setPage(1) }}
              className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
                sourceFilter === val
                  ? 'bg-white text-neutral-900 shadow-sm'
                  : 'text-neutral-500 hover:text-neutral-700'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
        <span className="text-sm text-neutral-500">{data?.total ?? 0} students</span>
      </div>

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
          <Dialog.Content className="fixed left-1/2 top-1/2 z-50 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-white rounded-xl shadow-xl p-6">
            <Dialog.Title className="text-lg font-semibold text-neutral-900 mb-4 flex items-center gap-2">
              <Users2 className="w-5 h-5 text-brand-600" />
              Add Student
            </Dialog.Title>

            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-neutral-700">Full name</label>
                <input
                  {...register('name')}
                  className="w-full px-3 py-2 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.name && <p className="text-xs text-red-600">{errors.name.message}</p>}
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-neutral-700">Email</label>
                <input
                  {...register('email')}
                  type="email"
                  className="w-full px-3 py-2 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.email && <p className="text-xs text-red-600">{errors.email.message}</p>}
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-neutral-700">Phone</label>
                <input
                  {...register('phone')}
                  type="tel"
                  className="w-full px-3 py-2 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.phone && <p className="text-xs text-red-600">{errors.phone.message}</p>}
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-neutral-700">Source</label>
                <select
                  {...register('source')}
                  className="w-full px-3 py-2 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
                >
                  <option value="b2c">B2C (Individual)</option>
                  <option value="b2b">B2B (Corporate)</option>
                </select>
              </div>

              <div className="flex justify-end gap-3 pt-2">
                <Dialog.Close className="px-4 py-2 text-sm font-medium text-neutral-700 bg-neutral-100 rounded-lg hover:bg-neutral-200 transition-colors">
                  Cancel
                </Dialog.Close>
                <button
                  type="submit"
                  disabled={createStudent.isPending}
                  className="px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-50 transition-colors"
                >
                  {createStudent.isPending ? 'Adding...' : 'Add Student'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
