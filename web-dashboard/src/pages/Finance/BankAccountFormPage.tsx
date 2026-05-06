import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Landmark } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { accountingService } from '@/services/accounting.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const CURRENCIES = [
  { label: 'IDR — Rupiah', value: 'IDR' },
  { label: 'USD — Dollar AS', value: 'USD' },
  { label: 'EUR — Euro', value: 'EUR' },
  { label: 'SGD — Dollar Singapura', value: 'SGD' },
]

export default function BankAccountFormPage() {
  const navigate = useNavigate()
  const { accountId } = useParams<{ accountId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(accountId)

  const [name, setName] = useState('')
  const [accountNumber, setAccountNumber] = useState('')
  const [bankName, setBankName] = useState('')
  const [currency, setCurrency] = useState('IDR')
  const [initialBalance, setInitialBalance] = useState('')
  const [description, setDescription] = useState('')

  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)

  const { data: existing } = useQuery<any>({
    queryKey: ['bank-account', accountId],
    queryFn: () => accountingService.getBankAccount(accountId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (existing) {
      setName(existing.name ?? '')
      setAccountNumber(existing.account_number ?? '')
      setBankName(existing.bank_name ?? '')
      setCurrency(existing.currency ?? 'IDR')
      setInitialBalance(existing.initial_balance ? String(existing.initial_balance) : '')
      setDescription(existing.description ?? '')
    }
  }, [existing])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama rekening wajib diisi'
    if (!accountNumber.trim()) e.account_number = 'Nomor rekening wajib diisi'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    try {
      if (isEdit) {
        await accountingService.updateBankAccount(accountId!, {
          name: name.trim(),
          account_number: accountNumber.trim(),
          bank_name: bankName.trim() || undefined,
          currency,
          description: description.trim() || undefined,
        })
        toast.success('Rekening berhasil diperbarui')
      } else {
        await accountingService.createBankAccount({
          name: name.trim(),
          account_number: accountNumber.trim(),
          bank_name: bankName.trim() || undefined,
          currency,
          initial_balance: initialBalance ? Number(initialBalance) : 0,
          description: description.trim() || undefined,
        })
        toast.success('Rekening berhasil ditambahkan')
      }

      await queryClient.invalidateQueries({ queryKey: ['finance/bank-accounts'] })
      navigate('/finance/bank-accounts')
    } catch {
      toast.error('Gagal menyimpan rekening')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Rekening Bank' : 'Tambah Rekening Bank'}
      icon={<Landmark size={20} />}
      onBack={() => navigate('/finance/bank-accounts')}
      tabs={[
        {
          id: 'info',
          label: 'Informasi',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Rekening/Bank" required error={errors.name}>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="cth. Kas Utama BCA"
                    className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Nomor Rekening" required error={errors.account_number}>
                  <input
                    type="text"
                    value={accountNumber}
                    onChange={(e) => setAccountNumber(e.target.value)}
                    placeholder="cth. 1234567890"
                    className={`${formStyles.input} ${errors.account_number ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Nama Bank">
                  <input
                    type="text"
                    value={bankName}
                    onChange={(e) => setBankName(e.target.value)}
                    placeholder="cth. Bank Central Asia"
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Mata Uang">
                  <select
                    value={currency}
                    onChange={(e) => setCurrency(e.target.value)}
                    className={formStyles.input}
                  >
                    {CURRENCIES.map((c) => (
                      <option key={c.value} value={c.value}>{c.label}</option>
                    ))}
                  </select>
                </Field>
                {!isEdit && (
                  <Field label="Saldo Awal">
                    <input
                      type="number"
                      value={initialBalance}
                      onChange={(e) => setInitialBalance(e.target.value)}
                      placeholder="0"
                      min={0}
                      className={formStyles.input}
                    />
                  </Field>
                )}
                <Field label="Keterangan">
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Keterangan tambahan (opsional)"
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
      submitLabel={isEdit ? 'Simpan Perubahan' : 'Simpan'}
    />
  )
}
