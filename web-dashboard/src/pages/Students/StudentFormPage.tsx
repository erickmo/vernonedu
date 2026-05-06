import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { User, Calendar, Clock } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
  Toggle,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { studentService } from '@/services/student.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const GENDER_OPTIONS = [
  { value: '', label: 'Pilih...' },
  { value: 'male', label: 'Laki-laki' },
  { value: 'female', label: 'Perempuan' },
]

const EDUCATION_OPTIONS = [
  { value: '', label: 'Pilih...' },
  { value: 'SD', label: 'SD' },
  { value: 'SMP', label: 'SMP' },
  { value: 'SMA', label: 'SMA/SMK' },
  { value: 'D1', label: 'D1' },
  { value: 'D2', label: 'D2' },
  { value: 'D3', label: 'D3' },
  { value: 'S1', label: 'S1' },
  { value: 'S2', label: 'S2' },
  { value: 'S3', label: 'S3' },
]

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

  // Tab 1 — Informasi Umum
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [gender, setGender] = useState('')
  const [birthDate, setBirthDate] = useState('')
  const [nik, setNik] = useState('')
  const [photoUrl, setPhotoUrl] = useState('')
  const [isActive, setIsActive] = useState(true)

  // Tab 2 — Alamat
  const [address, setAddress] = useState('')
  const [city, setCity] = useState('')
  const [province, setProvince] = useState('')
  const [postalCode, setPostalCode] = useState('')

  // Tab 3 — Pendidikan
  const [educationLevel, setEducationLevel] = useState('')
  const [schoolName, setSchoolName] = useState('')

  // Tab 4 — Kontak Darurat
  const [emergencyContactName, setEmergencyContactName] = useState('')
  const [emergencyContactPhone, setEmergencyContactPhone] = useState('')

  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: student } = useQuery({
    queryKey: ['student', studentId],
    queryFn: () => studentService.getById(studentId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (!student) return
    setName(student.name ?? '')
    setEmail(student.email ?? '')
    setPhone(student.phone ?? '')
    setGender(student.gender ?? '')
    setBirthDate(student.birth_date ?? '')
    setNik(student.nik ?? '')
    setPhotoUrl(student.photo_url ?? '')
    setIsActive(student.is_active ?? true)
    setAddress(student.address ?? '')
    setCity(student.city ?? '')
    setProvince(student.province ?? '')
    setPostalCode(student.postal_code ?? '')
    setEducationLevel(student.education_level ?? '')
    setSchoolName(student.school_name ?? '')
    setEmergencyContactName(student.emergency_contact_name ?? '')
    setEmergencyContactPhone(student.emergency_contact_phone ?? '')
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
      const base = {
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim() || undefined,
        gender: gender || undefined,
        birth_date: birthDate || undefined,
        nik: nik.trim() || undefined,
        photo_url: photoUrl.trim() || undefined,
        address: address.trim() || undefined,
        city: city.trim() || undefined,
        province: province.trim() || undefined,
        postal_code: postalCode.trim() || undefined,
        education_level: educationLevel || undefined,
        school_name: schoolName.trim() || undefined,
        emergency_contact_name: emergencyContactName.trim() || undefined,
        emergency_contact_phone: emergencyContactPhone.trim() || undefined,
      }
      if (isEdit) {
        await studentService.update(studentId!, { ...base, is_active: isActive })
        toast.success('Data siswa berhasil diperbarui')
      } else {
        await studentService.create(base)
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
          </div>
        </Field>
      )}
      {isEdit && (
        <Field label="Status Siswa" hint="Nonaktifkan jika siswa sudah alumni atau keluar.">
          <Toggle
            checked={isActive}
            onChange={setIsActive}
            label={isActive ? 'Aktif' : 'Alumni'}
          />
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
                <Field label="Telepon" hint="Nomor HP/WA untuk komunikasi.">
                  <input
                    type="tel"
                    inputMode="numeric"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value.replace(/[^0-9+]/g, ''))}
                    placeholder="cth. 08123456789"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Jenis Kelamin">
                  <select
                    value={gender}
                    onChange={(e) => setGender(e.target.value)}
                    className={formStyles.input}
                  >
                    {GENDER_OPTIONS.map(o => (
                      <option key={o.value} value={o.value}>{o.label}</option>
                    ))}
                  </select>
                </Field>
                <Field label="Tanggal Lahir">
                  <input
                    type="date"
                    value={birthDate}
                    onChange={(e) => setBirthDate(e.target.value)}
                    className={formStyles.input}
                  />
                </Field>
                <Field label="NIK" hint="Nomor Induk Kependudukan (KTP).">
                  <input
                    type="text"
                    inputMode="numeric"
                    value={nik}
                    onChange={(e) => setNik(e.target.value.replace(/[^0-9]/g, '').slice(0, 16))}
                    placeholder="16 digit NIK"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="URL Foto" hint="Link foto profil (opsional).">
                  <input
                    type="url"
                    value={photoUrl}
                    onChange={(e) => setPhotoUrl(e.target.value)}
                    placeholder="https://..."
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
              {sidebarContent}
            </FormGrid>
          ),
        },
        {
          id: 'address',
          label: 'Alamat',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Alamat Lengkap">
                  <textarea
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    placeholder="cth. Jl. Merdeka No. 10, RT 02/RW 05"
                    rows={3}
                    className={formStyles.input}
                    style={{ resize: 'vertical' }}
                  />
                </Field>
                <Field label="Kota">
                  <input
                    type="text"
                    value={city}
                    onChange={(e) => setCity(e.target.value)}
                    placeholder="cth. Jakarta Selatan"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Provinsi">
                  <input
                    type="text"
                    value={province}
                    onChange={(e) => setProvince(e.target.value)}
                    placeholder="cth. DKI Jakarta"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Kode Pos">
                  <input
                    type="text"
                    inputMode="numeric"
                    value={postalCode}
                    onChange={(e) => setPostalCode(e.target.value.replace(/[^0-9]/g, '').slice(0, 5))}
                    placeholder="cth. 12345"
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
        {
          id: 'education',
          label: 'Pendidikan',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Pendidikan Terakhir">
                  <select
                    value={educationLevel}
                    onChange={(e) => setEducationLevel(e.target.value)}
                    className={formStyles.input}
                  >
                    {EDUCATION_OPTIONS.map(o => (
                      <option key={o.value} value={o.value}>{o.label}</option>
                    ))}
                  </select>
                </Field>
                <Field label="Nama Sekolah / Universitas">
                  <input
                    type="text"
                    value={schoolName}
                    onChange={(e) => setSchoolName(e.target.value)}
                    placeholder="cth. Universitas Indonesia"
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
        {
          id: 'emergency',
          label: 'Kontak Darurat',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Kontak Darurat">
                  <input
                    type="text"
                    value={emergencyContactName}
                    onChange={(e) => setEmergencyContactName(e.target.value)}
                    placeholder="cth. Siti Rahayu (Ibu)"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Telepon Kontak Darurat">
                  <input
                    type="tel"
                    inputMode="numeric"
                    value={emergencyContactPhone}
                    onChange={(e) => setEmergencyContactPhone(e.target.value.replace(/[^0-9+]/g, ''))}
                    placeholder="cth. 08129876543"
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
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
