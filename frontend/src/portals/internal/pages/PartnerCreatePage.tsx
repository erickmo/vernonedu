import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import { createPartnerSchema, type CreatePartnerInput } from '@/schemas/partner'
import { PARTNER_STATUSES, PARTNER_TYPES } from '@/types/partner'
import { useCreatePartner } from '@/lib/api/partner'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Operations', to: '/internal/operations' },
  { label: 'Partners', to: '/internal/partners' },
  { label: 'New Partner' },
]

export default function PartnerCreatePage() {
  const navigate = useNavigate()
  const create = useCreatePartner()

  const {
    register, handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreatePartnerInput>({
    resolver: zodResolver(createPartnerSchema),
    defaultValues: {
      name: '', type: 'corporate', status: 'prospect',
      contact_name: '', contact_email: '', contact_phone: '',
      address: '', notes: '',
    },
  })

  async function onSubmit(values: CreatePartnerInput) {
    try {
      const res = await create.mutateAsync(values)
      toast.success('Partner created')
      const id = (res as any)?.data?.id ?? (res as any)?.id
      navigate(id ? `/internal/partners/${id}` : '/internal/partners')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create partner')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="Add Partner" subtitle="Create a new partner">
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4"
      >
        <FormField label="Name" required error={errors.name?.message}>
          <Input {...register('name')} />
        </FormField>
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Type" required error={errors.type?.message}>
            <Select {...register('type')}>
              {PARTNER_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
            </Select>
          </FormField>
          <FormField label="Status" error={errors.status?.message}>
            <Select {...register('status')}>
              {PARTNER_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
            </Select>
          </FormField>
        </div>
        <FormField label="Contact Name" error={errors.contact_name?.message}>
          <Input {...register('contact_name')} />
        </FormField>
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Contact Email" error={errors.contact_email?.message}>
            <Input {...register('contact_email')} />
          </FormField>
          <FormField label="Contact Phone" error={errors.contact_phone?.message}>
            <Input {...register('contact_phone')} />
          </FormField>
        </div>
        <FormField label="Address" error={errors.address?.message}>
          <Input {...register('address')} />
        </FormField>
        <FormField label="Notes" error={errors.notes?.message}>
          <Textarea {...register('notes')} rows={3} />
        </FormField>
        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/partners')}>
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
