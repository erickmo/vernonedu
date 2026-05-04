import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Newspaper } from 'lucide-react'
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

const MEDIA_TYPES = [
  { value: 'press_release', label: 'Press Release' },
  { value: 'article', label: 'Artikel' },
  { value: 'interview', label: 'Wawancara' },
] as const

const STATUSES = [
  { value: 'draft', label: 'Draft' },
  { value: 'published', label: 'Dipublikasi' },
] as const

export default function PrContentFormPage() {
  const navigate = useNavigate()
  const { contentId } = useParams<{ contentId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(contentId)

  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [mediaType, setMediaType] = useState('')
  const [publishDate, setPublishDate] = useState('')
  const [status, setStatus] = useState('draft')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: prList } = useQuery({
    queryKey: ['marketing-pr'],
    queryFn: () => marketingService.listPr(),
    enabled: isEdit,
  })

  const prItem = isEdit
    ? (Array.isArray(prList) ? prList : (prList as any)?.items ?? []).find((p: any) => String(p.id) === contentId)
    : null

  useEffect(() => {
    if (prItem) {
      setTitle(prItem.title ?? '')
      setContent(prItem.content ?? '')
      setMediaType(prItem.media_type ?? '')
      setPublishDate(prItem.publish_date ?? '')
      setStatus(prItem.status ?? 'draft')
    }
  }, [prItem])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!title.trim()) e.title = 'Judul wajib diisi'
    if (!content.trim()) e.content = 'Konten PR wajib diisi'
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
        media_type: mediaType || undefined,
        publish_date: publishDate || undefined,
      }
      if (isEdit) {
        payload.status = status
        await marketingService.updatePr(contentId!, payload)
        toast.success('Konten PR berhasil diperbarui')
      } else {
        await marketingService.createPr(payload)
        toast.success('Konten PR berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['marketing-pr'] })
      navigate('/marketing')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Konten PR' : 'Tambah Konten PR'}
      icon={<Newspaper size={20} />}
      onBack={() => navigate('/marketing')}
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
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="cth. Peluncuran Program Baru"
                  className={`${formStyles.input} ${errors.title ? formStyles.inputError : ''}`}
                  autoFocus
                />
              </Field>

              <Field label="Konten PR" required error={errors.content}>
                <textarea
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder="Tulis konten PR..."
                  rows={8}
                  className={`${formStyles.textarea} ${errors.content ? formStyles.inputError : ''}`}
                />
              </Field>
            </FormColumn>

            <FormColumn>
              <Field label="Jenis Media">
                <select
                  value={mediaType}
                  onChange={(e) => setMediaType(e.target.value)}
                  className={formStyles.input}
                >
                  <option value="">Pilih jenis media...</option>
                  {MEDIA_TYPES.map((m) => (
                    <option key={m.value} value={m.value}>{m.label}</option>
                  ))}
                </select>
              </Field>

              <Field label="Tanggal Publikasi">
                <input
                  type="date"
                  value={publishDate}
                  onChange={(e) => setPublishDate(e.target.value)}
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
