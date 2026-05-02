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
  createCmsArticleSchema,
  type CreateCmsArticleInput,
} from '@/schemas/cmsarticle'
import { ARTICLE_STATUSES, ARTICLE_CATEGORIES } from '@/types/cmsarticle'
import { useCreateCmsArticle } from '@/lib/api/cms'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'CMS', to: '/internal/cms/articles' },
  { label: 'Articles', to: '/internal/cms/articles' },
  { label: 'New Article' },
]

export default function ArticleCreatePage() {
  const navigate = useNavigate()
  const create = useCreateCmsArticle()

  const {
    register, handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateCmsArticleInput>({
    resolver: zodResolver(createCmsArticleSchema),
    defaultValues: {
      title: '',
      category: 'news',
      content: '',
      featured_image_url: '',
      status: 'draft',
    },
  })

  async function onSubmit(values: CreateCmsArticleInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Article created')
      navigate('/internal/cms/articles')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="New Article">
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="max-w-3xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4"
      >
        <FormField label="Title" required error={errors.title?.message}>
          <Input {...register('title')} />
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
        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/cms/articles')}>
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
