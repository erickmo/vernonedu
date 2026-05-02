import { useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import {
  updateCourseBatchSchema,
  PAYMENT_METHODS,
  PAYMENT_METHOD_LABELS,
  type UpdateCourseBatchInput,
} from '@/schemas/coursebatch'
import { useCourseBatch, useUpdateCourseBatch } from '@/lib/api/coursebatch'

function toDateInput(s: string | undefined): string {
  if (!s) return ''
  // accept either ISO or already YYYY-MM-DD
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s
  try {
    return new Date(s).toISOString().slice(0, 10)
  } catch {
    return ''
  }
}

export default function BatchEditPage() {
  const navigate = useNavigate()
  const { id = '' } = useParams<{ id: string }>()
  const { data, isLoading } = useCourseBatch(id)
  const update = useUpdateCourseBatch(id)

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateCourseBatchInput>({
    resolver: zodResolver(updateCourseBatchSchema),
  })

  useEffect(() => {
    if (data) {
      reset({
        code: data.code ?? '',
        name: data.name,
        start_date: toDateInput(data.start_date),
        end_date: toDateInput(data.end_date),
        min_participants: data.min_participants ?? 0,
        max_participants: data.max_participants,
        website_visible: data.website_visible ?? true,
        is_active: data.is_active ?? true,
        price: data.price ?? 0,
        payment_method: (data.payment_method as any) ?? 'upfront',
      })
    }
  }, [data, reset])

  async function onSubmit(values: UpdateCourseBatchInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Batch updated')
      navigate(`/internal/batches/${id}`)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update batch')
    }
  }

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Batches', to: '/internal/batches' },
    { label: data.code || data.name, to: `/internal/batches/${id}` },
    { label: 'Edit' },
  ]

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Edit Batch"
      subtitle={data.code || data.name}
    >
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Batch Code" error={errors.code?.message}>
          <Input {...register('code')} />
        </FormField>

        <FormField label="Batch Name" required error={errors.name?.message}>
          <Input {...register('name')} />
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

        <div className="flex gap-2 pt-2 border-t border-neutral-100">
          <Button type="button" variant="secondary" onClick={() => navigate(`/internal/batches/${id}`)}>
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
