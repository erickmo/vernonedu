import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useCreateStudent } from '@/lib/api/identity'
import FormModal from '@/components/shared/FormModal'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'

const schema = z.object({
  name: z.string().min(2, 'Name required'),
  email: z.string().email('Valid email required'),
  phone: z.string().min(8, 'Phone required'),
  source: z.enum(['b2c', 'b2b']),
})

type FormData = z.infer<typeof schema>

interface CreateStudentModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

export default function CreateStudentModal({ open, onOpenChange }: CreateStudentModalProps) {
  const createStudent = useCreateStudent()
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { source: 'b2c' },
  })

  const onSubmit = async (data: FormData) => {
    try {
      await createStudent.mutateAsync(data)
      toast.success('Student created')
      onOpenChange(false)
      reset()
    } catch {
      toast.error('Failed to create student')
    }
  }

  return (
    <FormModal
      open={open}
      onOpenChange={onOpenChange}
      title="Add Student"
      onSubmit={handleSubmit(onSubmit)}
      loading={createStudent.isPending}
      submitLabel="Create Student"
    >
      <FormField label="Name" error={errors.name?.message} required>
        <Input {...register('name')} placeholder="Full name" error={!!errors.name} />
      </FormField>
      <FormField label="Email" error={errors.email?.message} required>
        <Input
          {...register('email')}
          type="email"
          placeholder="email@example.com"
          error={!!errors.email}
        />
      </FormField>
      <FormField label="Phone" error={errors.phone?.message} required>
        <Input {...register('phone')} type="tel" placeholder="+62..." error={!!errors.phone} />
      </FormField>
      <FormField label="Source" error={errors.source?.message} required>
        <Select {...register('source')} error={!!errors.source}>
          <option value="b2c">B2C</option>
          <option value="b2b">B2B</option>
        </Select>
      </FormField>
    </FormModal>
  )
}
