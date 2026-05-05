import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { CalendarCheck } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { DatePicker } from '@/widgets/DatePicker/DatePicker'
import { toast } from '@/widgets/Toast/Toast'
import { hrmService } from '@/services/hrm.service'
import { ATTENDANCE_STATUS_LABELS } from '@/types/hrm.types'
import type { AttendanceStatus } from '@/types/hrm.types'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const STATUS_OPTIONS = Object.entries(ATTENDANCE_STATUS_LABELS).map(([value, label]) => ({ value, label }))

export default function AttendanceFormPage() {
  const navigate = useNavigate()
  const { attendanceId } = useParams<{ attendanceId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(attendanceId)

  const [employeeId, setEmployeeId] = useState('')
  const [date, setDate] = useState('')
  const [status, setStatus] = useState<AttendanceStatus>('present')
  const [clockIn, setClockIn] = useState('')
  const [clockOut, setClockOut] = useState('')
  const [note, setNote] = useState('')

  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: record } = useQuery<any>({
    queryKey: ['hrm-attendance-detail', attendanceId],
    queryFn: () => hrmService.getAttendance(attendanceId!),
    enabled: isEdit,
  })

  const { data: employees = [] } = useQuery({
    queryKey: ['hrm-employees-all'],
    queryFn: async () => {
      const res = await hrmService.listEmployees({ limit: 200 })
      return res.items ?? []
    },
  })

  useEffect(() => {
    if (record) {
      setEmployeeId(record.employee_id ?? '')
      setDate(record.date ?? '')
      setStatus(record.status ?? 'present')
      setClockIn(record.clock_in ?? '')
      setClockOut(record.clock_out ?? '')
      setNote(record.note ?? '')
    }
  }, [record])

  function validate(): boolean {
    const errs: Record<string, string> = {}
    if (!employeeId) errs.employeeId = 'Karyawan wajib dipilih'
    if (!date) errs.date = 'Tanggal wajib diisi'
    if (!status) errs.status = 'Status wajib dipilih'
    setErrors(errs)
    return Object.keys(errs).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return
    setIsSubmitting(true)
    setServerError('')
    try {
      const payload = { employee_id: employeeId, date, status, clock_in: clockIn, clock_out: clockOut, note }
      if (isEdit) {
        await hrmService.updateAttendance(attendanceId!, payload)
        toast.success('Data kehadiran berhasil diperbarui')
        await queryClient.invalidateQueries({ queryKey: ['hrm-attendance-detail', attendanceId] })
        navigate(`/hrm/attendance/${attendanceId}`)
      } else {
        await hrmService.createAttendance(payload)
        toast.success('Data kehadiran berhasil ditambahkan')
        navigate('/hrm/attendance')
      }
      await queryClient.invalidateQueries({ queryKey: ['hrm-attendance'] })
    } catch (err: any) {
      setServerError(err?.message ?? 'Terjadi kesalahan, coba lagi')
    } finally {
      setIsSubmitting(false)
    }
  }

  const backPath = isEdit ? `/hrm/attendance/${attendanceId}` : '/hrm/attendance'

  const formContent = (
    <FormGrid>
      <FormColumn>
        <Field label="Karyawan" required error={errors.employeeId}>
          <select
            value={employeeId}
            onChange={(e) => setEmployeeId(e.target.value)}
            disabled={isEdit}
            className={formStyles.input}
          >
            <option value="">Pilih karyawan...</option>
            {employees.map((emp: any) => (
              <option key={emp.id} value={emp.id}>{emp.user_name}</option>
            ))}
          </select>
        </Field>
        <Field label="Tanggal" required error={errors.date}>
          <DatePicker value={date} onChange={setDate} />
        </Field>
        <Field label="Status" required error={errors.status}>
          <select
            value={status}
            onChange={(e) => setStatus(e.target.value as AttendanceStatus)}
            className={formStyles.input}
          >
            {STATUS_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
        </Field>
      </FormColumn>
      <FormColumn>
        <Field label="Jam Masuk">
          <input
            type="time"
            value={clockIn}
            onChange={(e) => setClockIn(e.target.value)}
            className={formStyles.input}
          />
        </Field>
        <Field label="Jam Keluar">
          <input
            type="time"
            value={clockOut}
            onChange={(e) => setClockOut(e.target.value)}
            className={formStyles.input}
          />
        </Field>
        <Field label="Catatan">
          <textarea
            value={note}
            onChange={(e) => setNote(e.target.value)}
            rows={4}
            className={formStyles.input}
            placeholder="Keterangan tambahan..."
          />
        </Field>
      </FormColumn>
    </FormGrid>
  )

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Kehadiran' : 'Tambah Kehadiran'}
      icon={<CalendarCheck size={20} />}
      onBack={() => navigate(backPath)}
      onSubmit={handleSubmit}
      onCancel={() => navigate(backPath)}
      isSubmitting={isSubmitting}
      submitLabel={isEdit ? 'Simpan Perubahan' : 'Tambah Kehadiran'}
      serverError={serverError}
      helpTitle="Kehadiran"
      helpText="Tambah atau koreksi data kehadiran karyawan secara manual."
      tabs={[{ id: 'form', label: 'Data Kehadiran', content: formContent }]}
    />
  )
}
