import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import RoleGate from '@/components/shared/RoleGate'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  updateMarketingPostSchema,
  submitPostUrlSchema,
  type UpdateMarketingPostInput,
  type SubmitPostUrlInput,
} from '@/schemas/marketingpost'
import {
  POST_PLATFORMS,
  POST_CONTENT_TYPES,
  POST_STATUSES,
} from '@/types/marketingpost'
import {
  useMarketingPost,
  useUpdateMarketingPost,
  useDeleteMarketingPost,
  useSubmitMarketingPostUrl,
} from '@/lib/api/marketing'

export default function MarketingPostEditPage() {
  const navigate = useNavigate()
  const { id = '' } = useParams<{ id: string }>()
  const { data, isLoading } = useMarketingPost(id)
  const update = useUpdateMarketingPost(id)
  const submitUrl = useSubmitMarketingPostUrl(id)
  const del = useDeleteMarketingPost()
  const [confirmDelete, setConfirmDelete] = useState(false)

  const {
    register, handleSubmit, control, reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateMarketingPostInput>({
    resolver: zodResolver(updateMarketingPostSchema),
  })

  const urlForm = useForm<SubmitPostUrlInput>({
    resolver: zodResolver(submitPostUrlSchema),
    defaultValues: { post_url: '' },
  })

  useEffect(() => {
    if (data) {
      reset({
        platforms: data.platforms ?? [],
        scheduled_at: data.scheduled_at?.slice(0, 16) ?? '',
        content_type: data.content_type,
        caption: data.caption,
        media_url: data.media_url ?? '',
        batch_id: data.batch_id ?? null,
        status: data.status,
      })
      urlForm.reset({ post_url: data.post_url ?? '' })
    }
  }, [data, reset, urlForm])

  async function onSubmit(values: UpdateMarketingPostInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Post updated')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update')
    }
  }

  async function onSubmitUrl(values: SubmitPostUrlInput) {
    try {
      await submitUrl.mutateAsync(values)
      toast.success('Post URL submitted')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed')
    }
  }

  async function onDelete() {
    try {
      await del.mutateAsync(id)
      toast.success('Post deleted')
      navigate('/internal/marketing/posts')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed')
    } finally {
      setConfirmDelete(false)
    }
  }

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Marketing', to: '/internal/marketing/posts' },
    { label: 'Posts', to: '/internal/marketing/posts' },
    { label: 'Edit' },
  ]

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="Edit Marketing Post">
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
                        active ? 'bg-brand-50 border-brand-500 text-brand-700' : 'bg-white border-neutral-200 text-neutral-700'
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
        <FormField label="Status" required error={errors.status?.message}>
          <Select {...register('status')}>
            {POST_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
          </Select>
        </FormField>
        <FormField label="Caption" required error={errors.caption?.message}>
          <Textarea {...register('caption')} rows={5} />
        </FormField>
        <FormField label="Media URL" error={errors.media_url?.message}>
          <Input {...register('media_url')} />
        </FormField>
        <div className="flex gap-2 pt-2 border-t border-neutral-100">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/marketing/posts')}>
            Cancel
          </Button>
          <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
            Save
          </Button>
          <RoleGate action="delete" resource="marketing_post">
            <Button type="button" variant="danger" onClick={() => setConfirmDelete(true)}>
              Delete
            </Button>
          </RoleGate>
        </div>
      </form>

      <form
        onSubmit={urlForm.handleSubmit(onSubmitUrl)}
        className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 mt-4 space-y-4"
      >
        <div className="text-sm font-semibold text-neutral-900">Submit Post URL</div>
        <FormField label="Published Post URL" error={urlForm.formState.errors.post_url?.message}>
          <Input {...urlForm.register('post_url')} placeholder="https://..." />
        </FormField>
        <Button type="submit" loading={urlForm.formState.isSubmitting}>
          Submit URL
        </Button>
      </form>

      <ConfirmDialog
        open={confirmDelete}
        onConfirm={onDelete}
        onCancel={() => setConfirmDelete(false)}
        title="Delete post?"
        description="This cannot be undone."
        confirmLabel="Delete"
        destructive
      />
    </StandardPageLayout>
  )
}
