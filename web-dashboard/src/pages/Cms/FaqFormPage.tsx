import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { HelpCircle } from 'lucide-react'
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

export default function FaqFormPage() {
  const navigate = useNavigate()
  const { faqId } = useParams<{ faqId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(faqId)

  const [question, setQuestion] = useState('')
  const [answer, setAnswer] = useState('')
  const [category, setCategory] = useState('')
  const [sortOrder, setSortOrder] = useState('')
  const [isActive, setIsActive] = useState(true)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: faqList } = useQuery({
    queryKey: ['cms-faq'],
    queryFn: () => cmsService.listFaq(),
    enabled: isEdit,
  })

  const faqItem = isEdit
    ? (Array.isArray(faqList) ? faqList : (faqList as any)?.items ?? []).find((f: any) => String(f.id) === faqId)
    : null

  useEffect(() => {
    if (faqItem) {
      setQuestion(faqItem.question ?? '')
      setAnswer(faqItem.answer ?? '')
      setCategory(faqItem.category ?? '')
      setSortOrder(faqItem.sort_order != null ? String(faqItem.sort_order) : '')
      setIsActive(faqItem.is_active ?? true)
    }
  }, [faqItem])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!question.trim()) e.question = 'Pertanyaan wajib diisi'
    if (!answer.trim()) e.answer = 'Jawaban wajib diisi'
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
        question: question.trim(),
        answer: answer.trim(),
        category: category.trim() || undefined,
        sort_order: sortOrder ? Number(sortOrder) : undefined,
        is_active: isActive,
      }
      if (isEdit) {
        await cmsService.updateFaq(faqId!, payload)
        toast.success('FAQ berhasil diperbarui')
      } else {
        await cmsService.createFaq(payload)
        toast.success('FAQ berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['cms-faq'] })
      navigate('/cms')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit FAQ' : 'Tambah FAQ'}
      icon={<HelpCircle size={20} />}
      onBack={() => navigate('/cms')}
      tabs={[{
        id: 'general',
        label: 'Informasi Umum',
        content: (
          <FormGrid>
            <FormColumn>
              <Field label="Pertanyaan" required error={errors.question}>
                <input
                  type="text"
                  value={question}
                  onChange={(e) => setQuestion(e.target.value)}
                  placeholder="cth. Bagaimana cara mendaftar kursus?"
                  className={`${formStyles.input} ${errors.question ? formStyles.inputError : ''}`}
                  autoFocus
                />
              </Field>

              <Field label="Jawaban" required error={errors.answer}>
                <textarea
                  value={answer}
                  onChange={(e) => setAnswer(e.target.value)}
                  placeholder="Tulis jawaban..."
                  rows={6}
                  className={`${formStyles.textarea} ${errors.answer ? formStyles.inputError : ''}`}
                />
              </Field>
            </FormColumn>

            <FormColumn>
              <Field label="Kategori">
                <input
                  type="text"
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  placeholder="cth. Pendaftaran"
                  className={formStyles.input}
                />
              </Field>

              <Field label="Urutan" hint="Nomor urut tampilan FAQ">
                <input
                  type="number"
                  value={sortOrder}
                  onChange={(e) => setSortOrder(e.target.value)}
                  placeholder="cth. 1"
                  min={0}
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
