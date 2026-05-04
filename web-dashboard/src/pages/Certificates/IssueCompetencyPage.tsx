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

export default function IssueCompetencyPage() {
  const navigate = useNavigate()
  useParams<{ enrollmentId: string }>()
  const queryClient = useQueryClient()

  const [studentId, setStudentId] = useState('')
  const [studentName, setStudentName] = useState('')
  const [testScore, setTestScore] = useState('')
  const [notes, setNotes] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!studentId.trim()) e.student_id = 'ID Siswa wajib diisi'
    if (!studentName.trim()) e.student_name = 'Nama Siswa wajib diisi'
    const score = Number(testScore)
    if (!testScore.trim()) e.test_score = 'Nilai Tes wajib diisi'
    else if (isNaN(score) || score < 0 || score > 100) e.test_score = 'Nilai harus antara 0–100'
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
        student_id: studentId.trim(),
        student_name: studentName.trim(),
        test_score: Number(testScore),
        notes: notes.trim(),
      }
      await certificateService.issueCompetency(payload)
      toast.success('Sertifikat Kompetensi berhasil diterbitkan')
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
      title="Terbitkan Sertifikat Kompetensi"
      icon={<Award size={20} />}
      onBack={() => navigate('/certificates')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Sertifikat',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="ID Siswa" required error={errors.student_id}>
                  <input
                    type="text"
                    value={studentId}
                    onChange={(e) => setStudentId(e.target.value)}
                    placeholder="cth. STD-2026-001"
                    className={`${formStyles.input} ${errors.student_id ? formStyles.inputError : ''}`}
                    autoFocus
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
                <Field label="Nilai Tes" required error={errors.test_score} hint="Rentang nilai: 0–100">
                  <input
                    type="number"
                    value={testScore}
                    onChange={(e) => setTestScore(e.target.value)}
                    placeholder="cth. 85"
                    min={0}
                    max={100}
                    className={`${formStyles.input} ${errors.test_score ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Catatan" hint="Opsional. Catatan tambahan terkait hasil tes.">
                  <textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Catatan tambahan..."
                    rows={4}
                    className={formStyles.textarea}
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
                    Sertifikat Kompetensi diterbitkan untuk siswa yang telah lulus tes kompetensi.
                    Sertifikat ini juga dapat diterbitkan untuk peserta non-terdaftar jika memenuhi kriteria.
                    Nilai tes akan tercantum dalam sertifikat.
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
