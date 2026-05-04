import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { BookOpen, Calendar, Clock } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
  Toggle,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { courseService } from '@/services/course.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

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

  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [departmentId, setDepartmentId] = useState('')
  const [courseTypeId, setCourseTypeId] = useState('')
  const [isActive, setIsActive] = useState(true)
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
      setName(course.name ?? '')
      setDescription(course.description ?? '')
      setDepartmentId(course.department_id ?? '')
      setCourseTypeId(course.course_type_id ?? '')
      setIsActive(course.is_active ?? true)
    }
  }, [course])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama kursus wajib diisi'
    else if (name.trim().length < 2) e.name = 'Minimal 2 karakter'
    if (!departmentId.trim()) e.department_id = 'Departemen wajib diisi'
    if (!courseTypeId.trim()) e.course_type_id = 'Tipe kursus wajib diisi'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')

    try {
      const payload = {
        name: name.trim(),
        description: description.trim(),
        department_id: departmentId.trim(),
        course_type_id: courseTypeId.trim(),
        is_active: isActive,
      }
      if (isEdit) {
        await courseService.update(courseId!, payload)
        toast.success('Kursus berhasil diperbarui')
      } else {
        await courseService.create(payload)
        toast.success('Kursus berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['courses'] })
      navigate('/curriculum')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const sidebarContent = (
    <FormColumn>
      <Field label="Status Kursus">
        <div style={{
          padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
        }}>
          <Toggle
            checked={isActive}
            onChange={setIsActive}
            label={isActive ? 'Aktif — tampil di kurikulum' : 'Nonaktif — tersembunyi'}
          />
          <p style={{
            fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)',
            marginTop: 'var(--space-2)', lineHeight: 1.5,
          }}>
            Kursus nonaktif tidak akan muncul saat membuat batch kelas baru.
          </p>
        </div>
      </Field>

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
            <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
              Total versi: {course.version_count ?? 0}
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
      onBack={() => navigate('/curriculum')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Umum',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Kursus" required error={errors.name}>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="cth. Web Development Fundamentals"
                    className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field label="Departemen" required error={errors.department_id}>
                  <input
                    type="text"
                    value={departmentId}
                    onChange={(e) => setDepartmentId(e.target.value)}
                    placeholder="Masukkan ID departemen"
                    className={`${formStyles.input} ${errors.department_id ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Tipe Kursus" required error={errors.course_type_id}>
                  <input
                    type="text"
                    value={courseTypeId}
                    onChange={(e) => setCourseTypeId(e.target.value)}
                    placeholder="Masukkan ID tipe kursus"
                    className={`${formStyles.input} ${errors.course_type_id ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Deskripsi" hint="Opsional. Jelaskan konten dan cakupan kursus ini.">
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Jelaskan konten kursus ini..."
                    rows={5}
                    className={formStyles.textarea}
                  />
                  <span style={{
                    fontSize: 'var(--font-min)', color: 'var(--color-text-tertiary)',
                    textAlign: 'right', display: 'block', marginTop: 2,
                  }}>
                    {description.length} karakter
                  </span>
                </Field>
              </FormColumn>
              {sidebarContent}
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/curriculum')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
