import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { BookOpen, Calendar, Clock } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { SearchableSelect, type SelectOption } from '@/widgets/SearchableSelect/SearchableSelect'
import { TagInput } from '@/widgets/TagInput/TagInput'
import { toast } from '@/widgets/Toast/Toast'
import { courseService } from '@/services/course.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const FIELD_OPTIONS: SelectOption[] = [
  { value: 'Teknologi', label: 'Teknologi' },
  { value: 'Bisnis & Kewirausahaan', label: 'Bisnis & Kewirausahaan' },
  { value: 'Desain', label: 'Desain' },
  { value: 'Seni & Kreatif', label: 'Seni & Kreatif' },
  { value: 'Sains', label: 'Sains' },
  { value: 'Kesehatan', label: 'Kesehatan' },
  { value: 'Pendidikan', label: 'Pendidikan' },
  { value: 'Sosial & Komunikasi', label: 'Sosial & Komunikasi' },
  { value: 'Hukum', label: 'Hukum' },
  { value: 'Pertanian', label: 'Pertanian' },
]

async function fetchFieldOptions(search: string): Promise<SelectOption[]> {
  const q = search.toLowerCase()
  return q
    ? FIELD_OPTIONS.filter(o => o.label.toLowerCase().includes(q))
    : FIELD_OPTIONS
}

function formatDate(ts: number | undefined) {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(ts * 1000))
}

export default function CourseFormPage() {
  const navigate = useNavigate()
  const { courseId } = useParams<{ courseId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(courseId)

  const [courseCode, setCourseCode] = useState('')
  const [courseName, setCourseName] = useState('')
  const [field, setField] = useState('')
  const [fieldLabel, setFieldLabel] = useState('')
  const [coreCompetencies, setCoreCompetencies] = useState<string[]>([])
  const [description, setDescription] = useState('')
  const [supportingAppUrl, setSupportingAppUrl] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: course } = useQuery({
    queryKey: ['course', courseId],
    queryFn: () => courseService.getById(courseId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (course) {
      setCourseCode(course.course_code ?? '')
      setCourseName(course.course_name ?? '')
      setField(course.field ?? '')
      setFieldLabel(course.field ?? '')
      setCoreCompetencies(course.core_competencies ?? [])
      setDescription(course.description ?? '')
      setSupportingAppUrl(course.supporting_app_url ?? '')
    }
  }, [course])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!isEdit && !courseCode.trim()) e.course_code = 'Kode kursus wajib diisi'
    if (!courseName.trim()) e.course_name = 'Nama kursus wajib diisi'
    else if (courseName.trim().length < 2) e.course_name = 'Minimal 2 karakter'
    if (!field) e.field = 'Bidang studi wajib dipilih'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')

    try {
      if (isEdit) {
        await courseService.update(courseId!, {
          course_name: courseName.trim(),
          field,
          core_competencies: coreCompetencies,
          description: description.trim(),
          supporting_app_url: supportingAppUrl.trim() || undefined,
        })
        toast.success('Kursus berhasil diperbarui')
      } else {
        await courseService.create({
          course_code: courseCode.trim(),
          course_name: courseName.trim(),
          field,
          core_competencies: coreCompetencies,
          description: description.trim(),
          supporting_app_url: supportingAppUrl.trim() || undefined,
        })
        toast.success('Kursus berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['courses'] })
      navigate(isEdit ? `/course/${courseId}` : '/course')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const sidebarContent = (
    <FormColumn>
      {isEdit && course && (
        <Field label="Informasi">
          <div style={{
            padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            display: 'flex', flexDirection: 'column', gap: 'var(--space-3)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Calendar size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Dibuat</span>
              <span style={{ fontWeight: 500 }}>{formatDate(course.created_at)}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Clock size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Diperbarui</span>
              <span style={{ fontWeight: 500 }}>{formatDate(course.updated_at)}</span>
            </div>
          </div>
        </Field>
      )}
    </FormColumn>
  )

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Kursus' : 'Tambah Kursus'}
      icon={<BookOpen size={20} />}
      onBack={() => navigate(isEdit ? `/course/${courseId}` : '/course')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Umum',
          content: (
            <FormGrid>
              <FormColumn>
                {!isEdit && (
                  <Field label="Kode Kursus" required error={errors.course_code} hint="Kode unik, tidak bisa diubah setelah disimpan. Contoh: WD-001">
                    <input
                      type="text"
                      value={courseCode}
                      onChange={(e) => setCourseCode(e.target.value)}
                      placeholder="cth. WD-001"
                      className={`${formStyles.input} ${errors.course_code ? formStyles.inputError : ''}`}
                      autoFocus
                    />
                  </Field>
                )}

                <Field label="Nama Kursus" required error={errors.course_name}>
                  <input
                    type="text"
                    value={courseName}
                    onChange={(e) => setCourseName(e.target.value)}
                    placeholder="cth. Web Development Fundamentals"
                    className={`${formStyles.input} ${errors.course_name ? formStyles.inputError : ''}`}
                    autoFocus={isEdit}
                  />
                </Field>

                <Field label="Bidang Studi" required error={errors.field}>
                  <SearchableSelect
                    value={field}
                    displayLabel={fieldLabel}
                    placeholder="— Pilih Bidang Studi —"
                    error={errors.field}
                    fetchOptions={fetchFieldOptions}
                    onSelect={(opt) => {
                      setField(opt?.value ?? '')
                      setFieldLabel(opt?.label ?? '')
                    }}
                  />
                </Field>

                <Field label="Kompetensi Inti" hint="Ketik lalu tekan Enter untuk menambah.">
                  <TagInput
                    value={coreCompetencies}
                    onChange={setCoreCompetencies}
                    placeholder="cth. Problem Solving, Teamwork..."
                  />
                </Field>

                <Field label="Deskripsi">
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Deskripsi singkat tentang kursus ini..."
                    className={formStyles.input}
                    rows={4}
                    style={{ resize: 'vertical' }}
                  />
                </Field>

                <Field label="URL Supporting App" hint="Opsional. Link ke aplikasi pendukung (contoh: app-entrepreneur).">
                  <input
                    type="url"
                    value={supportingAppUrl}
                    onChange={(e) => setSupportingAppUrl(e.target.value)}
                    placeholder="https://..."
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
              {sidebarContent}
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate(isEdit ? `/course/${courseId}` : '/course')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
