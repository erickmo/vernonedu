import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { CreditCard } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { DatePicker } from '@/widgets/DatePicker/DatePicker'
import { toast } from '@/widgets/Toast/Toast'
import { hrmService } from '@/services/hrm.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

export default function PayrollPeriodFormPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [period, setPeriod] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [notes, setNotes] = useState('')

  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!period.trim()) e.period = 'Nama periode wajib diisi'
    if (!startDate) e.startDate = 'Tanggal mulai wajib diisi'
    if (!endDate) e.endDate = 'Tanggal selesai wajib diisi'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return
    setIsSubmitting(true)
    setServerError('')
    try {
      await hrmService.createPayrollPeriod({ period, start_date: startDate, end_date: endDate, notes })
      toast.success('Periode penggajian berhasil dibuat')
      await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-periods'] })
      navigate('/hrm/payroll')
    } catch (err: any) {
      setServerError(err?.message ?? 'Terjadi kesalahan, coba lagi')
    } finally {
      setIsSubmitting(false)
    }
  }

  const formContent = (
    <FormGrid>
      <FormColumn>
        <Field label="Nama Periode" required error={errors.period}>
          <input
            type="text"
            value={period}
            onChange={(e) => setPeriod(e.target.value)}
            placeholder="cth. Januari 2026"
            className={formStyles.input}
          />
        </Field>
        <Field label="Tanggal Mulai" required error={errors.startDate}>
          <DatePicker value={startDate} onChange={setStartDate} />
        </Field>
        <Field label="Tanggal Selesai" required error={errors.endDate}>
          <DatePicker value={endDate} onChange={setEndDate} />
        </Field>
      </FormColumn>
      <FormColumn>
        <Field label="Catatan">
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            rows={5}
            placeholder="Keterangan tambahan..."
            className={formStyles.input}
          />
        </Field>
      </FormColumn>
    </FormGrid>
  )

  return (
    <FormPageTemplate
      title="Buat Periode Penggajian"
      icon={<CreditCard size={20} />}
      onBack={() => navigate('/hrm/payroll')}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/hrm/payroll')}
      isSubmitting={isSubmitting}
      submitLabel="Buat Periode"
      serverError={serverError}
      helpTitle="Periode Penggajian"
      helpText="Buat periode penggajian baru. Setelah dibuat, generate payroll untuk mengisi data gaji karyawan."
      tabs={[{ id: 'form', label: 'Data Periode', content: formContent }]}
    />
  )
}
