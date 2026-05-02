import { useNavigate } from 'react-router-dom'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import {
  createMarketingPostSchema,
  type CreateMarketingPostInput,
} from '@/schemas/marketingpost'
import { POST_PLATFORMS, POST_CONTENT_TYPES } from '@/types/marketingpost'
import { useCreateMarketingPost } from '@/lib/api/marketing'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Marketing', to: '/internal/marketing/posts' },
  { label: 'Posts', to: '/internal/marketing/posts' },
  { label: 'New Post' },
]

export default function MarketingPostCreatePage() {
  const navigate = useNavigate()
  const create = useCreateMarketingPost()

  const {
    register, handleSubmit, control,
    formState: { errors, isSubmitting },
  } = useForm<CreateMarketingPostInput>({
    resolver: zodResolver(createMarketingPostSchema),
    defaultValues: {
      platforms: [],
      scheduled_at: '',
      content_type: 'image',
      caption: '',
      media_url: '',
      batch_id: null,
    },
  })

  async function onSubmit(values: CreateMarketingPostInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Post created')
      navigate('/internal/marketing/posts')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="New Marketing Post">
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Platforms" required error={errors.platforms?.message as string | undefined}>
          <Controller
            name="platforms"
            control={control}
            render={({ field }) => (
              <div className="flex flex-wrap gap-2">
                {POST_PLATFORMS.map((p) => {
                  const active = (field.value ?? []).includes(p)
                  return (
                    <button
                      key={p}
                      type="button"
                      onClick={() => {
                        const current = field.value ?? []
                        field.onChange(
                          active ? current.filter((v) => v !== p) : [...current, p],
                        )
                      }}
                      className={`px-3 py-1.5 text-sm rounded-lg border ${
                        active
                          ? 'bg-brand-50 border-brand-500 text-brand-700'
                          : 'bg-white border-neutral-200 text-neutral-700'
                      }`}
                    >
                      {p}
                    </button>
                  )
                })}
              </div>
            )}
          />
        </FormField>
        <FormField label="Scheduled At" required error={errors.scheduled_at?.message}>
          <Input type="datetime-local" {...register('scheduled_at')} />
        </FormField>
        <FormField label="Content Type" required error={errors.content_type?.message}>
          <Select {...register('content_type')}>
            {POST_CONTENT_TYPES.map((c) => <option key={c} value={c}>{c}</option>)}
          </Select>
        </FormField>
        <FormField label="Caption" required error={errors.caption?.message}>
          <Textarea {...register('caption')} rows={5} />
        </FormField>
        <FormField label="Media URL" error={errors.media_url?.message}>
          <Input {...register('media_url')} />
        </FormField>
        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/marketing/posts')}>
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
