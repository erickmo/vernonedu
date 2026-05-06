import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { FolderTree, Calendar, Clock } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { courseVersionService } from '@/services/course-version.service'
import { apiClient } from '@/services/api.client'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

function formatDate(ts: number | undefined) {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(ts * 1000))
}

export default function VersionFormPage() {
  const navigate = useNavigate()
  const { courseId, versionId } = useParams<{ courseId: string; versionId?: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(versionId)

  const [versionNumber, setVersionNumber] = useState('')
  const [description, setDescription] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: version } = useQuery({
    queryKey: ['course-version', versionId],
    queryFn: () => courseVersionService.getById(versionId!),
    enabled: isEdit,
  })


  useEffect(() => {
    if (version) {
      setVersionNumber(version.version_number ?? '')
      setDescription(version.description ?? '')
    }
  }, [version])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!versionNumber.trim()) e.version_number = 'Nomor versi wajib diisi'
    else if (!/^[0-9]+\.[0-9]+$/.test(versionNumber.trim())) {
      e.version_number = 'Format: X.Y (cth. 1.0)'
    }
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
        version_number: versionNumber.trim(),
        description: description.trim(),
        course_id: courseId,
      }
      if (isEdit) {
        await apiClient.put<any>(`/curriculum/versions/${versionId}`, payload)
        toast.success('Versi silabus berhasil diperbarui')
      } else {
        await apiClient.post<any>(`/curriculum/versions`, payload)
        toast.success('Versi silabus berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['course-versions', courseId] })
      navigate(`/course/${courseId}/versions`)
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const sidebarContent = (
    <FormColumn>
      {isEdit && version && (
        <Field label="Informasi">
          <div style={{
            padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            display: 'flex', flexDirection: 'column', gap: 'var(--space-3)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Calendar size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Dibuat</span>
              <span style={{ fontWeight: 500 }}>{formatDate(version.created_at)}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Clock size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Diperbarui</span>
              <span style={{ fontWeight: 500 }}>{formatDate(version.updated_at)}</span>
            </div>
            <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
              Status: {version.is_approved ? 'Disetujui' : 'Draft'}
            </div>
          </div>
        </Field>
      )}
      {!isEdit && (
        <Field label="Catatan">
          <div style={{
            padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
          }}>
            <p style={{
              fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)',
              lineHeight: 1.6, margin: 0,
            }}>
              Versi silabus yang dibuat akan berstatus <strong>Draft</strong>.
              Anda perlu mengajukan persetujuan ke Kepala Departemen sebelum bisa digunakan dalam batch kelas.
            </p>
          </div>
        </Field>
      )}
    </FormColumn>
  )

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Versi Silabus' : 'Tambah Versi Silabus'}
      icon={<FolderTree size={20} />}
      onBack={() => navigate(`/course/${courseId}/versions`)}
      backLabel="Kembali ke Daftar Versi"
      tabs={[
        {
          id: 'general',
          label: 'Informasi Umum',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nomor Versi" required error={errors.version_number} hint="Format: X.Y (cth. 1.0, 2.1)">
                  <input
                    type="text"
                    value={versionNumber}
                    onChange={(e) => setVersionNumber(e.target.value)}
                    placeholder="cth. 1.0"
                    className={`${formStyles.input} ${errors.version_number ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field label="Deskripsi" hint="Opsional. Jelaskan perubahan atau cakupan versi ini.">
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Jelaskan perubahan pada versi ini..."
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
      onCancel={() => navigate(`/course/${courseId}/versions`)}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
