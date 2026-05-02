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
import { createLeadSchema, type CreateLeadInput } from '@/schemas/lead'
import { LEAD_SOURCES } from '@/types/lead'
import { useCreateLead } from '@/lib/api/lead'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Operations', to: '/internal/operations' },
  { label: 'Leads', to: '/internal/leads' },
  { label: 'New Lead' },
]

export default function LeadCreatePage() {
  const navigate = useNavigate()
  const create = useCreateLead()

  const {
    register, handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateLeadInput>({
    resolver: zodResolver(createLeadSchema),
    defaultValues: {
      name: '',
      email: '',
      phone: '',
      interest: '',
      source: '',
      notes: '',
    },
  })

  async function onSubmit(values: CreateLeadInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Lead created')
      navigate('/internal/leads')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create lead')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="Add Lead" subtitle="Create a new lead">
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4"
      >
        <FormField label="Name" required error={errors.name?.message}>
          <Input {...register('name')} placeholder="Full name" />
        </FormField>

        <div className="grid grid-cols-2 gap-4">
          <FormField label="Email" error={errors.email?.message}>
            <Input {...register('email')} placeholder="email@example.com" />
          </FormField>
          <FormField label="Phone" error={errors.phone?.message}>
            <Input {...register('phone')} placeholder="08xxxx" />
          </FormField>
        </div>

        <FormField label="Interest" error={errors.interest?.message}>
          <Input {...register('interest')} placeholder="Course or topic" />
        </FormField>

        <FormField label="Source" error={errors.source?.message}>
          <Select {...register('source')}>
            <option value="">— Select —</option>
            {LEAD_SOURCES.map((s) => <option key={s} value={s}>{s}</option>)}
          </Select>
        </FormField>

        <FormField label="Notes" error={errors.notes?.message}>
          <Textarea {...register('notes')} rows={4} />
        </FormField>

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/leads')}>
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
