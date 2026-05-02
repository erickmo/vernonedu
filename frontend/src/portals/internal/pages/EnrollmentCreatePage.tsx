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
  createEnrollmentSchema,
  type CreateEnrollmentInput,
} from '@/schemas/enrollment'
import { PAYMENT_METHODS, PAYMENT_METHOD_LABELS } from '@/schemas/coursebatch'
import { useCreateEnrollment } from '@/lib/api/enrollment'
import { useCourseBatches } from '@/lib/api/coursebatch'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Academic', to: '/internal/academic' },
  { label: 'Enrollments', to: '/internal/enrollments' },
  { label: 'New Enrollment' },
]

function todayISO(): string {
  return new Date().toISOString().slice(0, 10)
}

export default function EnrollmentCreatePage() {
  const navigate = useNavigate()
  const create = useCreateEnrollment()
  const { data: batchesPage } = useCourseBatches({ limit: 100 })
  const batches = batchesPage?.data ?? []

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateEnrollmentInput>({
    resolver: zodResolver(createEnrollmentSchema),
    defaultValues: {
      student_id: '',
      course_batch_id: '',
      enrollment_date: todayISO(),
      payment_method: 'upfront',
      voucher_code: '',
    },
  })

  async function onSubmit(values: CreateEnrollmentInput) {
    try {
      const result: any = await create.mutateAsync(values)
      toast.success('Enrollment created')
      const newId = result?.id ?? result?.data?.id
      navigate(newId ? `/internal/enrollments/${newId}` : '/internal/enrollments')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create enrollment')
    }
  }

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="New Enrollment"
      subtitle="Enroll a student into a course batch"
    >
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4"
      >
        <FormField label="Student ID (UUID)" required error={errors.student_id?.message}>
          <Input {...register('student_id')} placeholder="00000000-0000-0000-0000-000000000000" />
        </FormField>

        <FormField label="Course Batch" required error={errors.course_batch_id?.message}>
          <Select {...register('course_batch_id')}>
            <option value="">— Select batch —</option>
            {batches.map((b) => (
              <option key={b.id} value={b.id}>
                {b.code ? `[${b.code}] ` : ''}{b.name}
              </option>
            ))}
          </Select>
        </FormField>

        <FormField label="Enrollment Date" required error={errors.enrollment_date?.message}>
          <Input type="date" {...register('enrollment_date')} />
        </FormField>

        <FormField label="Payment Method" required error={errors.payment_method?.message}>
          <Select {...register('payment_method')}>
            {PAYMENT_METHODS.map((m) => (
              <option key={m} value={m}>
                {PAYMENT_METHOD_LABELS[m]}
              </option>
            ))}
          </Select>
        </FormField>

        <FormField label="Voucher Code" error={errors.voucher_code?.message}>
          <Input {...register('voucher_code')} placeholder="optional" />
        </FormField>

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/enrollments')}>
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
