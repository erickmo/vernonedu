import { useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { updateInvestmentSchema, type UpdateInvestmentInput } from '@/schemas/investment'
import { useInvestment, useUpdateInvestment } from '@/lib/api/investment'
import { INVESTMENT_STATUSES, INVESTMENT_CATEGORIES } from '@/types/investment'

export default function InvestmentEditPage() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = useInvestment(id)
  const update = useUpdateInvestment(id)

  const form = useForm<UpdateInvestmentInput>({
    resolver: zodResolver(updateInvestmentSchema),
    defaultValues: { title: '', category: '', proposed_by: '', amount: 0, expected_roi: 0, status: 'proposed', notes: '' },
  })
  const { register, handleSubmit, reset, formState: { errors, isSubmitting } } = form

  useEffect(() => {
    if (data) {
      reset({
        title: data.title, category: data.category, proposed_by: data.proposed_by,
        amount: data.amount, expected_roi: data.expected_roi, status: data.status,
        notes: data.notes ?? '',
      })
    }
  }, [data, reset])

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Investments', to: '/internal/investments' },
    { label: data.title, to: `/internal/investments/${id}` },
    { label: 'Edit' },
  ]

  async function onSubmit(values: UpdateInvestmentInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Investment plan updated')
      navigate(`/internal/investments/${id}`)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="Edit Investment Plan">
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Title" required error={errors.title?.message}>
          <Input {...register('title')} />
        </FormField>
        <FormField label="Category" required error={errors.category?.message}>
          <Select {...register('category')}>
            {INVESTMENT_CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
          </Select>
        </FormField>
        <FormField label="Proposed By" required error={errors.proposed_by?.message}>
          <Input {...register('proposed_by')} />
        </FormField>
        <div className="grid grid-cols-2 gap-3">
          <FormField label="Amount (IDR)" required error={errors.amount?.message}>
            <Input type="number" step="1" {...register('amount', { valueAsNumber: true })} />
          </FormField>
          <FormField label="Expected ROI (%)" required error={errors.expected_roi?.message}>
            <Input type="number" step="any" {...register('expected_roi', { valueAsNumber: true })} />
          </FormField>
        </div>
        <FormField label="Status" error={errors.status?.message}>
          <Select {...register('status')}>
            {INVESTMENT_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
          </Select>
        </FormField>
        <FormField label="Notes" error={errors.notes?.message}>
          <Textarea {...register('notes')} rows={4} />
        </FormField>
        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate(`/internal/investments/${id}`)}>Cancel</Button>
          <Button type="submit" loading={isSubmitting}>Save</Button>
        </div>
      </form>
    </StandardPageLayout>
  )
}
