import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { LayoutTemplate } from 'lucide-react'
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

export default function PageEditorPage() {
  const navigate = useNavigate()
  const { pageId } = useParams<{ pageId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(pageId)

  const [title, setTitle] = useState('')
  const [slug, setSlug] = useState('')
  const [content, setContent] = useState('')
  const [metaDescription, setMetaDescription] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: page } = useQuery({
    queryKey: ['cms-page', pageId],
    queryFn: () => cmsService.getPage(pageId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (page) {
      setTitle(page.title ?? '')
      setSlug(page.slug ?? '')
      setContent(page.content ?? '')
      setMetaDescription(page.meta_description ?? '')
    }
  }, [page])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!title.trim()) e.title = 'Judul halaman wajib diisi'
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
        content: content.trim(),
        meta_description: metaDescription.trim() || undefined,
      }
      const targetSlug = isEdit ? pageId! : slug.trim()
      if (!isEdit) {
        payload.slug = slug.trim()
      }
      await cmsService.updatePage(targetSlug, payload)
      toast.success(isEdit ? 'Halaman berhasil diperbarui' : 'Halaman berhasil dibuat')
      await queryClient.invalidateQueries({ queryKey: ['cms-pages'] })
      navigate('/cms')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Halaman' : 'Buat Halaman'}
      icon={<LayoutTemplate size={20} />}
      onBack={() => navigate('/cms')}
      tabs={[{
        id: 'general',
        label: 'Konten Halaman',
        content: (
          <FormGrid>
            <FormColumn>
              <Field label="Judul Halaman" required error={errors.title}>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="cth. Tentang Kami"
                  className={`${formStyles.input} ${errors.title ? formStyles.inputError : ''}`}
                  autoFocus
                />
              </Field>

              <Field label="Slug URL" hint={isEdit ? 'Slug tidak dapat diubah setelah dibuat.' : 'Slug akan digunakan sebagai URL halaman.'}>
                <input
                  type="text"
                  value={slug}
                  onChange={(e) => setSlug(e.target.value)}
                  placeholder="tentang-kami"
                  className={`${formStyles.input} ${isEdit ? formStyles.inputReadonly : ''}`}
                  readOnly={isEdit}
                />
              </Field>

              <Field label="Konten (HTML)" required error={errors.content} hint="Gunakan format HTML untuk konten halaman.">
                <textarea
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder="<h1>Selamat Datang</h1>\n<p>Konten halaman...</p>"
                  rows={16}
                  className={`${formStyles.textarea} ${errors.content ? formStyles.inputError : ''}`}
                  style={{ fontFamily: 'var(--font-mono)', fontSize: 'var(--font-xs)' }}
                />
              </Field>
            </FormColumn>

            <FormColumn>
              <Field label="Meta Deskripsi" hint="Deskripsi singkat untuk SEO (max 160 karakter).">
                <textarea
                  value={metaDescription}
                  onChange={(e) => setMetaDescription(e.target.value)}
                  placeholder="Deskripsi singkat halaman untuk mesin pencari..."
                  rows={4}
                  className={formStyles.textarea}
                />
                <span style={{
                  fontSize: 'var(--font-min)', color: 'var(--color-text-tertiary)',
                  textAlign: 'right', display: 'block', marginTop: 2,
                }}>
                  {metaDescription.length}/160
                </span>
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
