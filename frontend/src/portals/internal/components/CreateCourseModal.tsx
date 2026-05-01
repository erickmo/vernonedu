import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useCreateCourse } from '@/lib/api/catalog'
import { useDepartments } from '@/lib/api/identity'
import FormModal from '@/components/shared/FormModal'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Textarea from '@/components/ui/Textarea'

const schema = z.object({
  name: z.string().min(3, 'Name required'),
  code: z.string().min(2, 'Code required'),
  department_id: z.string().min(1, 'Department required'),
  description: z.string().min(10, 'Description required'),
  duration_days: z.coerce.number().min(1),
  format: z.enum(['online', 'offline', 'hybrid']),
  status: z.enum(['active', 'inactive']),
})

type FormData = z.infer<typeof schema>

interface CreateCourseModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

export default function CreateCourseModal({ open, onOpenChange }: CreateCourseModalProps) {
  const createCourse = useCreateCourse()
  const { data: departments } = useDepartments()
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { format: 'online', status: 'active' },
  })

  const onSubmit = async (data: FormData) => {
    try {
      await createCourse.mutateAsync(data)
      toast.success('Course created')
      onOpenChange(false)
      reset()
    } catch {
      toast.error('Failed to create course')
    }
  }

  return (
    <FormModal
      open={open}
      onOpenChange={onOpenChange}
      title="Add Course"
      onSubmit={handleSubmit(onSubmit)}
      loading={createCourse.isPending}
      submitLabel="Create Course"
    >
      <FormField label="Name" error={errors.name?.message} required>
        <Input {...register('name')} placeholder="Course name" error={!!errors.name} />
      </FormField>
      <FormField label="Code" error={errors.code?.message} required>
        <Input {...register('code')} className="font-mono uppercase" placeholder="e.g. CS101" error={!!errors.code} />
      </FormField>
      <FormField label="Department" error={errors.department_id?.message} required>
        <Select {...register('department_id')} error={!!errors.department_id}>
          <option value="">Select department…</option>
          {(departments ?? []).map((d) => (
            <option key={d.id} value={d.id}>{d.name}</option>
          ))}
        </Select>
      </FormField>
      <FormField label="Description" error={errors.description?.message} required>
        <Textarea {...register('description')} placeholder="Course description" rows={3} error={!!errors.description} />
      </FormField>
      <FormField label="Duration (days)" error={errors.duration_days?.message} required>
        <Input {...register('duration_days')} type="number" min={1} placeholder="30" error={!!errors.duration_days} />
      </FormField>
      <FormField label="Format" error={errors.format?.message}>
        <Select {...register('format')} error={!!errors.format}>
          <option value="online">Online</option>
          <option value="offline">Offline</option>
          <option value="hybrid">Hybrid</option>
        </Select>
      </FormField>
      <FormField label="Status" error={errors.status?.message}>
        <Select {...register('status')} error={!!errors.status}>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </Select>
      </FormField>
    </FormModal>
  )
}
