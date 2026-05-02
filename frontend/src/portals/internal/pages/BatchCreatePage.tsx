import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import {
  createCourseBatchSchema,
  PAYMENT_METHODS,
  PAYMENT_METHOD_LABELS,
  type CreateCourseBatchInput,
} from '@/schemas/coursebatch'
import { useCreateCourseBatch } from '@/lib/api/coursebatch'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Operations', to: '/internal/operations' },
  { label: 'Batches', to: '/internal/batches' },
  { label: 'New Batch' },
]

export default function BatchCreatePage() {
  const navigate = useNavigate()
  const create = useCreateCourseBatch()

  const {
    register, handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateCourseBatchInput>({
    resolver: zodResolver(createCourseBatchSchema),
    defaultValues: {
      course_id: '',
      code: '',
      name: '',
      start_date: '',
      end_date: '',
      min_participants: 0,
      max_participants: 20,
      website_visible: true,
      is_active: true,
      price: 0,
      payment_method: 'upfront',
    },
  })

  async function onSubmit(values: CreateCourseBatchInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Batch created')
      navigate('/internal/batches')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create batch')
    }
  }

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Add Batch"
      subtitle="Create a new course batch (kelas)"
    >
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Course ID (UUID)" required error={errors.course_id?.message}>
          <Input {...register('course_id')} placeholder="00000000-0000-0000-0000-000000000000" />
        </FormField>

        <FormField label="Batch Code" error={errors.code?.message}>
          <Input {...register('code')} placeholder="B-2026-01" />
        </FormField>

        <FormField label="Batch Name" required error={errors.name?.message}>
          <Input {...register('name')} placeholder="Web Dev — Jan 2026" />
        </FormField>

        <div className="grid grid-cols-2 gap-3">
          <FormField label="Start Date" required error={errors.start_date?.message}>
            <Input type="date" {...register('start_date')} />
          </FormField>
          <FormField label="End Date" required error={errors.end_date?.message}>
            <Input type="date" {...register('end_date')} />
          </FormField>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <FormField label="Min Participants" error={errors.min_participants?.message}>
            <Input type="number" {...register('min_participants', { valueAsNumber: true })} />
          </FormField>
          <FormField label="Max Participants" required error={errors.max_participants?.message}>
            <Input type="number" {...register('max_participants', { valueAsNumber: true })} />
          </FormField>
        </div>

        <FormField label="Price (IDR)" error={errors.price?.message}>
          <Input type="number" {...register('price', { valueAsNumber: true })} />
        </FormField>

        <FormField label="Payment Method" required error={errors.payment_method?.message}>
          <Select {...register('payment_method')}>
            {PAYMENT_METHODS.map((pm) => (
              <option key={pm} value={pm}>{PAYMENT_METHOD_LABELS[pm]}</option>
            ))}
          </Select>
        </FormField>

        <div className="flex items-center gap-4 text-sm">
          <label className="flex items-center gap-2">
            <input type="checkbox" {...register('website_visible')} />
            Visible on website
          </label>
          <label className="flex items-center gap-2">
            <input type="checkbox" {...register('is_active')} />
            Active
          </label>
        </div>

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/batches')}>
            Cancel
          </Button>
          <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
            Save
          </Button>
        </div>
      </form>
    </StandardPageLayout>
  )
}
