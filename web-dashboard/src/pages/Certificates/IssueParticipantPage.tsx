import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Award } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
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

export default function IssueParticipantPage() {
  const navigate = useNavigate()
  const { enrollmentId } = useParams<{ enrollmentId: string }>()
  const queryClient = useQueryClient()

  const [enrollmentIdField, setEnrollmentIdField] = useState(enrollmentId ?? '')
  const [batchId, setBatchId] = useState('')
  const [studentName, setStudentName] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!enrollmentIdField.trim()) e.enrollment_id = 'ID Pendaftaran wajib diisi'
    if (!batchId.trim()) e.batch_id = 'ID Batch wajib diisi'
    if (!studentName.trim()) e.student_name = 'Nama Siswa wajib diisi'
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
        enrollment_id: enrollmentIdField.trim(),
        batch_id: batchId.trim(),
        student_name: studentName.trim(),
      }
      await certificateService.issueParticipant(payload)
      toast.success('Sertifikat Peserta berhasil diterbitkan')
      await queryClient.invalidateQueries({ queryKey: [QK.certificates] })
      navigate('/certificates')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menerbitkan sertifikat')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title="Terbitkan Sertifikat Peserta"
      icon={<Award size={20} />}
      onBack={() => navigate('/certificates')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Sertifikat',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="ID Pendaftaran" required error={errors.enrollment_id}>
                  <input
                    type="text"
                    value={enrollmentIdField}
                    onChange={(e) => setEnrollmentIdField(e.target.value)}
                    placeholder="cth. ENR-2026-001"
                    className={`${formStyles.input} ${errors.enrollment_id ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field label="ID Batch" required error={errors.batch_id}>
                  <input
                    type="text"
                    value={batchId}
                    onChange={(e) => setBatchId(e.target.value)}
                    placeholder="cth. BTC-2026-001"
                    className={`${formStyles.input} ${errors.batch_id ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Nama Siswa" required error={errors.student_name} hint="Untuk verifikasi dan konfirmasi">
                  <input
                    type="text"
                    value={studentName}
                    onChange={(e) => setStudentName(e.target.value)}
                    placeholder="Nama lengkap siswa"
                    className={`${formStyles.input} ${errors.student_name ? formStyles.inputError : ''}`}
                  />
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Informasi">
                  <div style={{
                    padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
                    border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
                    fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', lineHeight: 1.6,
                  }}>
                    Sertifikat Peserta diterbitkan untuk siswa yang telah menyelesaikan seluruh rangkaian kursus pada batch tertentu.
                    Pastikan data pendaftaran dan batch sudah benar sebelum menerbitkan.
                  </div>
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/certificates')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
