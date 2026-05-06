import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { User, X, Plus } from 'lucide-react'
import { useQuery, useQueryClient, useMutation } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { SearchableSelect } from '@/widgets/SearchableSelect/SearchableSelect'
import { leadService } from '@/services/lead.service'
import { leadSourceService } from '@/services/lead-source.service'
import { apiClient } from '@/services/api.client'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const ENTITY_TYPES = [
  { value: 'master_course', label: 'Master Course' },
  { value: 'course_type', label: 'Course Type' },
  { value: 'course_batch', label: 'Batch' },
]

const STATUS_OPTIONS = [
  { value: 'new', label: 'Baru' },
  { value: 'contacted', label: 'Dihubungi' },
  { value: 'interested', label: 'Tertarik' },
  { value: 'negotiating', label: 'Negosiasi' },
  { value: 'enrolled', label: 'Terdaftar' },
  { value: 'not_interested', label: 'Tidak Tertarik' },
]

const ENTITY_TYPE_LABELS: Record<string, string> = {
  master_course: 'Master Course',
  course_type: 'Course Type',
  course_batch: 'Batch',
}

export default function LeadFormPage() {
  const navigate = useNavigate()
  const { leadId } = useParams<{ leadId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(leadId)

  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [sourceId, setSourceId] = useState('')
  const [status, setStatus] = useState('new')
  const [notes, setNotes] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const [interestEntityType, setInterestEntityType] = useState('master_course')
  const [interestEntityId, setInterestEntityId] = useState('')

  const { data: lead } = useQuery({
    queryKey: ['lead', leadId],
    queryFn: () => leadService.getById(leadId!),
    enabled: isEdit,
  })

  const { data: sources = [] } = useQuery({
    queryKey: ['lead-sources'],
    queryFn: () => leadSourceService.list().then((r) => r.items),
  })

  const activeSources = sources.filter((s) => s.is_active)

  const { data: masterCourses = [] } = useQuery({
    queryKey: ['master-courses-simple'],
    queryFn: () =>
      apiClient.get<any>('master-courses?limit=200').then((r: any) => {
        const d = r?.data ?? r
        return Array.isArray(d?.data) ? d.data : Array.isArray(d) ? d : []
      }),
    enabled: isEdit,
  })

  const { data: courseTypes = [] } = useQuery({
    queryKey: ['course-types-simple'],
    queryFn: () =>
      apiClient.get<any>('course-types?limit=200').then((r: any) => {
        const d = r?.data ?? r
        return Array.isArray(d?.data) ? d.data : Array.isArray(d) ? d : []
      }),
    enabled: isEdit,
  })

  const { data: courseBatches = [] } = useQuery({
    queryKey: ['course-batches-simple'],
    queryFn: () =>
      apiClient.get<any>('course-batches?limit=200').then((r: any) => {
        const d = r?.data ?? r
        return Array.isArray(d?.data) ? d.data : Array.isArray(d) ? d : []
      }),
    enabled: isEdit,
  })

  useEffect(() => {
    if (lead) {
      setName((lead as any).name ?? '')
      setEmail((lead as any).email ?? '')
      setPhone((lead as any).phone ?? '')
      setSourceId((lead as any).source?.id ?? '')
      setStatus((lead as any).status ?? 'new')
      setNotes((lead as any).notes ?? '')
    }
  }, [lead])

  const interests: any[] = (lead as any)?.interests ?? []

  const addInterestMutation = useMutation({
    mutationFn: () =>
      leadService.addInterest(leadId!, {
        entity_type: interestEntityType,
        entity_id: interestEntityId,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lead', leadId] })
      setInterestEntityId('')
      toast.success('Minat ditambahkan')
    },
    onError: () => toast.error('Gagal menambah minat'),
  })

  const removeInterestMutation = useMutation({
    mutationFn: (interestId: string) => leadService.removeInterest(leadId!, interestId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lead', leadId] })
      toast.success('Minat dihapus')
    },
    onError: () => toast.error('Gagal menghapus minat'),
  })

  function getEntityOptions(): Array<{ value: string; label: string }> {
    if (interestEntityType === 'master_course') {
      return (masterCourses as any[]).map((c: any) => ({
        value: c.id,
        label: c.course_name ?? c.name ?? c.id,
      }))
    }
    if (interestEntityType === 'course_type') {
      return (courseTypes as any[]).map((c: any) => ({
        value: c.id,
        label: c.type_name ?? c.name ?? c.id,
      }))
    }
    return (courseBatches as any[]).map((c: any) => ({
      value: c.id,
      label: c.name ?? c.id,
    }))
  }

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama wajib diisi'
    else if (name.trim().length < 2) e.name = 'Minimal 2 karakter'
    if (!phone.trim()) e.phone = 'Telepon wajib diisi'
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
      e.email = 'Format email tidak valid'
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
        phone: phone.trim(),
        email: email.trim() || undefined,
        source_id: sourceId || undefined,
        notes: notes.trim() || undefined,
        ...(isEdit && { status }),
      }
      if (isEdit) {
        await leadService.update(leadId!, payload)
        toast.success('Lead berhasil diperbarui')
      } else {
        await leadService.create(payload)
        toast.success('Lead berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['leads'] })
      navigate(isEdit ? `/leads/${leadId}` : '/leads')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const interestsSection = isEdit ? (
    <FormColumn style={{ gridColumn: '1 / -1' }}>
      <Field label="Minat" hint="Kursus atau batch yang diminati lead ini.">
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 12 }}>
          {interests.length === 0 && (
            <span
              style={{
                color: 'var(--color-text-tertiary)',
                fontSize: 'var(--font-sm)',
              }}
            >
              Belum ada minat
            </span>
          )}
          {interests.map((i: any) => (
            <span
              key={i.id}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 6,
                padding: '4px 10px',
                borderRadius: 'var(--radius-full)',
                background: 'var(--color-primary-subtle)',
                color: 'var(--color-primary)',
                fontSize: 'var(--font-xs)',
                fontWeight: 600,
              }}
            >
              <span style={{ opacity: 0.7 }}>
                [{ENTITY_TYPE_LABELS[i.entity_type] ?? i.entity_type}]
              </span>
              {i.entity_name ?? i.entity_id}
              <button
                type="button"
                onClick={() => removeInterestMutation.mutate(i.id)}
                style={{
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  padding: 0,
                  lineHeight: 1,
                  color: 'inherit',
                }}
              >
                <X size={12} />
              </button>
            </span>
          ))}
        </div>
        <div
          style={{
            display: 'flex',
            gap: 8,
            alignItems: 'center',
            flexWrap: 'wrap',
          }}
        >
          <div style={{ width: 150 }}>
            <SearchableSelect
              value={interestEntityType}
              displayLabel={ENTITY_TYPES.find((t) => t.value === interestEntityType)?.label ?? ''}
              placeholder="Tipe"
              fetchOptions={(search) => Promise.resolve(
                ENTITY_TYPES
                  .filter((t) => t.label.toLowerCase().includes(search.toLowerCase()))
                  .map((t) => ({ value: t.value, label: t.label }))
              )}
              onSelect={(opt) => {
                setInterestEntityType(opt?.value ?? 'master_course')
                setInterestEntityId('')
              }}
            />
          </div>
          <div style={{ flex: 1, minWidth: 200 }}>
            <SearchableSelect
              value={interestEntityId}
              displayLabel={getEntityOptions().find((o) => o.value === interestEntityId)?.label ?? ''}
              placeholder="Pilih..."
              fetchOptions={(search) => Promise.resolve(
                getEntityOptions()
                  .filter((o) => o.label.toLowerCase().includes(search.toLowerCase()))
                  .map((o) => ({ value: o.value, label: o.label }))
              )}
              onSelect={(opt) => setInterestEntityId(opt?.value ?? '')}
            />
          </div>
          <button
            type="button"
            onClick={() => interestEntityId && addInterestMutation.mutate()}
            disabled={!interestEntityId || addInterestMutation.isPending}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 4,
              padding: '6px 14px',
              borderRadius: 'var(--radius-md)',
              background: 'var(--color-primary)',
              color: '#fff',
              border: 'none',
              cursor: 'pointer',
              fontSize: 'var(--font-sm)',
              fontWeight: 600,
              opacity: !interestEntityId || addInterestMutation.isPending ? 0.5 : 1,
            }}
          >
            <Plus size={14} /> Tambah
          </button>
        </div>
      </Field>
    </FormColumn>
  ) : null

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Lead' : 'Tambah Lead'}
      icon={<User size={20} />}
      onBack={() => navigate(isEdit ? `/leads/${leadId}` : '/leads')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Utama',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama" required error={errors.name}>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Nama lengkap prospek"
                    className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field
                  label="Telepon"
                  required
                  error={errors.phone}
                  hint="Digunakan untuk menghubungi prospek."
                >
                  <input
                    type="tel"
                    inputMode="numeric"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value.replace(/[^0-9+]/g, ''))}
                    placeholder="+62 xxx xxxx xxxx"
                    className={`${formStyles.input} ${errors.phone ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Email" error={errors.email} hint="Opsional.">
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="contoh@email.com"
                    className={`${formStyles.input} ${errors.email ? formStyles.inputError : ''}`}
                  />
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Sumber" hint="Dari mana prospek mengetahui layanan kami.">
                  <SearchableSelect
                    value={sourceId}
                    displayLabel={activeSources.find((s) => s.id === sourceId)?.name ?? ''}
                    placeholder="— Pilih Sumber —"
                    fetchOptions={(search) => Promise.resolve(
                      activeSources
                        .filter((s) => s.name.toLowerCase().includes(search.toLowerCase()))
                        .map((s) => ({ value: s.id, label: s.name }))
                    )}
                    onSelect={(opt) => setSourceId(opt?.value ?? '')}
                  />
                </Field>
                {isEdit && (
                  <Field label="Status" hint="Tahap prospek saat ini.">
                    <SearchableSelect
                      value={status}
                      displayLabel={STATUS_OPTIONS.find((o) => o.value === status)?.label ?? ''}
                      placeholder="— Pilih Status —"
                      fetchOptions={(search) => Promise.resolve(
                        STATUS_OPTIONS
                          .filter((o) => o.label.toLowerCase().includes(search.toLowerCase()))
                          .map((o) => ({ value: o.value, label: o.label }))
                      )}
                      onSelect={(opt) => setStatus(opt?.value ?? 'new')}
                    />
                  </Field>
                )}
              </FormColumn>
              {interestsSection}
              <FormColumn style={{ gridColumn: '1 / -1' }}>
                <Field label="Catatan" hint="Opsional.">
                  <textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Catatan tambahan..."
                    rows={5}
                    className={formStyles.textarea}
                  />
                  <span
                    style={{
                      fontSize: 'var(--font-min)',
                      color: 'var(--color-text-tertiary)',
                      textAlign: 'right',
                      display: 'block',
                      marginTop: 2,
                    }}
                  >
                    {notes.length} karakter
                  </span>
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate(isEdit ? `/leads/${leadId}` : '/leads')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
