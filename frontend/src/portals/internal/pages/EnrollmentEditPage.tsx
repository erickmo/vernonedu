import { useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import {
  updateEnrollmentSchema,
  type UpdateEnrollmentInput,
} from '@/schemas/enrollment'
import {
  ENROLLMENT_STATUSES,
  ENROLLMENT_PAYMENT_STATUSES,
} from '@/types/enrollment'
import {
  useEnrollment,
  useUpdateEnrollmentStatus,
  useUpdateEnrollmentPaymentStatus,
} from '@/lib/api/enrollment'

// Edit page — backend exposes only status + payment_status updates
// (see api/internal/delivery/http/enrollment_handler.go). Both are sent
// in sequence on submit; either may be skipped if unchanged.
export default function EnrollmentEditPage() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: enrollment, isLoading } = useEnrollment(id)
  const updateStatus = useUpdateEnrollmentStatus()
  const updatePayment = useUpdateEnrollmentPaymentStatus()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateEnrollmentInput>({
    resolver: zodResolver(updateEnrollmentSchema),
    defaultValues: { status: 'pending', payment_status: 'pending' },
  })

  useEffect(() => {
    if (enrollment) {
      reset({
        status: enrollment.status,
        payment_status: enrollment.payment_status,
      })
    }
  }, [enrollment, reset])

  async function onSubmit(values: UpdateEnrollmentInput) {
    try {
      const tasks: Promise<unknown>[] = []
      if (!enrollment || values.status !== enrollment.status) {
        tasks.push(updateStatus.mutateAsync({ id, status: values.status }))
      }
      if (!enrollment || values.payment_status !== enrollment.payment_status) {
        tasks.push(updatePayment.mutateAsync({ id, payment_status: values.payment_status }))
      }
      await Promise.all(tasks)
      toast.success('Enrollment updated')
      navigate(`/internal/enrollments/${id}`)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update enrollment')
    }
  }

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Academic', to: '/internal/academic' },
    { label: 'Enrollments', to: '/internal/enrollments' },
    { label: `Enrollment #${id.slice(0, 8)}`, to: `/internal/enrollments/${id}` },
    { label: 'Edit' },
  ]

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-24">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title={`Edit Enrollment #${id.slice(0, 8)}`}
      subtitle="Update status and payment status"
    >
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4"
      >
        <FormField label="Status" required error={errors.status?.message}>
          <Select {...register('status')}>
            {ENROLLMENT_STATUSES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </Select>
        </FormField>

        <FormField label="Payment Status" required error={errors.payment_status?.message}>
          <Select {...register('payment_status')}>
            {ENROLLMENT_PAYMENT_STATUSES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </Select>
        </FormField>

        <div className="flex gap-2 pt-2">
          <Button
            type="button"
            variant="secondary"
            onClick={() => navigate(`/internal/enrollments/${id}`)}
          >
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
