import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Handshake, Calendar, Clock } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
  Toggle,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { SearchableSelect } from '@/widgets/SearchableSelect/SearchableSelect'
import { partnerService } from '@/services/partner.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const PARTNER_TYPES = [
  'Sekolah',
  'Universitas',
  'Perusahaan',
  'Pemerintah',
  'Lembaga Nirlaba',
  'Lainnya',
]

function formatDate(ts: number | undefined) {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(ts * 1000))
}

export default function PartnerFormPage() {
  const navigate = useNavigate()
  const { partnerId } = useParams<{ partnerId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(partnerId)

  const [name, setName] = useState('')
  const [type, setType] = useState('')
  const [contactPerson, setContactPerson] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [address, setAddress] = useState('')
  const [isActive, setIsActive] = useState(true)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: partner } = useQuery({
    queryKey: ['partner', partnerId],
    queryFn: () => partnerService.getById(partnerId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (partner) {
      setName(partner.name ?? '')
      setType(partner.type ?? '')
      setContactPerson(partner.contact_person ?? '')
      setEmail(partner.email ?? partner.contact_email ?? '')
      setPhone(partner.phone ?? '')
      setAddress(partner.address ?? '')
      setIsActive(partner.is_active ?? true)
    }
  }, [partner])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama partner wajib diisi'
    else if (name.trim().length < 2) e.name = 'Minimal 2 karakter'
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) e.email = 'Format email tidak valid'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')

    const payload = {
      name: name.trim(),
      type: type || undefined,
      contact_person: contactPerson.trim() || undefined,
      email: email.trim() || undefined,
      phone: phone.trim() || undefined,
      address: address.trim() || undefined,
      is_active: isActive,
    }

    try {
      if (isEdit) {
        await partnerService.update(partnerId!, payload)
        toast.success('Partner berhasil diperbarui')
      } else {
        await partnerService.create(payload)
        toast.success('Partner berhasil ditambahkan')
      }
      await queryClient.invalidateQueries({ queryKey: ['partners'] })
      navigate(isEdit ? `/partners/${partnerId}` : '/partners')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const sidebarContent = (
    <FormColumn>
      <Field label="Status Partner">
        <div style={{
          padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
        }}>
          <Toggle
            checked={isActive}
            onChange={setIsActive}
            label={isActive ? 'Aktif — tampil dalam kolaborasi' : 'Nonaktif — tersembunyi'}
          />
          <p style={{
            fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)',
            marginTop: 'var(--space-2)', lineHeight: 1.5,
          }}>
            Partner nonaktif tidak akan muncul dalam daftar kolaborasi batch baru.
          </p>
        </div>
      </Field>

      {isEdit && partner && (
        <Field label="Informasi">
          <div style={{
            padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            display: 'flex', flexDirection: 'column', gap: 'var(--space-3)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Calendar size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Dibuat</span>
              <span style={{ fontWeight: 500 }}>{formatDate(partner.created_at)}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Clock size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Diperbarui</span>
              <span style={{ fontWeight: 500 }}>{formatDate(partner.updated_at)}</span>
            </div>
          </div>
        </Field>
      )}
    </FormColumn>
  )

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Partner' : 'Tambah Partner'}
      icon={<Handshake size={20} />}
      onBack={() => navigate(isEdit ? `/partners/${partnerId}` : '/partners')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Umum',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Partner" required error={errors.name}>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="cth. PT Maju Bersama"
                    className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>

                <Field label="Jenis Partner" hint="Opsional. Kategorikan tipe partner.">
                  <SearchableSelect
                    value={type}
                    displayLabel={type}
                    placeholder="— Pilih tipe —"
                    fetchOptions={(search) => Promise.resolve(
                      PARTNER_TYPES
                        .filter((t) => t.toLowerCase().includes(search.toLowerCase()))
                        .map((t) => ({ value: t, label: t }))
                    )}
                    onSelect={(opt) => setType(opt?.value ?? '')}
                  />
                </Field>

                <Field label="Kontak Person" hint="Nama PIC dari partner.">
                  <input
                    type="text"
                    value={contactPerson}
                    onChange={(e) => setContactPerson(e.target.value)}
                    placeholder="cth. Budi Santoso"
                    className={formStyles.input}
                  />
                </Field>

                <Field label="Email" error={errors.email}>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="cth. partner@email.com"
                    className={`${formStyles.input} ${errors.email ? formStyles.inputError : ''}`}
                  />
                </Field>

                <Field label="Nomor Telepon">
                  <input
                    type="tel"
                    inputMode="numeric"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value.replace(/[^0-9+]/g, ''))}
                    placeholder="cth. 08123456789"
                    className={formStyles.input}
                  />
                </Field>

                <Field label="Alamat" hint="Opsional.">
                  <textarea
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    placeholder="Alamat lengkap partner..."
                    rows={3}
                    className={formStyles.textarea}
                  />
                </Field>
              </FormColumn>
              {sidebarContent}
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate(isEdit ? `/partners/${partnerId}` : '/partners')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
