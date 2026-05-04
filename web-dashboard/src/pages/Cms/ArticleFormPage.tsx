import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { FileText } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { cmsService } from '@/services/cms.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const STATUSES = [
  { value: 'draft', label: 'Draft' },
  { value: 'published', label: 'Dipublikasi' },
] as const

export default function ArticleFormPage() {
  const navigate = useNavigate()
  const { articleId } = useParams<{ articleId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(articleId)

  const [title, setTitle] = useState('')
  const [slug, setSlug] = useState('')
  const [content, setContent] = useState('')
  const [excerpt, setExcerpt] = useState('')
  const [category, setCategory] = useState('')
  const [status, setStatus] = useState('draft')
  const [featuredImageUrl, setFeaturedImageUrl] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: articles } = useQuery({
    queryKey: ['cms-articles'],
    queryFn: () => cmsService.listArticles(),
    enabled: isEdit,
  })

  const article = isEdit
    ? (Array.isArray(articles) ? articles : (articles as any)?.items ?? []).find((a: any) => String(a.id) === articleId)
    : null

  useEffect(() => {
    if (article) {
      setTitle(article.title ?? '')
      setSlug(article.slug ?? '')
      setContent(article.content ?? '')
      setExcerpt(article.excerpt ?? '')
      setCategory(article.category ?? '')
      setStatus(article.status ?? 'draft')
      setFeaturedImageUrl(article.featured_image_url ?? '')
    }
  }, [article])

  function generateSlug(text: string): string {
    return text
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim()
  }

  function handleTitleChange(value: string) {
    setTitle(value)
    if (!isEdit) {
      setSlug(generateSlug(value))
    }
  }

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!title.trim()) e.title = 'Judul wajib diisi'
    if (!content.trim()) e.content = 'Konten wajib diisi'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(ev: React.FormEvent) {
    ev.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')

    try {
      const payload: Record<string, any> = {
        title: title.trim(),
        slug: slug.trim() || generateSlug(title),
        content: content.trim(),
        excerpt: excerpt.trim() || undefined,
        category: category.trim() || undefined,
        featured_image_url: featuredImageUrl.trim() || undefined,
      }
      if (isEdit) {
        payload.status = status
        await cmsService.updateArticle(articleId!, payload)
        toast.success('Artikel berhasil diperbarui')
      } else {
        await cmsService.createArticle(payload)
        toast.success('Artikel berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['cms-articles'] })
      navigate('/cms')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Artikel' : 'Tambah Artikel'}
      icon={<FileText size={20} />}
      onBack={() => navigate('/cms')}
      tabs={[{
        id: 'general',
        label: 'Informasi Umum',
        content: (
          <FormGrid>
            <FormColumn>
              <Field label="Judul" required error={errors.title}>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => handleTitleChange(e.target.value)}
                  placeholder="cth. Tips Memilih Kursus yang Tepat"
                  className={`${formStyles.input} ${errors.title ? formStyles.inputError : ''}`}
                  autoFocus
                />
              </Field>

              <Field label="Slug URL" hint="Otomatis dari judul. Bisa diubah manual.">
                <input
                  type="text"
                  value={slug}
                  onChange={(e) => setSlug(e.target.value)}
                  placeholder="tips-memilih-kursus"
                  className={formStyles.input}
                />
              </Field>

              <Field label="Konten" required error={errors.content}>
                <textarea
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder="Tulis konten artikel..."
                  rows={12}
                  className={`${formStyles.textarea} ${errors.content ? formStyles.inputError : ''}`}
                />
              </Field>

              <Field label="Ringkasan" hint="Singkat isi artikel untuk preview.">
                <textarea
                  value={excerpt}
                  onChange={(e) => setExcerpt(e.target.value)}
                  placeholder="Ringkasan singkat artikel..."
                  rows={3}
                  className={formStyles.textarea}
                />
              </Field>
            </FormColumn>

            <FormColumn>
              <Field label="Kategori">
                <input
                  type="text"
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  placeholder="cth. Tips & Trik"
                  className={formStyles.input}
                />
              </Field>

              {isEdit && (
                <Field label="Status">
                  <select
                    value={status}
                    onChange={(e) => setStatus(e.target.value)}
                    className={formStyles.input}
                  >
                    {STATUSES.map((s) => (
                      <option key={s.value} value={s.value}>{s.label}</option>
                    ))}
                  </select>
                </Field>
              )}

              <Field label="URL Gambar Utama">
                <input
                  type="text"
                  value={featuredImageUrl}
                  onChange={(e) => setFeaturedImageUrl(e.target.value)}
                  placeholder="https://example.com/image.jpg"
                  className={formStyles.input}
                />
              </Field>
            </FormColumn>
          </FormGrid>
        ),
      }]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/cms')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
