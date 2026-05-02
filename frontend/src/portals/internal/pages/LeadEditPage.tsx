import { useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import { updateLeadSchema, type UpdateLeadInput } from '@/schemas/lead'
import { LEAD_SOURCES, LEAD_STATUSES } from '@/types/lead'
import { useLead, useUpdateLead } from '@/lib/api/lead'

export default function LeadEditPage() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = useLead(id)
  const update = useUpdateLead(id)

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateLeadInput>({
    resolver: zodResolver(updateLeadSchema),
  })

  useEffect(() => {
    if (data) {
      reset({
        name: data.name,
        email: data.email,
        phone: data.phone,
        interest: data.interest,
        source: data.source,
        notes: data.notes,
        status: data.status,
        pic_id: data.pic_id ?? undefined,
      })
    }
  }, [data, reset])

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Leads', to: '/internal/leads' },
    { label: data.name, to: `/internal/leads/${id}` },
    { label: 'Edit' },
  ]

  async function onSubmit(values: UpdateLeadInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Lead updated')
      navigate(`/internal/leads/${id}`)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update lead')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="Edit Lead" subtitle={data.name}>
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4"
      >
        <FormField label="Name" required error={errors.name?.message}>
          <Input {...register('name')} />
        </FormField>

        <div className="grid grid-cols-2 gap-4">
          <FormField label="Email" error={errors.email?.message}>
            <Input {...register('email')} />
          </FormField>
          <FormField label="Phone" error={errors.phone?.message}>
            <Input {...register('phone')} />
          </FormField>
        </div>

        <FormField label="Interest" error={errors.interest?.message}>
          <Input {...register('interest')} />
        </FormField>

        <div className="grid grid-cols-2 gap-4">
          <FormField label="Source" error={errors.source?.message}>
            <Select {...register('source')}>
              <option value="">— Select —</option>
              {LEAD_SOURCES.map((s) => <option key={s} value={s}>{s}</option>)}
            </Select>
          </FormField>
          <FormField label="Status" required error={errors.status?.message}>
            <Select {...register('status')}>
              {LEAD_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
            </Select>
          </FormField>
        </div>

        <FormField label="Notes" error={errors.notes?.message}>
          <Textarea {...register('notes')} rows={4} />
        </FormField>

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate(`/internal/leads/${id}`)}>
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
