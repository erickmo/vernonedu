import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Tag } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { leadSourceService } from '@/services/lead-source.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

export default function LeadSourceFormPage() {
  const navigate = useNavigate()
  const { sourceId } = useParams<{ sourceId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(sourceId)

  const [name, setName] = useState('')
  const [isActive, setIsActive] = useState(true)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: source } = useQuery({
    queryKey: ['lead-source', sourceId],
    queryFn: async () => {
      const all = await leadSourceService.list()
      return all.find(s => s.id === sourceId) ?? null
    },
    enabled: isEdit,
  })

  useEffect(() => {
    if (source) {
      setName(source.name ?? '')
      setIsActive(source.is_active ?? true)
    }
  }, [source])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama wajib diisi'
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
        await leadSourceService.update(sourceId!, { name: name.trim(), is_active: isActive })
        toast.success('Sumber lead berhasil diperbarui')
      } else {
        await leadSourceService.create({ name: name.trim() })
        toast.success('Sumber lead berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['lead-sources'] })
      navigate('/settings/lead-sources')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Sumber Lead' : 'Tambah Sumber Lead'}
      icon={<Tag size={20} />}
      onBack={() => navigate('/settings/lead-sources')}
      tabs={[{
        id: 'general',
        label: 'Informasi',
        content: (
          <FormGrid>
            <FormColumn>
              <Field label="Nama Sumber" required error={errors.name}>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="cth. Referral, Website"
                  className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                  autoFocus
                />
              </Field>
              {isEdit && (
                <Field label="Status">
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                    <input
                      type="checkbox"
                      checked={isActive}
                      onChange={(e) => setIsActive(e.target.checked)}
                    />
                    <span>Aktif</span>
                  </label>
                </Field>
              )}
            </FormColumn>
          </FormGrid>
        ),
      }]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/settings/lead-sources')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
