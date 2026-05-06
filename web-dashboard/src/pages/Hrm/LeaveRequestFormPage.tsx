import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { CalendarOff } from 'lucide-react'
import { useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { hrmService } from '@/services/hrm.service'
import { DatePicker } from '@/widgets/DatePicker/DatePicker'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const LEAVE_TYPES = [
  { label: 'Tahunan', value: 'annual' },
  { label: 'Sakit', value: 'sick' },
  { label: 'Pribadi', value: 'personal' },
  { label: 'Melahirkan', value: 'maternity' },
  { label: 'Lainnya', value: 'other' },
]

export default function LeaveRequestFormPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [employeeId, setEmployeeId] = useState('')
  const [leaveType, setLeaveType] = useState('annual')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [reason, setReason] = useState('')

  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!employeeId.trim()) e.employeeId = 'ID karyawan wajib diisi'
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
      await hrmService.createLeave({
        employee_id: employeeId,
        leave_type: leaveType,
        start_date: startDate,
        end_date: endDate,
        reason,
      })
      toast.success('Permintaan cuti berhasil diajukan')
      await queryClient.invalidateQueries({ queryKey: ['hrm-leaves'] })
      navigate('/hrm/leaves')
    } catch (err: any) {
      setServerError(err?.message ?? 'Terjadi kesalahan, coba lagi')
    } finally {
      setIsSubmitting(false)
    }
  }

  const formContent = (
    <FormGrid>
      <FormColumn>
        <Field label="ID Karyawan" required error={errors.employeeId}>
          <input
            type="text"
            value={employeeId}
            onChange={(e) => setEmployeeId(e.target.value)}
            placeholder="Masukkan ID karyawan..."
            className={formStyles.input}
          />
        </Field>
        <Field label="Jenis Cuti" required>
          <select
            value={leaveType}
            onChange={(e) => setLeaveType(e.target.value)}
            className={formStyles.input}
          >
            {LEAVE_TYPES.map((t) => (
              <option key={t.value} value={t.value}>{t.label}</option>
            ))}
          </select>
        </Field>
      </FormColumn>
      <FormColumn>
        <Field label="Tanggal Mulai" required error={errors.startDate}>
          <DatePicker value={startDate} onChange={setStartDate} />
        </Field>
        <Field label="Tanggal Selesai" required error={errors.endDate}>
          <DatePicker value={endDate} onChange={setEndDate} />
        </Field>
        <Field label="Alasan">
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            rows={4}
            placeholder="Keterangan alasan cuti..."
            className={formStyles.input}
          />
        </Field>
      </FormColumn>
    </FormGrid>
  )

  return (
    <FormPageTemplate
      title="Ajukan Cuti"
      icon={<CalendarOff size={20} />}
      onBack={() => navigate('/hrm/leaves')}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/hrm/leaves')}
      isSubmitting={isSubmitting}
      submitLabel="Ajukan Cuti"
      serverError={serverError}
      helpTitle="Permintaan Cuti"
      helpText="Ajukan permintaan cuti karyawan. Permintaan akan menunggu persetujuan dari atasan."
      tabs={[{ id: 'form', label: 'Data Cuti', content: formContent }]}
    />
  )
}
