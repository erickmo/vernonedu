import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Briefcase } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FieldRow,
  FieldSection,
} from '@/widgets/FormPageTemplate'
import { SearchableSelect, type SelectOption } from '@/widgets/SearchableSelect/SearchableSelect'
import { TagInput } from '@/widgets/TagInput/TagInput'
import { DatePicker } from '@/widgets/DatePicker/DatePicker'
import { toast } from '@/widgets/Toast/Toast'
import { jobVacancyService } from '@/services/jobvacancy.service'
import { partnerService } from '@/services/partner.service'
import { useAuthStore } from '@/stores/auth.store'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

function formatRupiah(val: string): string {
  if (!val) return ''
  return Number(val).toLocaleString('id-ID')
}

function parseRupiah(displayVal: string): string {
  return displayVal.replace(/\./g, '').replace(/,/g, '').replace(/[^\d]/g, '')
}

// ─── Static option fetchers ────────────────────────────────────────────────────

const TYPE_OPTIONS: SelectOption[] = [
  { value: 'full-time', label: 'Full-time' },
  { value: 'part-time', label: 'Part-time' },
  { value: 'internship', label: 'Magang' },
  { value: 'contract', label: 'Kontrak' },
]

const STATUS_OPTIONS: SelectOption[] = [
  { value: 'draft', label: 'Draft' },
  { value: 'open', label: 'Buka' },
  { value: 'closed', label: 'Tutup' },
]

const EXPERIENCE_OPTIONS: SelectOption[] = [
  { value: 'junior', label: 'Junior' },
  { value: 'mid', label: 'Mid-level' },
  { value: 'senior', label: 'Senior' },
]

function filterStatic(opts: SelectOption[], search: string): Promise<SelectOption[]> {
  const q = search.toLowerCase()
  return Promise.resolve(q ? opts.filter(o => o.label.toLowerCase().includes(q)) : opts)
}

async function fetchPartners(search: string): Promise<SelectOption[]> {
  const res = await partnerService.list(search ? { search, limit: 20 } : { limit: 20 })
  return (res.items ?? []).map((p: Record<string, unknown>) => ({
    value: String(p.id ?? ''),
    label: String(p.name ?? ''),
  }))
}

// ─── Component ────────────────────────────────────────────────────────────────

export default function TalentPoolLowonganFormPage() {
  const { vacancyId } = useParams<{ vacancyId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const isEdit = Boolean(vacancyId)
  const user = useAuthStore(s => s.user)

  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')

  const [partnerId, setPartnerId] = useState('')
  const [partnerLabel, setPartnerLabel] = useState('')

  const [type, setType] = useState('')
  const [typeLabel, setTypeLabel] = useState('')
  const [status, setStatus] = useState('draft')
  const [statusLabel, setStatusLabel] = useState('Draft')
  const [experienceLevel, setExperienceLevel] = useState('')
  const [experienceLevelLabel, setExperienceLevelLabel] = useState('')

  const [location, setLocation] = useState('')
  const [slots, setSlots] = useState('')
  const [minSalary, setMinSalary] = useState('')
  const [maxSalary, setMaxSalary] = useState('')
  const [requiredSkills, setRequiredSkills] = useState<string[]>([])
  const [deadline, setDeadline] = useState('')

  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: vacancy } = useQuery<Record<string, unknown>>({
    queryKey: ['job-vacancy', vacancyId],
    queryFn: () => jobVacancyService.getById(vacancyId!),
    enabled: isEdit,
  })

  const existingPartnerId = vacancy?.partner_id as string | undefined

  const { data: existingPartner } = useQuery({
    queryKey: ['partner', existingPartnerId],
    queryFn: () => partnerService.getById(existingPartnerId!),
    enabled: Boolean(existingPartnerId),
  })

  useEffect(() => {
    if (!vacancy) return
    setTitle(vacancy.title ?? '')
    setDescription(vacancy.description ?? '')
    setPartnerId(vacancy.partner_id ?? '')
    setPartnerLabel(existingPartner?.name ?? '')
    setType(vacancy.type ?? '')
    setTypeLabel(TYPE_OPTIONS.find(o => o.value === vacancy.type)?.label ?? vacancy.type ?? '')
    setStatus(vacancy.status ?? 'draft')
    setStatusLabel(STATUS_OPTIONS.find(o => o.value === vacancy.status)?.label ?? 'Draft')
    setExperienceLevel(vacancy.experience_level ?? '')
    setExperienceLevelLabel(
      EXPERIENCE_OPTIONS.find(o => o.value === vacancy.experience_level)?.label ?? vacancy.experience_level ?? ''
    )
    setLocation(vacancy.location ?? '')
    setSlots(vacancy.slots ? String(vacancy.slots) : '')
    setMinSalary(vacancy.min_salary ? String(vacancy.min_salary) : '')
    setMaxSalary(vacancy.max_salary ? String(vacancy.max_salary) : '')
    setRequiredSkills(vacancy.required_skills ?? [])
    setDeadline(vacancy.deadline ? new Date(vacancy.deadline * 1000).toISOString().split('T')[0] : '')
  }, [vacancy])

  useEffect(() => {
    if (existingPartner?.name) setPartnerLabel(existingPartner.name)
  }, [existingPartner])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!title.trim()) e.title = 'Judul lowongan wajib diisi'
    if (!partnerId) e.partnerId = 'Partner wajib dipilih'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')

    try {
      const payload: Record<string, unknown> = {
        title: title.trim(),
        description: description.trim() || undefined,
        partner_id: partnerId,
        created_by: user?.id,
        location: location.trim() || undefined,
        type: type || undefined,
        status,
        experience_level: experienceLevel || undefined,
        slots: slots ? Number(slots) : undefined,
        min_salary: minSalary ? Number(minSalary) : undefined,
        max_salary: maxSalary ? Number(maxSalary) : undefined,
        required_skills: requiredSkills.length > 0 ? requiredSkills : undefined,
        deadline: deadline || undefined,
      }

      if (isEdit) {
        await jobVacancyService.update(vacancyId!, payload)
        toast.success('Lowongan berhasil diperbarui')
      } else {
        await jobVacancyService.create(payload)
        toast.success('Lowongan berhasil ditambahkan')
      }

      await queryClient.invalidateQueries({ queryKey: ['talentpool-lowongan'] })
      navigate(isEdit ? `/talentpool/lowongan/${vacancyId}` : '/talentpool/lowongan')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const backPath = isEdit ? `/talentpool/lowongan/${vacancyId}` : '/talentpool/lowongan'

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Lowongan' : 'Tambah Lowongan'}
      icon={<Briefcase size={20} />}
      onBack={() => navigate(backPath)}
      tabs={[
        {
          id: 'info',
          label: 'Informasi',
          content: (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' }}>
              {/* ── Section 1: Informasi Dasar ───────────────────────────── */}
              <FieldSection title="Informasi Dasar">
                <Field label="Judul Lowongan" required error={errors.title}>
                  <input
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder="cth. Frontend Developer"
                    className={`${formStyles.input} ${errors.title ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field label="Partner" required error={errors.partnerId} hint="Perusahaan partner penyedia lowongan">
                  <SearchableSelect
                    value={partnerId}
                    displayLabel={partnerLabel}
                    placeholder="Pilih partner..."
                    error={errors.partnerId}
                    fetchOptions={fetchPartners}
                    onSelect={(opt) => {
                      setPartnerId(opt?.value ?? '')
                      setPartnerLabel(opt?.label ?? '')
                    }}
                  />
                </Field>
                <Field label="Status">
                  <SearchableSelect
                    value={status}
                    displayLabel={statusLabel}
                    placeholder="Pilih status..."
                    fetchOptions={(s) => filterStatic(STATUS_OPTIONS, s)}
                    onSelect={(opt) => {
                      setStatus(opt?.value ?? 'draft')
                      setStatusLabel(opt?.label ?? 'Draft')
                    }}
                  />
                </Field>
              </FieldSection>

              {/* ── Section 2: Detail Pekerjaan ──────────────────────────── */}
              <FieldSection title="Detail Pekerjaan">
                <FieldRow>
                  <Field label="Jenis Pekerjaan">
                    <SearchableSelect
                      value={type}
                      displayLabel={typeLabel}
                      placeholder="Pilih jenis..."
                      fetchOptions={(s) => filterStatic(TYPE_OPTIONS, s)}
                      onSelect={(opt) => {
                        setType(opt?.value ?? '')
                        setTypeLabel(opt?.label ?? '')
                      }}
                    />
                  </Field>
                  <Field label="Level Pengalaman">
                    <SearchableSelect
                      value={experienceLevel}
                      displayLabel={experienceLevelLabel}
                      placeholder="Pilih level..."
                      fetchOptions={(s) => filterStatic(EXPERIENCE_OPTIONS, s)}
                      onSelect={(opt) => {
                        setExperienceLevel(opt?.value ?? '')
                        setExperienceLevelLabel(opt?.label ?? '')
                      }}
                    />
                  </Field>
                </FieldRow>
                <FieldRow>
                  <Field label="Lokasi">
                    <input
                      type="text"
                      value={location}
                      onChange={(e) => setLocation(e.target.value)}
                      placeholder="cth. Jakarta Selatan / Remote"
                      className={formStyles.input}
                    />
                  </Field>
                  <Field label="Batas Waktu" hint="Tanggal penutupan lowongan">
                    <DatePicker value={deadline} onChange={val => setDeadline(val)} />
                  </Field>
                </FieldRow>
              </FieldSection>

              {/* ── Section 3: Kompensasi ────────────────────────────────── */}
              <FieldSection title="Kompensasi">
                <FieldRow>
                  <Field label="Gaji Minimum" hint="Opsional. Dalam Rupiah">
                    <input
                      type="text"
                      inputMode="numeric"
                      value={formatRupiah(minSalary)}
                      onChange={(e) => setMinSalary(parseRupiah(e.target.value))}
                      placeholder="5.000.000"
                      className={formStyles.input}
                    />
                  </Field>
                  <Field label="Gaji Maksimum" hint="Opsional. Dalam Rupiah">
                    <input
                      type="text"
                      inputMode="numeric"
                      value={formatRupiah(maxSalary)}
                      onChange={(e) => setMaxSalary(parseRupiah(e.target.value))}
                      placeholder="10.000.000"
                      className={formStyles.input}
                    />
                  </Field>
                  <Field label="Kuota" hint="Jumlah posisi tersedia">
                    <input
                      type="number"
                      value={slots}
                      onChange={(e) => setSlots(e.target.value)}
                      placeholder="3"
                      min={1}
                      className={formStyles.input}
                    />
                  </Field>
                </FieldRow>
              </FieldSection>

              {/* ── Section 4: Kualifikasi ───────────────────────────────── */}
              <FieldSection title="Kualifikasi">
                <Field label="Skill Dibutuhkan" hint="Tekan Enter atau koma untuk tambah skill">
                  <TagInput
                    value={requiredSkills}
                    onChange={setRequiredSkills}
                    placeholder="React, TypeScript..."
                  />
                </Field>
                <Field label="Deskripsi">
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Deskripsi pekerjaan, tanggung jawab, dan kualifikasi..."
                    rows={5}
                    className={formStyles.textarea}
                  />
                </Field>
              </FieldSection>
            </div>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate(backPath)}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
