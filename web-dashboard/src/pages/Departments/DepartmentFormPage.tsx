import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Building2, Calendar, Clock } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
  Toggle,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { departmentService } from '@/services/department.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

function formatDate(ts: number | undefined) {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(ts * 1000))
}

export default function DepartmentFormPage() {
  const navigate = useNavigate()
  const { deptId } = useParams<{ deptId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(deptId)

  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [isActive, setIsActive] = useState(true)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: dept } = useQuery({
    queryKey: ['department', deptId],
    queryFn: () => departmentService.getById(deptId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (dept) {
      setName(dept.name ?? '')
      setDescription(dept.description ?? '')
      setIsActive(dept.is_active ?? true)
    }
  }, [dept])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama departemen wajib diisi'
    else if (name.trim().length < 2) e.name = 'Minimal 2 karakter'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')

    try {
      const payload = { name: name.trim(), description: description.trim(), is_active: isActive }
      if (isEdit) {
        await departmentService.update(deptId!, payload)
        toast.success('Departemen berhasil diperbarui')
      } else {
        await departmentService.create(payload)
        toast.success('Departemen berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['departments'] })
      navigate('/departments')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const sidebarContent = (
    <FormColumn>
      <Field label="Status Departemen">
        <div style={{
          padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
        }}>
          <Toggle
            checked={isActive}
            onChange={setIsActive}
            label={isActive ? 'Aktif — tampil di kursus' : 'Nonaktif — tersembunyi'}
          />
          <p style={{
            fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)',
            marginTop: 'var(--space-2)', lineHeight: 1.5,
          }}>
            Departemen nonaktif tidak akan muncul saat membuat kursus baru.
          </p>
        </div>
      </Field>

      {isEdit && dept && (
        <Field label="Informasi">
          <div style={{
            padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            display: 'flex', flexDirection: 'column', gap: 'var(--space-3)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Calendar size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Dibuat</span>
              <span style={{ fontWeight: 500 }}>{formatDate(dept.created_at)}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Clock size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Diperbarui</span>
              <span style={{ fontWeight: 500 }}>{formatDate(dept.updated_at)}</span>
            </div>
            {dept.leader_id && (
              <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
                Kepala Dept. ditetapkan melalui menu HRM.
              </div>
            )}
          </div>
        </Field>
      )}
    </FormColumn>
  )

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Departemen' : 'Tambah Departemen'}
      icon={<Building2 size={20} />}
      onBack={() => navigate('/departments')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Umum',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Departemen" required error={errors.name}>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="cth. Department of Technology"
                    className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field label="Deskripsi" hint="Opsional. Jelaskan fokus dan cakupan departemen ini.">
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Jelaskan fokus departemen ini..."
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
      onCancel={() => navigate('/departments')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
