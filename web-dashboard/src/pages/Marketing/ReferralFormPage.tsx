import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Users } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { marketingService } from '@/services/marketing.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

export default function ReferralFormPage() {
  const navigate = useNavigate()
  const { refId } = useParams<{ refId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(refId)

  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [commissionRate, setCommissionRate] = useState('')
  const [notes, setNotes] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: partners } = useQuery({
    queryKey: ['marketing-referral-partners'],
    queryFn: () => marketingService.listReferralPartners(),
    enabled: isEdit,
  })

  const partner = isEdit
    ? (Array.isArray(partners) ? partners : (partners as any)?.items ?? []).find((p: any) => String(p.id) === refId)
    : null

  useEffect(() => {
    if (partner) {
      setName(partner.name ?? '')
      setEmail(partner.email ?? '')
      setPhone(partner.phone ?? '')
      setCommissionRate(partner.commission_rate != null ? String(partner.commission_rate) : '')
      setNotes(partner.notes ?? '')
    }
  }, [partner])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama partner wajib diisi'
    if (!email.trim()) e.email = 'Email wajib diisi'
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) e.email = 'Format email tidak valid'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(ev: React.FormEvent) {
    ev.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')

    try {
      const payload: Record<string, any> = {
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim() || undefined,
        commission_rate: commissionRate ? Number(commissionRate) : undefined,
        notes: notes.trim() || undefined,
      }
      if (isEdit) {
        await marketingService.updateReferralPartner(refId!, payload)
        toast.success('Partner referral berhasil diperbarui')
      } else {
        await marketingService.createReferralPartner(payload)
        toast.success('Partner referral berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['marketing-referral-partners'] })
      navigate('/marketing')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Partner Referral' : 'Tambah Partner Referral'}
      icon={<Users size={20} />}
      onBack={() => navigate('/marketing')}
      tabs={[{
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
                  placeholder="cth. PT Sukses Mandiri"
                  className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                  autoFocus
                />
              </Field>

              <Field label="Email" required error={errors.email}>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="partner@contoh.com"
                  className={`${formStyles.input} ${errors.email ? formStyles.inputError : ''}`}
                />
              </Field>

              <Field label="Telepon">
                <input
                  type="tel"
                  inputMode="numeric"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value.replace(/[^0-9+]/g, ''))}
                  placeholder="081234567890"
                  className={formStyles.input}
                />
              </Field>
            </FormColumn>

            <FormColumn>
              <Field label="Persentase Komisi" hint="Dalam persen (%)">
                <input
                  type="number"
                  value={commissionRate}
                  onChange={(e) => setCommissionRate(e.target.value)}
                  placeholder="cth. 10"
                  min={0}
                  max={100}
                  className={formStyles.input}
                />
              </Field>

              <Field label="Catatan">
                <textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Catatan tambahan..."
                  rows={4}
                  className={formStyles.textarea}
                />
              </Field>
            </FormColumn>
          </FormGrid>
        ),
      }]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/marketing')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
