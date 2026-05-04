import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Receipt, Calendar, Clock } from 'lucide-react'
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

function formatDate(ts: number | undefined) {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(ts * 1000))
}

const TYPE_OPTIONS = [
  { value: 'debit', label: 'Debit (Pemasukan)' },
  { value: 'credit', label: 'Kredit (Pengeluaran)' },
]

export default function TransactionFormPage() {
  const navigate = useNavigate()
  const { txId } = useParams<{ txId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(txId)

  const [date, setDate] = useState('')
  const [accountId, setAccountId] = useState('')
  const [type, setType] = useState('debit')
  const [amount, setAmount] = useState('')
  const [description, setDescription] = useState('')
  const [referenceNumber, setReferenceNumber] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: tx } = useQuery({
    queryKey: ['transaction', txId],
    queryFn: () => accountingService.listTransactions({ id: txId }).then((r: any) => {
      if (Array.isArray(r)) return r.find((t: any) => t.id === txId) ?? r
      return (r as any).data?.find((t: any) => t.id === txId) ?? r
    }),
    enabled: isEdit,
  })

  useEffect(() => {
    if (tx) {
      const data = Array.isArray(tx) ? tx[0] : tx
      if (data) {
        setDate(data.date ?? '')
        setAccountId(data.account_id ?? '')
        setType(data.type ?? 'debit')
        setAmount(data.amount?.toString() ?? data.debit?.toString() ?? data.credit?.toString() ?? '')
        setDescription(data.description ?? '')
        setReferenceNumber(data.reference_number ?? '')
      }
    }
  }, [tx])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!date) e.date = 'Tanggal wajib diisi'
    if (!accountId.trim()) e.account_id = 'ID Akun wajib diisi'
    if (!type) e.type = 'Jenis transaksi wajib dipilih'
    if (!amount || Number(amount) <= 0) e.amount = 'Jumlah harus lebih dari 0'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(ev: React.FormEvent) {
    ev.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')

    try {
      const payload = {
        date,
        account_id: accountId.trim(),
        type,
        amount: Number(amount),
        description: description.trim(),
        reference_number: referenceNumber.trim(),
      }
      if (isEdit) {
        await accountingService.updateTransaction(txId!, payload)
        toast.success('Transaksi berhasil diperbarui')
      } else {
        await accountingService.createTransaction(payload)
        toast.success('Transaksi berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['transactions'] })
      navigate('/finance/transactions')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan transaksi')
    } finally {
      setIsSubmitting(false)
    }
  }

  const sidebarContent = (
    <FormColumn>
      {isEdit && tx && (
        <Field label="Informasi">
          <div style={{
            padding: 'var(--space-4)',
            borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)',
            background: 'var(--color-surface-elevated)',
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--space-3)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Calendar size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Dibuat</span>
              <span style={{ fontWeight: 500 }}>{formatDate((tx as any).created_at)}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', fontSize: 'var(--font-sm)' }}>
              <Clock size={13} style={{ color: 'var(--color-text-tertiary)' }} />
              <span style={{ color: 'var(--color-text-tertiary)' }}>Diperbarui</span>
              <span style={{ fontWeight: 500 }}>{formatDate((tx as any).updated_at)}</span>
            </div>
          </div>
        </Field>
      )}
    </FormColumn>
  )

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'}
      icon={<Receipt size={20} />}
      onBack={() => navigate('/finance/transactions')}
      tabs={[
        {
          id: 'general',
          label: 'Detail Transaksi',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Tanggal" required error={errors.date}>
                  <input
                    type="date"
                    value={date}
                    onChange={(e) => setDate(e.target.value)}
                    className={`${formStyles.input} ${errors.date ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="ID Akun" required error={errors.account_id}>
                  <input
                    type="text"
                    value={accountId}
                    onChange={(e) => setAccountId(e.target.value)}
                    placeholder="cth. ACC-001"
                    className={`${formStyles.input} ${errors.account_id ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Jenis" required error={errors.type}>
                  <select
                    value={type}
                    onChange={(e) => setType(e.target.value)}
                    className={`${formStyles.input} ${errors.type ? formStyles.inputError : ''}`}
                  >
                    {TYPE_OPTIONS.map((opt) => (
                      <option key={opt.value} value={opt.value}>
                        {opt.label}
                      </option>
                    ))}
                  </select>
                </Field>
                <Field label="Jumlah" required error={errors.amount}>
                  <input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="cth. 500000"
                    min={0}
                    className={`${formStyles.input} ${errors.amount ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Deskripsi" hint="Opsional. Keterangan tambahan untuk transaksi ini.">
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Deskripsi transaksi..."
                    rows={4}
                    className={formStyles.textarea}
                  />
                </Field>
                <Field label="No. Referensi" hint="Opsional. Nomor referensi atau bukti transaksi.">
                  <input
                    type="text"
                    value={referenceNumber}
                    onChange={(e) => setReferenceNumber(e.target.value)}
                    placeholder="cth. TRX-20260501-001"
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
              {sidebarContent}
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/finance/transactions')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
