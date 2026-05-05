import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { UserCog, Search } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { hrmService } from '@/services/hrm.service'
import { apiClient } from '@/services/api.client'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const CONTRACT_TYPES = [
  { label: 'Tetap', value: 'permanent' },
  { label: 'Kontrak', value: 'contract' },
  { label: 'Magang', value: 'internship' },
  { label: 'Freelance', value: 'freelance' },
]

export default function EmployeeFormPage() {
  const navigate = useNavigate()
  const { employeeId } = useParams<{ employeeId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(employeeId)

  // Form state
  const [userId, setUserId] = useState('')
  const [userName, setUserName] = useState('')
  const [employeeNumber, setEmployeeNumber] = useState('')
  const [departmentId, setDepartmentId] = useState('')
  const [position, setPosition] = useState('')
  const [hireDate, setHireDate] = useState('')
  const [baseSalary, setBaseSalary] = useState('')
  const [phone, setPhone] = useState('')
  const [address, setAddress] = useState('')
  const [bankName, setBankName] = useState('')
  const [bankAccount, setBankAccount] = useState('')
  const [contractType, setContractType] = useState('permanent')
  const [contractEnd, setContractEnd] = useState('')
  const [notes, setNotes] = useState('')

  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  // User search
  const [userSearch, setUserSearch] = useState('')
  const [showUserSearch, setShowUserSearch] = useState(false)
  const [userResults, setUserResults] = useState<any[]>([])

  // Fetch employee data for edit mode
  const { data: emp } = useQuery<any>({
    queryKey: ['hrm-employee-detail', employeeId],
    queryFn: () => hrmService.getEmployee(employeeId!),
    enabled: isEdit,
  })

  // Fetch departments for dropdown
  const { data: departments = [] } = useQuery({
    queryKey: ['departments'],
    queryFn: async () => {
      const res = await hrmService.listDepartments()
      return (res as any) ?? []
    },
  })

  useEffect(() => {
    if (emp) {
      setUserId(emp.user_id ?? '')
      setUserName(emp.user_name ?? '')
      setEmployeeNumber(emp.employee_number ?? '')
      setDepartmentId(emp.department_id ?? '')
      setPosition(emp.position ?? '')
      setHireDate(emp.hire_date ?? '')
      setBaseSalary(emp.base_salary ? String(emp.base_salary) : '')
      setPhone(emp.phone ?? '')
      setAddress(emp.address ?? '')
      setBankName(emp.bank_name ?? '')
      setBankAccount(emp.bank_account ?? '')
      setContractType(emp.contract_type ?? 'permanent')
      setContractEnd(emp.contract_end ?? '')
      setNotes(emp.notes ?? '')
    }
  }, [emp])

  // User search handler
  useEffect(() => {
    if (userSearch.length < 2) {
      setUserResults([])
      return
    }
    const timer = setTimeout(async () => {
      try {
        const res = await apiClient.get<any>(`/users/search?name=${encodeURIComponent(userSearch)}&limit=10`)
        const d = (res as any)?.data ?? res
        setUserResults(Array.isArray(d) ? d : d?.items ?? [])
      } catch {
        setUserResults([])
      }
    }, 300)
    return () => clearTimeout(timer)
  }, [userSearch])

  function handleSelectUser(user: any) {
    setUserId(user.id)
    setUserName(user.name)
    setUserSearch('')
    setShowUserSearch(false)
    if (user.phone) setPhone(user.phone)
  }

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!userId) e.user_id = 'User wajib dipilih'
    if (!position.trim()) e.position = 'Jabatan wajib diisi'
    if (!hireDate) e.hire_date = 'Tanggal masuk wajib diisi'
    if (!baseSalary || Number(baseSalary) <= 0) e.base_salary = 'Gaji pokok wajib diisi'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')

    try {
      const payload = {
        user_id: userId,
        employee_number: employeeNumber.trim(),
        department_id: departmentId || null,
        position: position.trim(),
        hire_date: hireDate,
        base_salary: Number(baseSalary),
        phone: phone.trim(),
        address: address.trim(),
        bank_name: bankName.trim(),
        bank_account: bankAccount.trim(),
        contract_type: contractType,
        contract_end: contractEnd || null,
        notes: notes.trim(),
      }

      if (isEdit) {
        await hrmService.updateEmployee(employeeId!, payload)
        toast.success('Data karyawan berhasil diperbarui')
      } else {
        await hrmService.createEmployee(payload)
        toast.success('Karyawan berhasil ditambahkan')
      }
      await queryClient.invalidateQueries({ queryKey: ['hrm-employees'] })
      navigate(isEdit ? `/hrm/${employeeId}` : '/hrm')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const userSelectField = (
    <div style={{ position: 'relative' }}>
      {userId ? (
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '8px 12px', borderRadius: 'var(--radius-md)',
          border: '1px solid var(--color-border)', background: 'var(--color-surface)',
        }}>
          <span style={{ fontSize: 'var(--font-sm)', fontWeight: 500 }}>{userName}</span>
          <button
            type="button"
            onClick={() => { setUserId(''); setUserName('') }}
            style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}
          >
            Ganti
          </button>
        </div>
      ) : (
        <div>
          <button
            type="button"
            onClick={() => setShowUserSearch(true)}
            className={`${formStyles.input} ${errors.user_id ? formStyles.inputError : ''}`}
            style={{ cursor: 'pointer', textAlign: 'left', color: 'var(--color-text-tertiary)' }}
          >
            Pilih user...
          </button>
        </div>
      )}

      {showUserSearch && (
        <div style={{
          position: 'absolute', top: '100%', left: 0, right: 0, zIndex: 50,
          background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-md)',
          border: '1px solid var(--color-border)', boxShadow: 'var(--shadow-lg)', marginTop: 4,
          maxHeight: 280, overflow: 'hidden', display: 'flex', flexDirection: 'column',
        }}>
          <div style={{ padding: 'var(--space-2)', borderBottom: '1px solid var(--color-border)' }}>
            <div style={{ position: 'relative' }}>
              <Search size={14} style={{
                position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)',
                color: 'var(--color-text-tertiary)',
              }} />
              <input
                type="text"
                value={userSearch}
                onChange={(e) => setUserSearch(e.target.value)}
                placeholder="Cari nama user..."
                autoFocus
                style={{
                  width: '100%', padding: '8px 12px 8px 32px', borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
                  background: 'var(--color-surface)', color: 'var(--color-text)',
                }}
              />
            </div>
          </div>
          <div style={{ flex: 1, overflowY: 'auto' }}>
            {userSearch.length < 2 ? (
              <div style={{ padding: 'var(--space-4)', textAlign: 'center', color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>
                Ketik minimal 2 karakter
              </div>
            ) : userResults.length === 0 ? (
              <div style={{ padding: 'var(--space-4)', textAlign: 'center', color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>
                User tidak ditemukan
              </div>
            ) : (
              userResults.map((u: any) => (
                <button
                  key={u.id}
                  type="button"
                  onClick={() => handleSelectUser(u)}
                  style={{
                    display: 'flex', alignItems: 'center', gap: 'var(--space-3)',
                    width: '100%', padding: 'var(--space-3) var(--space-4)',
                    border: 'none', cursor: 'pointer', background: 'none', textAlign: 'left',
                  }}
                >
                  <div style={{
                    width: 28, height: 28, borderRadius: 'var(--radius-full)',
                    background: 'var(--color-primary-subtle)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    color: 'var(--color-primary)', fontSize: 'var(--font-xs)', fontWeight: 700,
                  }}>
                    {(u.name || '?').charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <div style={{ fontSize: 'var(--font-sm)', fontWeight: 500 }}>{u.name}</div>
                    <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)' }}>{u.email}</div>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Karyawan' : 'Tambah Karyawan'}
      icon={<UserCog size={20} />}
      onBack={() => navigate(isEdit ? `/hrm/${employeeId}` : '/hrm')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Karyawan',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="User" required error={errors.user_id} hint="Pilih user yang sudah terdaftar di sistem">
                  {userSelectField}
                </Field>
                <Field label="No. Karyawan" hint="Opsional. Akan digenerate otomatis jika dikosongkan">
                  <input
                    type="text"
                    value={employeeNumber}
                    onChange={(e) => setEmployeeNumber(e.target.value)}
                    placeholder="EMP-001"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Jabatan" required error={errors.position}>
                  <input
                    type="text"
                    value={position}
                    onChange={(e) => setPosition(e.target.value)}
                    placeholder="cth. Course Owner"
                    className={`${formStyles.input} ${errors.position ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Departemen">
                  <select
                    value={departmentId}
                    onChange={(e) => setDepartmentId(e.target.value)}
                    className={formStyles.input}
                  >
                    <option value="">— Pilih Departemen —</option>
                    {departments.map((d: any) => (
                      <option key={d.id} value={d.id}>{d.name}</option>
                    ))}
                  </select>
                </Field>
                <Field label="Tanggal Masuk" required error={errors.hire_date}>
                  <input
                    type="date"
                    value={hireDate}
                    onChange={(e) => setHireDate(e.target.value)}
                    className={`${formStyles.input} ${errors.hire_date ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Gaji Pokok" required error={errors.base_salary}>
                  <input
                    type="number"
                    value={baseSalary}
                    onChange={(e) => setBaseSalary(e.target.value)}
                    placeholder="5000000"
                    className={`${formStyles.input} ${errors.base_salary ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Telepon">
                  <input
                    type="text"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="08123456789"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Alamat">
                  <textarea
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    placeholder="Alamat lengkap"
                    rows={3}
                    className={formStyles.textarea}
                  />
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Tipe Kontrak">
                  <select
                    value={contractType}
                    onChange={(e) => setContractType(e.target.value)}
                    className={formStyles.input}
                  >
                    {CONTRACT_TYPES.map((ct) => (
                      <option key={ct.value} value={ct.value}>{ct.label}</option>
                    ))}
                  </select>
                </Field>
                {contractType === 'contract' && (
                  <Field label="Akhir Kontrak">
                    <input
                      type="date"
                      value={contractEnd}
                      onChange={(e) => setContractEnd(e.target.value)}
                      className={formStyles.input}
                    />
                  </Field>
                )}
                <Field label="Nama Bank">
                  <input
                    type="text"
                    value={bankName}
                    onChange={(e) => setBankName(e.target.value)}
                    placeholder="BCA, Mandiri, BNI, dll."
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Nomor Rekening">
                  <input
                    type="text"
                    value={bankAccount}
                    onChange={(e) => setBankAccount(e.target.value)}
                    placeholder="1234567890"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Catatan" hint="Opsional. Catatan tambahan tentang karyawan">
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
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate(isEdit ? `/hrm/${employeeId}` : '/hrm')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
