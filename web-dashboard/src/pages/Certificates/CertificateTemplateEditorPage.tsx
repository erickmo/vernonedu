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
import { certificateService } from '@/services/certificate.service'
import { QK } from '@/services/query-keys'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

interface TemplateData {
  id: string
  name: string
  type: string
  description: string
  content: string
}

export default function CertificateTemplateEditorPage() {
  const navigate = useNavigate()
  const { templateId } = useParams<{ templateId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(templateId)

  const [name, setName] = useState('')
  const [type, setType] = useState('participant')
  const [description, setDescription] = useState('')
  const [content, setContent] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: templates } = useQuery({
    queryKey: [QK.certificateTemplates],
    queryFn: () => certificateService.getTemplates(),
    enabled: isEdit,
  })

  useEffect(() => {
    if (!isEdit || !templates) return
    const found = (templates as TemplateData[]).find((t) => t.id === templateId)
    if (found) {
      setName(found.name ?? '')
      setType(found.type ?? 'participant')
      setDescription(found.description ?? '')
      setContent(found.content ?? '')
    }
  }, [templates, isEdit, templateId])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama template wajib diisi'
    else if (name.trim().length < 2) e.name = 'Minimal 2 karakter'
    if (!content.trim()) e.content = 'Konten template wajib diisi'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(ev: React.FormEvent) {
    ev.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')

    try {
      const payload = {
        name: name.trim(),
        type,
        description: description.trim(),
        content: content.trim(),
      }
      if (isEdit) {
        await certificateService.updateTemplate(templateId!, payload)
        toast.success('Template berhasil diperbarui')
      } else {
        await certificateService.createTemplate(payload)
        toast.success('Template berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: [QK.certificateTemplates] })
      navigate('/certificates/templates')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan template')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Template Sertifikat' : 'Template Sertifikat Baru'}
      icon={<FileText size={20} />}
      onBack={() => navigate('/certificates/templates')}
      tabs={[
        {
          id: 'general',
          label: 'Konten Template',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Template" required error={errors.name}>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="cth. Template Sertifikat Peserta v2"
                    className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field label="Jenis Sertifikat">
                  <select
                    value={type}
                    onChange={(e) => setType(e.target.value)}
                    className={formStyles.select}
                  >
                    <option value="participant">Peserta</option>
                    <option value="competency">Kompetensi</option>
                  </select>
                </Field>
                <Field label="Deskripsi" hint="Opsional. Deskripsi singkat template ini.">
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Deskripsi template..."
                    rows={3}
                    className={formStyles.textarea}
                  />
                </Field>
                <Field label="Konten Template (HTML)" required error={errors.content} hint="Gunakan HTML untuk desain template sertifikat.">
                  <textarea
                    value={content}
                    onChange={(e) => setContent(e.target.value)}
                    placeholder={'<div style="...">\n  <h1>Sertifikat</h1>\n  ...\n</div>'}
                    rows={14}
                    className={formStyles.textarea}
                    style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: 'var(--font-xs)' }}
                  />
                  <span style={{
                    fontSize: 'var(--font-min)', color: 'var(--color-text-tertiary)',
                    textAlign: 'right', display: 'block', marginTop: 2,
                  }}>
                    {content.length} karakter
                  </span>
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Panduan Template">
                  <div style={{
                    padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
                    border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
                    fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', lineHeight: 1.6,
                  }}>
                    <p style={{ marginBottom: 'var(--space-2)', fontWeight: 600 }}>
                      Variabel yang tersedia:
                    </p>
                    <ul style={{ paddingLeft: 16, margin: 0 }}>
                      <li>{'{{student_name}}'} — Nama siswa</li>
                      <li>{'{{batch_name}}'} — Nama batch</li>
                      <li>{'{{course_name}}'} — Nama kursus</li>
                      <li>{'{{issue_date}}'} — Tanggal terbit</li>
                      <li>{'{{certificate_number}}'} — Nomor sertifikat</li>
                      <li>{'{{test_score}}'} — Nilai tes (kompetensi)</li>
                    </ul>
                  </div>
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/certificates/templates')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
