import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { FileText } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { invoiceService } from '@/services/invoice.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

export default function ManualInvoiceFormPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [studentId, setStudentId] = useState('')
  const [amount, setAmount] = useState('')
  const [dueDate, setDueDate] = useState('')
  const [notes, setNotes] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!studentId.trim()) e.student_id = 'ID Siswa wajib diisi'
    if (!amount || Number(amount) <= 0) e.amount = 'Jumlah harus lebih dari 0'
    if (!dueDate) e.due_date = 'Tanggal jatuh tempo wajib diisi'
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
        student_id: studentId.trim(),
        amount: Number(amount),
        due_date: dueDate,
        notes: notes.trim(),
      }
      await invoiceService.createManual(payload)
      toast.success('Invoice manual berhasil dibuat')
      await queryClient.invalidateQueries({ queryKey: ['finance/invoices'] })
      navigate('/finance/invoices')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal membuat invoice')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title="Buat Invoice Manual"
      icon={<FileText size={20} />}
      onBack={() => navigate('/finance/invoices')}
      tabs={[
        {
          id: 'detail',
          label: 'Detail Invoice',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="ID Siswa" required error={errors.student_id}>
                  <input
                    type="text"
                    value={studentId}
                    onChange={(e) => setStudentId(e.target.value)}
                    placeholder="Masukkan ID siswa"
                    className={`${formStyles.input} ${errors.student_id ? formStyles.inputError : ''}`}
                    autoFocus
                  />
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
                <Field label="Tanggal Jatuh Tempo" required error={errors.due_date}>
                  <input
                    type="date"
                    value={dueDate}
                    onChange={(e) => setDueDate(e.target.value)}
                    className={`${formStyles.input} ${errors.due_date ? formStyles.inputError : ''}`}
                  />
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Catatan" hint="Opsional. Tambahkan catatan untuk invoice ini.">
                  <textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Catatan tambahan..."
                    rows={6}
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
      onCancel={() => navigate('/finance/invoices')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
