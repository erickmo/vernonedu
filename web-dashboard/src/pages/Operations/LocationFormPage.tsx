import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Building2, DoorOpen, Calendar, Clock } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { locationService } from '@/services/location.service'
import { RoomsManager } from './RoomsManager'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

function formatDate(ts: number | undefined) {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(ts * 1000))
}

export default function LocationFormPage() {
  const navigate = useNavigate()
  const { buildingId } = useParams<{ buildingId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(buildingId)

  const [name, setName] = useState('')
  const [address, setAddress] = useState('')
  const [description, setDescription] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: building } = useQuery({
    queryKey: ['building', buildingId],
    queryFn: () => locationService.getBuilding(buildingId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (building) {
      setName((building as any).name ?? '')
      setAddress((building as any).address ?? '')
      setDescription((building as any).description ?? '')
    }
  }, [building])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama gedung wajib diisi'
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
      const payload = {
        name: name.trim(),
        address: address.trim(),
        description: description.trim(),
      }
      if (isEdit) {
        await locationService.updateBuilding(buildingId!, payload)
        toast.success('Gedung berhasil diperbarui')
        await queryClient.invalidateQueries({ queryKey: ['locations/buildings'] })
        navigate(`/pengembangan/locations/${buildingId}`)
      } else {
        const res = await locationService.createBuilding(payload)
        toast.success('Gedung berhasil dibuat — tambahkan ruangan di tab Ruangan')
        await queryClient.invalidateQueries({ queryKey: ['locations/buildings'] })
        navigate(`/pengembangan/locations/${res.id}/edit`)
      }
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const b = building as any

  const sidebarContent = (
    <FormColumn>
      {isEdit && b && (
        <Field label="Informasi">
          <div style={{
            padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            display: 'flex', flexDirection: 'column', gap: 'var(--space-3)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Calendar size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Dibuat</span>
              <span style={{ fontWeight: 500 }}>{formatDate(b.created_at)}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Clock size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Diperbarui</span>
              <span style={{ fontWeight: 500 }}>{formatDate(b.updated_at)}</span>
            </div>
          </div>
        </Field>
      )}
    </FormColumn>
  )

  const tabs = [
    {
      id: 'general',
      label: 'Informasi Gedung',
      content: (
        <FormGrid>
          <FormColumn>
            <Field label="Nama Gedung" required error={errors.name}>
              <input
                type="text"
                value={name}
                onChange={e => setName(e.target.value)}
                placeholder="cth. Gedung Utama"
                className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                autoFocus
              />
            </Field>
            <Field label="Alamat" hint="Opsional. Alamat lengkap gedung.">
              <input
                type="text"
                value={address}
                onChange={e => setAddress(e.target.value)}
                placeholder="cth. Jl. Sudirman No. 1, Jakarta"
                className={formStyles.input}
              />
            </Field>
            <Field label="Deskripsi" hint="Opsional.">
              <textarea
                value={description}
                onChange={e => setDescription(e.target.value)}
                placeholder="Informasi tambahan tentang gedung ini..."
                rows={4}
                className={formStyles.textarea}
              />
            </Field>
          </FormColumn>
          {sidebarContent}
        </FormGrid>
      ),
    },
    ...(isEdit
      ? [{
          id: 'rooms',
          label: 'Ruangan',
          icon: <DoorOpen size={14} />,
          content: <RoomsManager buildingId={buildingId!} />,
        }]
      : []),
  ]

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Gedung' : 'Tambah Gedung'}
      icon={<Building2 size={20} />}
      onBack={() => navigate(isEdit ? `/pengembangan/locations/${buildingId}` : '/pengembangan/locations')}
      tabs={tabs}
      onSubmit={handleSubmit}
      onCancel={() => navigate(isEdit ? `/pengembangan/locations/${buildingId}` : '/pengembangan/locations')}
      isSubmitting={isSubmitting}
      serverError={serverError}
      helpTitle="Lokasi & Gedung"
      helpText="Kelola gedung dan ruangan yang digunakan untuk pelaksanaan kursus. Tab Ruangan tersedia setelah gedung disimpan."
    />
  )
}
