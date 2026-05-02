import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import { createInvestmentSchema, type CreateInvestmentInput } from '@/schemas/investment'
import { useCreateInvestment } from '@/lib/api/investment'
import { INVESTMENT_STATUSES, INVESTMENT_CATEGORIES } from '@/types/investment'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Investments', to: '/internal/investments' },
  { label: 'New Plan' },
]

export default function InvestmentCreatePage() {
  const navigate = useNavigate()
  const create = useCreateInvestment()

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<CreateInvestmentInput>({
    resolver: zodResolver(createInvestmentSchema),
    defaultValues: {
      title: '', category: 'Equipment', proposed_by: '',
      amount: 0, expected_roi: 0, status: 'proposed', notes: '',
    },
  })

  async function onSubmit(values: CreateInvestmentInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Investment plan created')
      navigate('/internal/investments')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="New Investment Plan" subtitle="Propose a new investment">
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
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/investments')}>Cancel</Button>
          <Button type="submit" loading={isSubmitting}>Save</Button>
        </div>
      </form>
    </StandardPageLayout>
  )
}
