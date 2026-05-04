import { useParams, useNavigate } from 'react-router-dom'
import {
  UserCog, Pencil, Mail, Phone, MapPin, Building2, Calendar,
  CreditCard, FileText, Clock, User, Ban,
} from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { hrmService } from '@/services/hrm.service'
import { toast } from '@/widgets/Toast/Toast'
import {
  EMPLOYEE_STATUS_LABELS, EMPLOYEE_STATUS_COLORS,
  ATTENDANCE_STATUS_LABELS, ATTENDANCE_STATUS_COLORS,
  PAYROLL_STATUS_LABELS, PAYROLL_STATUS_COLORS,
} from '@/types/hrm.types'
import type { EmployeeStatus, StaffAttendance, PayrollItem } from '@/types/hrm.types'

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)
}

function formatDateStr(dateStr: string | null | undefined): string {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(dateStr))
}

function formatTimestamp(ts: number | undefined): string {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(ts * 1000))
}

function InfoRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: React.ReactNode }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 'var(--space-3)',
      padding: 'var(--space-2) 0',
    }}>
      <div style={{ color: 'var(--color-text-tertiary)', marginTop: 2, flexShrink: 0 }}>{icon}</div>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 2 }}>{label}</div>
        <div style={{ fontSize: 'var(--font-sm)', fontWeight: 500 }}>{value || '—'}</div>
      </div>
    </div>
  )
}

function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div style={{
      padding: 'var(--space-5)', borderRadius: 'var(--radius-lg)',
      border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
    }}>
      <h3 style={{
        fontSize: 'var(--font-sm)', fontWeight: 700,
        color: 'var(--color-text-secondary)', marginBottom: 'var(--space-4)',
        textTransform: 'uppercase', letterSpacing: 0.5,
      }}>
        {title}
      </h3>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-1)' }}>
        {children}
      </div>
    </div>
  )
}

export default function SdmDetailPage() {
  const { employeeId } = useParams<{ employeeId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const { data: emp, isLoading } = useQuery({
    queryKey: ['hrm-employee-detail', employeeId],
    queryFn: () => hrmService.getEmployee(employeeId!),
  })

  const { data: attendanceData } = useQuery({
    queryKey: ['hrm-attendance', employeeId],
    queryFn: () => hrmService.listAttendance({ employee_id: employeeId, limit: 20 }),
  })

  const { data: payrollData } = useQuery({
    queryKey: ['hrm-payroll-items-employee', employeeId],
    queryFn: async () => {
      const res = await apiClient.get<any>(`/hrm/payroll-periods?limit=5`)
      const periods = unwrapList(res)
      const allItems: any[] = []
      for (const p of periods) {
        const itemsRes = await hrmService.getPayrollItems(p.id)
        const filtered = itemsRes.items?.filter((i: any) => i.employee_id === employeeId) ?? []
        allItems.push(...filtered.map((i: any) => ({ ...i, period_name: p.period })))
      }
      return allItems
    },
    enabled: !!employeeId,
  })

  function unwrapList(res: any): any[] {
    const d = (res as any)?.data ?? res
    if (Array.isArray(d)) return d
    return d?.items ?? []
  }

  const status = emp?.status as EmployeeStatus | undefined
  const statusColors = status ? EMPLOYEE_STATUS_COLORS[status] : null

  async function handleDeactivate() {
    if (!emp) return
    try {
      await hrmService.updateEmployee(emp.id, { status: emp.status === 'active' ? 'inactive' : 'active' })
      toast.success(`Karyawan berhasil ${emp.status === 'active' ? 'dinonaktifkan' : 'diaktifkan kembali'}`)
      await queryClient.invalidateQueries({ queryKey: ['hrm-employee-detail', employeeId] })
      await queryClient.invalidateQueries({ queryKey: ['hrm-employees'] })
    } catch {
      toast.error('Gagal mengubah status karyawan')
    }
  }

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Karyawan',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/hrm/${employeeId}/edit`),
    },
    {
      label: emp?.status === 'active' ? 'Nonaktifkan' : 'Aktifkan',
      icon: <Ban size={14} />,
      onClick: handleDeactivate,
      variant: emp?.status === 'active' ? 'warning' : 'success',
    },
  ]

  const overviewTab = (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 'var(--space-4)' }}>
      <Card title="Informasi Pribadi">
        <InfoRow icon={<User size={14} />} label="Nama" value={emp?.user_name} />
        <InfoRow icon={<Mail size={14} />} label="Email" value={emp?.user_email} />
        <InfoRow icon={<Phone size={14} />} label="Telepon" value={emp?.phone} />
        <InfoRow icon={<MapPin size={14} />} label="Alamat" value={emp?.address} />
      </Card>
      <Card title="Kepegawaian">
        <InfoRow icon={<FileText size={14} />} label="No. Karyawan" value={emp?.employee_number} />
        <InfoRow icon={<Building2 size={14} />} label="Departemen" value={emp?.department_name} />
        <InfoRow icon={<UserCog size={14} />} label="Jabatan" value={emp?.position} />
        <InfoRow icon={<Calendar size={14} />} label="Tanggal Masuk" value={formatDateStr(emp?.hire_date)} />
        <InfoRow icon={<FileText size={14} />} label="Tipe Kontrak" value={emp?.contract_type} />
        {emp?.contract_end && (
          <InfoRow icon={<Clock size={14} />} label="Akhir Kontrak" value={formatDateStr(emp.contract_end)} />
        )}
        {emp?.user_roles && emp.user_roles.length > 0 && (
          <InfoRow icon={<User size={14} />} label="Roles" value={emp.user_roles.join(', ')} />
        )}
      </Card>
      <Card title="Keuangan">
        <InfoRow icon={<CreditCard size={14} />} label="Gaji Pokok" value={emp ? formatCurrency(emp.base_salary) : '—'} />
        <InfoRow icon={<Building2 size={14} />} label="Bank" value={emp?.bank_name} />
        <InfoRow icon={<CreditCard size={14} />} label="No. Rekening" value={emp?.bank_account} />
      </Card>
      {emp?.notes && (
        <Card title="Catatan">
          <p style={{ fontSize: 'var(--font-sm)', lineHeight: 1.6, color: 'var(--color-text-secondary)', margin: 0 }}>
            {emp.notes}
          </p>
        </Card>
      )}
      {emp && (
        <Card title="Metadata">
          <InfoRow icon={<Clock size={14} />} label="Dibuat" value={formatTimestamp(emp.created_at)} />
          <InfoRow icon={<Clock size={14} />} label="Diperbarui" value={formatTimestamp(emp.updated_at)} />
        </Card>
      )}
    </div>
  )

  const attendanceList: StaffAttendance[] = attendanceData?.items ?? []

  const attendanceTab = (
    <div>
      {attendanceList.length === 0 ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Belum ada data kehadiran.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-2)' }}>
          {attendanceList.map((a) => {
            const colors = ATTENDANCE_STATUS_COLORS[a.status]
            return (
              <div key={a.id} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: 'var(--space-3) var(--space-4)', borderRadius: 'var(--radius-md)',
                border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                  <div style={{ fontSize: 'var(--font-sm)', fontWeight: 500 }}>{formatDateStr(a.date)}</div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-4)' }}>
                  <span style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)' }}>
                    {a.clock_in || '—'} - {a.clock_out || '—'}
                  </span>
                  <span style={{
                    display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
                    fontSize: 'var(--font-xs)', fontWeight: 600,
                    background: colors?.bg, color: colors?.color,
                  }}>
                    {ATTENDANCE_STATUS_LABELS[a.status]}
                  </span>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )

  const payrollItems: any[] = payrollData ?? []

  const payrollTab = (
    <div>
      {payrollItems.length === 0 ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          Belum ada data penggajian.
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-2)' }}>
          {payrollItems.map((item) => {
            const colors = PAYROLL_STATUS_COLORS[item.status as keyof typeof PAYROLL_STATUS_COLORS]
            return (
              <div key={item.id} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: 'var(--space-3) var(--space-4)', borderRadius: 'var(--radius-md)',
                border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
              }}>
                <div>
                  <div style={{ fontWeight: 600, fontSize: 'var(--font-sm)' }}>Periode: {item.period_name}</div>
                  <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginTop: 2 }}>
                    Gaji Pokok: {formatCurrency(item.base_salary)}
                    {item.facilitator_fee > 0 && ` + Fee: ${formatCurrency(item.facilitator_fee)}`}
                    {item.attendance_deduction > 0 && ` - Potongan: ${formatCurrency(item.attendance_deduction)}`}
                    {item.bonus > 0 && ` + Bonus: ${formatCurrency(item.bonus)}`}
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                  <span style={{ fontWeight: 700, fontSize: 'var(--font-sm)' }}>
                    {formatCurrency(item.total_amount)}
                  </span>
                  <span style={{
                    display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
                    fontSize: 'var(--font-xs)', fontWeight: 600,
                    background: colors?.bg, color: colors?.color,
                  }}>
                    {PAYROLL_STATUS_LABELS[item.status as keyof typeof PAYROLL_STATUS_LABELS] ?? item.status}
                  </span>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/hrm')}
      icon={<UserCog size={20} />}
      title={isLoading ? 'Memuat...' : (emp?.user_name ?? 'Karyawan')}
      code={emp?.employee_number}
      badges={
        status ? (
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 4, padding: '2px 10px',
            borderRadius: 'var(--radius-full)', fontSize: 'var(--font-xs)', fontWeight: 600,
            background: statusColors?.bg, color: statusColors?.color,
          }}>
            {EMPLOYEE_STATUS_LABELS[status]}
          </span>
        ) : undefined
      }
      actions={actions}
      tabs={[
        { id: 'overview', label: 'Profil', icon: <User size={14} />, content: overviewTab },
        { id: 'attendance', label: 'Kehadiran', icon: <Clock size={14} />, content: attendanceTab },
        { id: 'payroll', label: 'Penggajian', icon: <CreditCard size={14} />, content: payrollTab },
      ]}
    />
  )
}
