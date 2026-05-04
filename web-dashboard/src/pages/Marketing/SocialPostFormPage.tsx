import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Megaphone } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { marketingService } from '@/services/marketing.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const PLATFORMS = [
  { value: 'instagram', label: 'Instagram' },
  { value: 'facebook', label: 'Facebook' },
  { value: 'linkedin', label: 'LinkedIn' },
  { value: 'tiktok', label: 'TikTok' },
  { value: 'twitter', label: 'Twitter/X' },
] as const

const STATUSES = [
  { value: 'draft', label: 'Draft' },
  { value: 'scheduled', label: 'Terjadwal' },
  { value: 'published', label: 'Dipublikasi' },
] as const

export default function SocialPostFormPage() {
  const navigate = useNavigate()
  const { postId } = useParams<{ postId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(postId)

  const [platform, setPlatform] = useState('')
  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [scheduledAt, setScheduledAt] = useState('')
  const [imageUrl, setImageUrl] = useState('')
  const [status, setStatus] = useState('draft')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: posts } = useQuery({
    queryKey: ['marketing-posts'],
    queryFn: () => marketingService.listPosts(),
    enabled: isEdit,
  })

  const post = isEdit
    ? (Array.isArray(posts) ? posts : (posts as any)?.items ?? []).find((p: any) => String(p.id) === postId)
    : null

  useEffect(() => {
    if (post) {
      setPlatform(post.platform ?? '')
      setTitle(post.title ?? '')
      setContent(post.content ?? '')
      setScheduledAt(post.scheduled_at ? String(post.scheduled_at).slice(0, 16) : '')
      setImageUrl(post.image_url ?? '')
      setStatus(post.status ?? 'draft')
    }
  }, [post])

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
        platform: platform || undefined,
        title: title.trim(),
        content: content.trim(),
        scheduled_at: scheduledAt || undefined,
        image_url: imageUrl.trim() || undefined,
      }
      if (isEdit) {
        payload.status = status
        await marketingService.updatePost(postId!, payload)
        toast.success('Postingan berhasil diperbarui')
      } else {
        await marketingService.createPost(payload)
        toast.success('Postingan berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['marketing-posts'] })
      navigate('/marketing')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Postingan' : 'Tambah Postingan'}
      icon={<Megaphone size={20} />}
      onBack={() => navigate('/marketing')}
      tabs={[{
        id: 'general',
        label: 'Informasi Umum',
        content: (
          <FormGrid>
            <FormColumn>
              <Field label="Platform">
                <select
                  value={platform}
                  onChange={(e) => setPlatform(e.target.value)}
                  className={formStyles.input}
                >
                  <option value="">Pilih platform...</option>
                  {PLATFORMS.map((p) => (
                    <option key={p.value} value={p.value}>{p.label}</option>
                  ))}
                </select>
              </Field>

              <Field label="Judul" required error={errors.title}>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="cth. Promo Kursus Musim Panas"
                  className={`${formStyles.input} ${errors.title ? formStyles.inputError : ''}`}
                  autoFocus
                />
              </Field>

              <Field label="Konten" required error={errors.content}>
                <textarea
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder="Tulis konten postingan..."
                  rows={6}
                  className={`${formStyles.textarea} ${errors.content ? formStyles.inputError : ''}`}
                />
              </Field>

              <Field label="Jadwal Posting">
                <input
                  type="datetime-local"
                  value={scheduledAt}
                  onChange={(e) => setScheduledAt(e.target.value)}
                  className={formStyles.input}
                />
              </Field>
            </FormColumn>

            <FormColumn>
              <Field label="URL Gambar">
                <input
                  type="text"
                  value={imageUrl}
                  onChange={(e) => setImageUrl(e.target.value)}
                  placeholder="https://example.com/image.jpg"
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
            </FormColumn>
          </FormGrid>
        ),
      }]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/marketing')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
