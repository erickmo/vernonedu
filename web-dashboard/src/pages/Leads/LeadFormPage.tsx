import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { User } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { leadService } from '@/services/lead.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const SOURCE_OPTIONS = [
  { value: 'referral', label: 'Referral' },
  { value: 'social_media', label: 'Media Sosial' },
  { value: 'walk_in', label: 'Walk In' },
  { value: 'website', label: 'Website' },
  { value: 'other', label: 'Lainnya' },
]

const STATUS_OPTIONS = [
  { value: 'new', label: 'Baru' },
  { value: 'contacted', label: 'Dihubungi' },
  { value: 'interested', label: 'Tertarik' },
  { value: 'negotiating', label: 'Negosiasi' },
  { value: 'enrolled', label: 'Terdaftar' },
  { value: 'not_interested', label: 'Tidak Tertarik' },
]

export default function LeadFormPage() {
  const navigate = useNavigate()
  const { leadId } = useParams<{ leadId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(leadId)

  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [interest, setInterest] = useState('')
  const [source, setSource] = useState('referral')
  const [status, setStatus] = useState('new')
  const [notes, setNotes] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: lead } = useQuery({
    queryKey: ['lead', leadId],
    queryFn: () => leadService.getById(leadId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (lead) {
      setName(lead.name ?? '')
      setEmail(lead.email ?? '')
      setPhone(lead.phone ?? '')
      setInterest(lead.interest ?? '')
      setSource(lead.source ?? 'referral')
      setStatus(lead.status ?? 'new')
      setNotes(lead.notes ?? '')
    }
  }, [lead])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama wajib diisi'
    else if (name.trim().length < 2) e.name = 'Minimal 2 karakter'
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      e.email = 'Format email tidak valid'
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
        name: name.trim(),
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
        interest: interest.trim() || undefined,
        source,
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
      navigate('/leads')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Lead' : 'Tambah Lead'}
      icon={<User size={20} />}
      onBack={() => navigate('/leads')}
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
                <Field label="Email" error={errors.email} hint="Opsional. Digunakan untuk mengirim notifikasi.">
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="contoh@email.com"
                    className={`${formStyles.input} ${errors.email ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Telepon" hint="Opsional. Digunakan untuk menghubungi prospek.">
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="+62 xxx xxxx xxxx"
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Sumber" hint="Dari mana prospek mengetahui layanan kami.">
                  <select
                    value={source}
                    onChange={(e) => setSource(e.target.value)}
                    className={formStyles.select}
                  >
                    {SOURCE_OPTIONS.map((opt) => (
                      <option key={opt.value} value={opt.value}>
                        {opt.label}
                      </option>
                    ))}
                  </select>
                </Field>
                <Field label="Minat" hint="Opsional. Jenis kursus atau program yang diminati.">
                  <input
                    type="text"
                    value={interest}
                    onChange={(e) => setInterest(e.target.value)}
                    placeholder="cth. Programming, Digital Marketing"
                    className={formStyles.input}
                  />
                </Field>
                {isEdit && (
                  <Field label="Status" hint="Tahap prospek saat ini.">
                    <select
                      value={status}
                      onChange={(e) => setStatus(e.target.value)}
                      className={formStyles.select}
                    >
                      {STATUS_OPTIONS.map((opt) => (
                        <option key={opt.value} value={opt.value}>
                          {opt.label}
                        </option>
                      ))}
                    </select>
                  </Field>
                )}
              </FormColumn>
              <FormColumn style={{ gridColumn: '1 / -1' }}>
                <Field label="Catatan" hint="Opsional. Tambahkan catatan tentang prospek ini.">
                  <textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Catatan tambahan..."
                    rows={5}
                    className={formStyles.textarea}
                  />
                  <span style={{
                    fontSize: 'var(--font-min)', color: 'var(--color-text-tertiary)',
                    textAlign: 'right', display: 'block', marginTop: 2,
                  }}>
                    {notes.length} karakter
                  </span>
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/leads')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
