import { useEffect, useState } from 'react'
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
import RoleGate from '@/components/shared/RoleGate'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  updateCmsArticleSchema,
  type UpdateCmsArticleInput,
} from '@/schemas/cmsarticle'
import { ARTICLE_STATUSES, ARTICLE_CATEGORIES } from '@/types/cmsarticle'
import {
  useCmsArticle,
  useUpdateCmsArticle,
  useDeleteCmsArticle,
} from '@/lib/api/cms'

export default function ArticleEditPage() {
  const navigate = useNavigate()
  const { slug = '' } = useParams<{ slug: string }>()
  const { data, isLoading } = useCmsArticle(slug)
  const update = useUpdateCmsArticle(data?.id ?? '')
  const del = useDeleteCmsArticle()
  const [confirmDelete, setConfirmDelete] = useState(false)

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateCmsArticleInput>({
    resolver: zodResolver(updateCmsArticleSchema),
  })

  useEffect(() => {
    if (data) {
      reset({
        title: data.title,
        slug: data.slug,
        category: data.category,
        content: data.content,
        featured_image_url: data.featured_image_url ?? '',
        status: data.status,
      })
    }
  }, [data, reset])

  async function onSubmit(values: UpdateCmsArticleInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Article updated')
      navigate('/internal/cms/articles')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update')
    }
  }

  async function onDelete() {
    if (!data) return
    try {
      await del.mutateAsync(data.id)
      toast.success('Article deleted')
      navigate('/internal/cms/articles')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to delete')
    } finally {
      setConfirmDelete(false)
    }
  }

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'CMS', to: '/internal/cms/articles' },
    { label: 'Articles', to: '/internal/cms/articles' },
    { label: data.title, to: '#' },
    { label: 'Edit' },
  ]

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="Edit Article" subtitle={data.title}>
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="max-w-3xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4"
      >
        <FormField label="Title" required error={errors.title?.message}>
          <Input {...register('title')} />
        </FormField>
        <FormField label="Slug" error={errors.slug?.message}>
          <Input {...register('slug')} />
        </FormField>
        <FormField label="Category" required error={errors.category?.message}>
          <Select {...register('category')}>
            {ARTICLE_CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
          </Select>
        </FormField>
        <FormField label="Status" required error={errors.status?.message}>
          <Select {...register('status')}>
            {ARTICLE_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
          </Select>
        </FormField>
        <FormField label="Featured Image URL" error={errors.featured_image_url?.message}>
          <Input {...register('featured_image_url')} />
        </FormField>
        <FormField label="Content" required error={errors.content?.message}>
          <Textarea {...register('content')} rows={12} />
        </FormField>
        <div className="flex gap-2 pt-2 border-t border-neutral-100">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/cms/articles')}>
            Cancel
          </Button>
          <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
            Save
          </Button>
          <RoleGate action="delete" resource="cms_article">
            <Button type="button" variant="danger" onClick={() => setConfirmDelete(true)}>
              Delete
            </Button>
          </RoleGate>
        </div>
      </form>
      <ConfirmDialog
        open={confirmDelete}
        onConfirm={onDelete}
        onCancel={() => setConfirmDelete(false)}
        title="Delete article?"
        description="This cannot be undone."
        confirmLabel="Delete"
        destructive
      />
    </StandardPageLayout>
  )
}
