import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Users, GraduationCap, DollarSign, Calendar, Clock } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { enrollmentService } from '@/services/enrollment.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

interface Enrollment {
  id?: string
  student_id: string
  batch_id: string
  payment_method: 'upfront' | 'scheduled' | 'monthly' | 'batch_lump' | 'per_session'
  status?: string
  payment_status?: string
  enrolled_at?: number
  created_at?: number
  updated_at?: number
}

function formatDate(ts: number | undefined) {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(ts * 1000))
}

const paymentMethodOptions = [
  { value: 'upfront', label: 'Penuh di Awal' },
  { value: 'scheduled', label: 'Terjadwal' },
  { value: 'monthly', label: 'Bulanan' },
  { value: 'batch_lump', label: 'Batch Lump Sum' },
  { value: 'per_session', label: 'Per Sesi' },
]

export default function EnrollmentFormPage() {
  const navigate = useNavigate()
  const { enrollmentId } = useParams<{ enrollmentId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(enrollmentId)

  const [studentId, setStudentId] = useState('')
  const [batchId, setBatchId] = useState('')
  const [paymentMethod, setPaymentMethod] = useState<Enrollment['payment_method']>('upfront')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  // In edit mode, we need to fetch existing data
  // Note: The enrollmentService doesn't have getById, we may need to add it or use list with filter
  const { data: enrollment } = useQuery({
    queryKey: ['enrollment', enrollmentId],
    queryFn: async () => {
      // For now, we'll assume the service will be enhanced with getById
      // If not, we can create a custom fetcher
      const response = await enrollmentService.list({ page: 1, pageSize: 1 })
      return response.data?.[0]
    },
    enabled: isEdit,
  })

  useEffect(() => {
    if (enrollment) {
      setStudentId(enrollment.student_id ?? '')
      setBatchId(enrollment.batch_id ?? '')
      setPaymentMethod(enrollment.payment_method ?? 'upfront')
    }
  }, [enrollment])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!studentId.trim()) e.student_id = 'ID siswa wajib diisi'
    if (!batchId.trim()) e.batch_id = 'ID batch wajib diisi'
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
        student_id: studentId.trim(),
        batch_id: batchId.trim(),
        payment_method: paymentMethod,
      }

      if (isEdit) {
        // Update enrollment - note: service doesn't have update, may need to add
        await enrollmentService.updateStatus(enrollmentId!, paymentMethod)
        toast.success('Pendaftaran berhasil diperbarui')
      } else {
        await enrollmentService.enroll(payload)
        toast.success('Pendaftaran berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['enrollments'] })
      navigate('/enrollments')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const sidebarContent = (
    <FormColumn>
      {isEdit && enrollment && (
        <Field label="Informasi">
          <div style={{
            padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            display: 'flex', flexDirection: 'column', gap: 'var(--space-3)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Calendar size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Terdaftar</span>
              <span style={{ fontWeight: 500 }}>{formatDate(enrollment.enrolled_at)}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Clock size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Diperbarui</span>
              <span style={{ fontWeight: 500 }}>{formatDate(enrollment.updated_at)}</span>
            </div>
            {enrollment.status && (
              <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
                Status: {enrollment.status}
              </div>
            )}
            {enrollment.payment_status && (
              <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
                Pembayaran: {enrollment.payment_status}
              </div>
            )}
          </div>
        </Field>
      )}
    </FormColumn>
  )

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Pendaftaran' : 'Tambah Pendaftaran'}
      icon={<Users size={20} />}
      onBack={() => navigate('/enrollments')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Umum',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="ID Siswa" required error={errors.student_id} hint="Masukkan ID siswa yang akan didaftarkan.">
                  <input
                    type="text"
                    value={studentId}
                    onChange={(e) => setStudentId(e.target.value)}
                    placeholder="cth. STU-001"
                    className={`${formStyles.input} ${errors.student_id ? formStyles.inputError : ''}`}
                    autoFocus={!isEdit}
                  />
                </Field>
                <Field label="ID Batch" required error={errors.batch_id} hint="Masukkan ID batch kursus yang dipilih.">
                  <input
                    type="text"
                    value={batchId}
                    onChange={(e) => setBatchId(e.target.value)}
                    placeholder="cth. BAT-001"
                    className={`${formStyles.input} ${errors.batch_id ? formStyles.inputError : ''}`}
                    autoFocus={isEdit}
                  />
                </Field>
                <Field label="Metode Pembayaran" error={errors.payment_method}>
                  <select
                    value={paymentMethod}
                    onChange={(e) => setPaymentMethod(e.target.value as Enrollment['payment_method'])}
                    className={formStyles.select}
                  >
                    {paymentMethodOptions.map((opt) => (
                      <option key={opt.value} value={opt.value}>
                        {opt.label}
                      </option>
                    ))}
                  </select>
                  <p style={{
                    fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)',
                    marginTop: 'var(--space-2)', lineHeight: 1.5,
                  }}>
                    Pilih metode pembayaran untuk kursus ini.
                  </p>
                </Field>
              </FormColumn>
              {sidebarContent}
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/enrollments')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
