import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { MessageSquareQuote } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
  Toggle,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { cmsService } from '@/services/cms.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

export default function TestimonialFormPage() {
  const navigate = useNavigate()
  const { testimonialId } = useParams<{ testimonialId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(testimonialId)

  const [name, setName] = useState('')
  const [role, setRole] = useState('')
  const [content, setContent] = useState('')
  const [rating, setRating] = useState('')
  const [imageUrl, setImageUrl] = useState('')
  const [isActive, setIsActive] = useState(true)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: testimonials } = useQuery({
    queryKey: ['cms-testimonials'],
    queryFn: () => cmsService.listTestimonials(),
    enabled: isEdit,
  })

  const testimonial = isEdit
    ? (Array.isArray(testimonials) ? testimonials : (testimonials as any)?.items ?? []).find((t: any) => String(t.id) === testimonialId)
    : null

  useEffect(() => {
    if (testimonial) {
      setName(testimonial.name ?? '')
      setRole(testimonial.role ?? '')
      setContent(testimonial.content ?? '')
      setRating(testimonial.rating != null ? String(testimonial.rating) : '')
      setImageUrl(testimonial.image_url ?? '')
      setIsActive(testimonial.is_active ?? true)
    }
  }, [testimonial])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama wajib diisi'
    if (!content.trim()) e.content = 'Testimoni wajib diisi'
    if (rating && (Number(rating) < 1 || Number(rating) > 5)) e.rating = 'Rating harus antara 1-5'
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
        name: name.trim(),
        role: role.trim() || undefined,
        content: content.trim(),
        rating: rating ? Number(rating) : undefined,
        image_url: imageUrl.trim() || undefined,
        is_active: isActive,
      }
      if (isEdit) {
        await cmsService.updateTestimonial(testimonialId!, payload)
        toast.success('Testimoni berhasil diperbarui')
      } else {
        await cmsService.createTestimonial(payload)
        toast.success('Testimoni berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['cms-testimonials'] })
      navigate('/cms')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Testimoni' : 'Tambah Testimoni'}
      icon={<MessageSquareQuote size={20} />}
      onBack={() => navigate('/cms')}
      tabs={[{
        id: 'general',
        label: 'Informasi Umum',
        content: (
          <FormGrid>
            <FormColumn>
              <Field label="Nama" required error={errors.name}>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="cth. Budi Santoso"
                  className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                  autoFocus
                />
              </Field>

              <Field label="Peran/Jabatan">
                <input
                  type="text"
                  value={role}
                  onChange={(e) => setRole(e.target.value)}
                  placeholder="cth. Alumni Kursus Web Development"
                  className={formStyles.input}
                />
              </Field>

              <Field label="Testimoni" required error={errors.content}>
                <textarea
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder="Tulis testimoni..."
                  rows={5}
                  className={`${formStyles.textarea} ${errors.content ? formStyles.inputError : ''}`}
                />
              </Field>
            </FormColumn>

            <FormColumn>
              <Field label="Rating" error={errors.rating} hint="Skala 1-5">
                <input
                  type="number"
                  value={rating}
                  onChange={(e) => setRating(e.target.value)}
                  placeholder="cth. 5"
                  min={1}
                  max={5}
                  className={`${formStyles.input} ${errors.rating ? formStyles.inputError : ''}`}
                />
              </Field>

              <Field label="URL Foto">
                <input
                  type="text"
                  value={imageUrl}
                  onChange={(e) => setImageUrl(e.target.value)}
                  placeholder="https://example.com/photo.jpg"
                  className={formStyles.input}
                />
              </Field>

              <Field label="Aktif">
                <div style={{
                  padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
                  border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
                }}>
                  <Toggle
                    checked={isActive}
                    onChange={setIsActive}
                    label={isActive ? 'Aktif — ditampilkan di website' : 'Nonaktif — tersembunyi'}
                  />
                </div>
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
