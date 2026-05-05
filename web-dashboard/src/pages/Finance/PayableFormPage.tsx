import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Receipt } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { payableService } from '@/services/payable.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'
import { DatePicker } from '@/widgets/DatePicker/DatePicker'

const PAYABLE_TYPES = [
  { label: 'Komisi Fasilitator', value: 'facilitator_fee' },
  { label: 'Operasional', value: 'operational' },
  { label: 'Lainnya', value: 'other' },
]

export default function PayableFormPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [description, setDescription] = useState('')
  const [type, setType] = useState('')
  const [amount, setAmount] = useState('')
  const [dueDate, setDueDate] = useState('')
  const [notes, setNotes] = useState('')

  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!description.trim()) e.description = 'Deskripsi wajib diisi'
    if (!amount || Number(amount) <= 0) e.amount = 'Jumlah wajib diisi'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    try {
      const payload = {
        description: description.trim(),
        type: type || undefined,
        amount: Number(amount),
        due_date: dueDate || undefined,
        notes: notes.trim() || undefined,
      }

      await payableService.create(payload)
      toast.success('Tagihan berhasil ditambahkan')

      await queryClient.invalidateQueries({ queryKey: ['finance/payables'] })
      navigate('/finance/payables')
    } catch {
      toast.error('Gagal menyimpan tagihan')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title="Tambah Tagihan"
      icon={<Receipt size={20} />}
      onBack={() => navigate('/finance/payables')}
      tabs={[
        {
          id: 'info',
          label: 'Informasi',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Deskripsi/Judul Tagihan" required error={errors.description}>
                  <input
                    type="text"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="cth. Komisi fasilitator Maret 2026"
                    className={`${formStyles.input} ${errors.description ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Jenis Tagihan">
                  <select
                    value={type}
                    onChange={(e) => setType(e.target.value)}
                    className={formStyles.input}
                  >
                    <option value="">— Pilih Jenis —</option>
                    {PAYABLE_TYPES.map((t) => (
                      <option key={t.value} value={t.value}>{t.label}</option>
                    ))}
                  </select>
                </Field>
                <Field label="Jumlah (Rp)" required error={errors.amount}>
                  <input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="0"
                    min={0}
                    className={`${formStyles.input} ${errors.amount ? formStyles.inputError : ''}`}
                  />
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Tanggal Jatuh Tempo">
                  <DatePicker
                    value={dueDate}
                    onChange={val => setDueDate(val)}
                  />
                </Field>
                <Field label="Catatan">
                  <textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Catatan tambahan (opsional)"
                    rows={4}
                    className={formStyles.input}
                    style={{ resize: 'vertical' }}
                  />
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      isSubmitting={isSubmitting}
      submitLabel="Simpan"
    />
  )
}
