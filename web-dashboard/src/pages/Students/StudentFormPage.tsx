import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { User, Calendar, Clock } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { studentService } from '@/services/student.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

function formatDate(ts: number | undefined) {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(ts * 1000))
}

export default function StudentFormPage() {
  const navigate = useNavigate()
  const { studentId } = useParams<{ studentId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(studentId)

  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: student } = useQuery({
    queryKey: ['student', studentId],
    queryFn: () => studentService.getById(studentId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (student) {
      setName(student.name ?? '')
      setEmail(student.email ?? '')
      setPhone(student.phone ?? '')
    }
  }, [student])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama siswa wajib diisi'
    else if (name.trim().length < 2) e.name = 'Minimal 2 karakter'
    if (!email.trim()) e.email = 'Email wajib diisi'
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) e.email = 'Format email tidak valid'
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
        email: email.trim(),
        phone: phone.trim() || undefined,
      }
      if (isEdit) {
        await studentService.update(studentId!, payload)
        toast.success('Data siswa berhasil diperbarui')
      } else {
        await studentService.create(payload)
        toast.success('Siswa berhasil ditambahkan')
      }
      await queryClient.invalidateQueries({ queryKey: ['students'] })
      navigate(isEdit ? `/students/${studentId}` : '/students')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const sidebarContent = (
    <FormColumn>
      {isEdit && student && (
        <Field label="Informasi">
          <div style={{
            padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            display: 'flex', flexDirection: 'column', gap: 'var(--space-3)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Calendar size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Dibuat</span>
              <span style={{ fontWeight: 500 }}>{formatDate(student.created_at)}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Clock size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Diperbarui</span>
              <span style={{ fontWeight: 500 }}>{formatDate(student.updated_at)}</span>
            </div>
            <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
              {student.is_active ? 'Status: Aktif' : 'Status: Alumni'}
            </div>
          </div>
        </Field>
      )}
    </FormColumn>
  )

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Siswa' : 'Tambah Siswa'}
      icon={<User size={20} />}
      onBack={() => navigate(isEdit ? `/students/${studentId}` : '/students')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Umum',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Siswa" required error={errors.name}>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="cth. Budi Santoso"
                    className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field label="Email" required error={errors.email} hint="Email utama untuk notifikasi dan login.">
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="cth. budi@example.com"
                    className={`${formStyles.input} ${errors.email ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Telepon" hint="Opsional. Nomor HP/WA untuk komunikasi.">
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="cth. 08123456789"
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
      onCancel={() => navigate(isEdit ? `/students/${studentId}` : '/students')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
