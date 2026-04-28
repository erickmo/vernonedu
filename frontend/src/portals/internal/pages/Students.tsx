import { useState } from 'react'
import { Plus, Search } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useStudents, useCreateStudent, type Student } from '@/lib/api/identity'
import { formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const studentSchema = z.object({
  name: z.string().min(2, 'Name required'),
  email: z.string().email('Valid email required'),
  phone: z.string().min(8, 'Phone required'),
  source: z.enum(['b2c', 'b2b']),
})

type StudentForm = z.infer<typeof studentSchema>

const SOURCE_FILTERS = [
  { label: 'All', value: '' },
  { label: 'B2C', value: 'b2c' },
  { label: 'B2B', value: 'b2b' },
] as const

const LIMIT = 15

export default function Students() {
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

  const COLUMNS: Column<Student>[] = [
    {
      header: '',
      accessor: 'name',
      className: 'w-10',
      cell: (row) => (
        <div className="w-8 h-8 rounded-full bg-brand-50 flex items-center justify-center text-xs font-bold text-brand-700">
          {row.name.charAt(0).toUpperCase()}
        </div>
      ),
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
            row.source === 'b2b'
              ? 'bg-violet-50 text-violet-700'
              : 'bg-brand-50 text-brand-700',
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

  return (
    <div className="space-y-5">
      <PageHeader
        title="Students"
        subtitle="Manage registered students"
        actions={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors shadow-sm"
          >
            <Plus className="w-4 h-4" />
            Add Student
          </button>
        }
      />

      {/* Filter bar */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            placeholder="Search by name or email…"
            className="w-full pl-9 pr-4 py-2 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
          />
        </div>
        <div className="flex items-center gap-1 bg-white border border-neutral-200 rounded-lg p-1">
          {SOURCE_FILTERS.map((f) => (
            <button
              key={f.value}
              onClick={() => { setSourceFilter(f.value as typeof sourceFilter); setPage(1) }}
              className={cn(
                'px-3 py-1 text-sm font-medium rounded-md transition-colors',
                sourceFilter === f.value
                  ? 'bg-brand-600 text-white shadow-sm'
                  : 'text-neutral-600 hover:bg-neutral-50',
              )}
            >
              {f.label}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={COLUMNS}
          data={data?.data ?? []}
          loading={isLoading}
          pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
          onPageChange={setPage}
          rowKey={(row) => row.id}
        />
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 animate-in fade-in-0" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-2xl shadow-xl p-6 animate-in fade-in-0 zoom-in-95">
            <Dialog.Title className="text-lg font-bold text-neutral-900 mb-5">Add Student</Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              {(['name', 'email', 'phone'] as const).map((field) => (
                <div key={field} className="space-y-1.5">
                  <label className="text-sm font-medium text-neutral-700 capitalize">{field}</label>
                  <input
                    {...register(field)}
                    type={field === 'email' ? 'email' : field === 'phone' ? 'tel' : 'text'}
                    className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                  {errors[field] && (
                    <p className="text-xs text-red-600">{errors[field]?.message}</p>
                  )}
                </div>
              ))}

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-neutral-700">Source</label>
                <select
                  {...register('source')}
                  className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
                >
                  <option value="b2c">B2C</option>
                  <option value="b2b">B2B</option>
                </select>
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <Dialog.Close asChild>
                  <button
                    type="button"
                    className="px-4 py-2 text-sm font-medium text-neutral-600 border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors"
                  >
                    Cancel
                  </button>
                </Dialog.Close>
                <button
                  type="submit"
                  disabled={createStudent.isPending}
                  className="px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-50 transition-colors"
                >
                  {createStudent.isPending ? 'Creating…' : 'Create Student'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
