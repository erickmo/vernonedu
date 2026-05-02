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
import {
  createMarketingPrSchema,
  type CreateMarketingPrInput,
} from '@/schemas/marketingpr'
import { PR_TYPES } from '@/types/marketingpr'
import { useCreateMarketingPr } from '@/lib/api/marketing'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Marketing', to: '/internal/marketing/pr' },
  { label: 'PR', to: '/internal/marketing/pr' },
  { label: 'New PR' },
]

export default function MarketingPRCreatePage() {
  const navigate = useNavigate()
  const create = useCreateMarketingPr()

  const {
    register, handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateMarketingPrInput>({
    resolver: zodResolver(createMarketingPrSchema),
    defaultValues: {
      title: '',
      type: 'press_release',
      scheduled_at: '',
      media_venue: '',
      pic_id: null,
      pic_name: '',
      notes: '',
    },
  })

  async function onSubmit(values: CreateMarketingPrInput) {
    try {
      await create.mutateAsync(values)
      toast.success('PR created')
      navigate('/internal/marketing/pr')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="New Marketing PR">
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Title" required error={errors.title?.message}>
          <Input {...register('title')} />
        </FormField>
        <FormField label="Type" required error={errors.type?.message}>
          <Select {...register('type')}>
            {PR_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
          </Select>
        </FormField>
        <FormField label="Scheduled At" required error={errors.scheduled_at?.message}>
          <Input type="datetime-local" {...register('scheduled_at')} />
        </FormField>
        <FormField label="Media / Venue" error={errors.media_venue?.message}>
          <Input {...register('media_venue')} placeholder="e.g. Kompas TV, Hotel Mulia" />
        </FormField>
        <FormField label="PIC Name" error={errors.pic_name?.message}>
          <Input {...register('pic_name')} />
        </FormField>
        <FormField label="Notes" error={errors.notes?.message}>
          <Textarea {...register('notes')} rows={4} />
        </FormField>
        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/marketing/pr')}>
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
