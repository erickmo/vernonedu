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
import { toast } from '@/widgets/Toast/Toast'
import { courseService } from '@/services/course.service'
import { departmentService } from '@/services/department.service'
import { userService } from '@/services/user.service'
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
  const [departmentId, setDepartmentId] = useState('')
  const [courseCreatorId, setCourseCreatorId] = useState('')
  const [basePrice, setBasePrice] = useState('')
  const [minPrice, setMinPrice] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: course } = useQuery({
    queryKey: ['course', courseId],
    queryFn: () => courseService.getById(courseId!),
    enabled: isEdit,
  })

  const { data: departmentsData, isLoading: loadingDepts } = useQuery({
    queryKey: ['departments', 'all'],
    queryFn: () => departmentService.list({ limit: 999 } as any),
  })

  const { data: creatorsData, isLoading: loadingCreators } = useQuery({
    queryKey: ['users', 'course_creator'],
    queryFn: () => userService.list({ role: 'course_creator', limit: 999 }),
  })

  useEffect(() => {
    if (course) {
      setName(course.name ?? '')
      setDepartmentId(course.department_id ?? '')
      setCourseCreatorId(course.course_creator_id ?? '')
      setBasePrice(course.base_price != null ? String(course.base_price) : '')
      setMinPrice(course.min_price != null ? String(course.min_price) : '')
    }
  }, [course])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama kursus wajib diisi'
    else if (name.trim().length < 2) e.name = 'Minimal 2 karakter'
    if (!departmentId) e.department_id = 'Departemen wajib diisi'
    if (!courseCreatorId) e.course_creator_id = 'Course Creator wajib diisi'
    const bp = parseFloat(basePrice)
    if (basePrice === '' || isNaN(bp)) e.base_price = 'Harga dasar wajib diisi'
    else if (bp < 0) e.base_price = 'Harga dasar tidak boleh negatif'
    const mp = parseFloat(minPrice)
    if (minPrice === '' || isNaN(mp)) e.min_price = 'Harga minimum wajib diisi'
    else if (mp < 0) e.min_price = 'Harga minimum tidak boleh negatif'
    else if (!isNaN(bp) && mp > bp) e.min_price = 'Harga minimum tidak boleh melebihi harga dasar'
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
        department_id: departmentId,
        course_creator_id: courseCreatorId,
        base_price: parseFloat(basePrice),
        min_price: parseFloat(minPrice),
      }
      if (isEdit) {
        await courseService.update(courseId!, payload)
        toast.success('Kursus berhasil diperbarui')
      } else {
        await courseService.create(payload)
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

  const departments = (departmentsData as any)?.items ?? (departmentsData as any)?.data ?? []
  const creators = (creatorsData as any)?.data ?? []

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
                  <select
                    value={departmentId}
                    onChange={(e) => setDepartmentId(e.target.value)}
                    className={`${formStyles.input} ${errors.department_id ? formStyles.inputError : ''}`}
                    disabled={loadingDepts}
                  >
                    <option value="">
                      {loadingDepts ? 'Memuat...' : '— Pilih Departemen —'}
                    </option>
                    {(departments as any[]).map((dept: any) => (
                      <option key={dept.id} value={dept.id}>
                        {dept.name}
                      </option>
                    ))}
                  </select>
                </Field>

                <Field label="Course Creator" required error={errors.course_creator_id}>
                  <select
                    value={courseCreatorId}
                    onChange={(e) => setCourseCreatorId(e.target.value)}
                    className={`${formStyles.input} ${errors.course_creator_id ? formStyles.inputError : ''}`}
                    disabled={loadingCreators}
                  >
                    <option value="">
                      {loadingCreators ? 'Memuat...' : '— Pilih Course Creator —'}
                    </option>
                    {(creators as any[]).map((user: any) => (
                      <option key={user.id} value={user.id}>
                        {user.name}
                      </option>
                    ))}
                  </select>
                </Field>

                <Field label="Harga Dasar" required error={errors.base_price}>
                  <div style={{ display: 'flex', alignItems: 'center' }}>
                    <span style={{
                      padding: '0 var(--space-3)',
                      background: 'var(--color-surface-elevated)',
                      border: '1px solid var(--color-border)',
                      borderRight: 'none',
                      borderRadius: 'var(--radius-md) 0 0 var(--radius-md)',
                      fontSize: 'var(--font-sm)',
                      color: 'var(--color-text-secondary)',
                      height: '36px',
                      display: 'flex',
                      alignItems: 'center',
                    }}>
                      Rp
                    </span>
                    <input
                      type="number"
                      min="0"
                      step="1000"
                      value={basePrice}
                      onChange={(e) => setBasePrice(e.target.value)}
                      placeholder="0"
                      className={`${formStyles.input} ${errors.base_price ? formStyles.inputError : ''}`}
                      style={{ borderRadius: '0 var(--radius-md) var(--radius-md) 0', flex: 1 }}
                    />
                  </div>
                </Field>

                <Field label="Harga Minimum" required error={errors.min_price} hint="Harga batch tidak boleh di bawah nilai ini.">
                  <div style={{ display: 'flex', alignItems: 'center' }}>
                    <span style={{
                      padding: '0 var(--space-3)',
                      background: 'var(--color-surface-elevated)',
                      border: '1px solid var(--color-border)',
                      borderRight: 'none',
                      borderRadius: 'var(--radius-md) 0 0 var(--radius-md)',
                      fontSize: 'var(--font-sm)',
                      color: 'var(--color-text-secondary)',
                      height: '36px',
                      display: 'flex',
                      alignItems: 'center',
                    }}>
                      Rp
                    </span>
                    <input
                      type="number"
                      min="0"
                      step="1000"
                      value={minPrice}
                      onChange={(e) => setMinPrice(e.target.value)}
                      placeholder="0"
                      className={`${formStyles.input} ${errors.min_price ? formStyles.inputError : ''}`}
                      style={{ borderRadius: '0 var(--radius-md) var(--radius-md) 0', flex: 1 }}
                    />
                  </div>
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
