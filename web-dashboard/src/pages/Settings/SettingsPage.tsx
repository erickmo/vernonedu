import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Settings, Plus, Trash2 } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { Modal } from '@/widgets/Modal/Modal'
import { toast } from '@/widgets/Toast/Toast'
import { apiClient } from '@/services/api.client'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

type CommissionBasis = 'revenue' | 'profit'

interface CommissionSettings {
  op_leader_pct: number
  op_leader_basis: CommissionBasis
  dept_leader_pct: number
  dept_leader_basis: CommissionBasis
  course_creator_pct: number
  course_creator_basis: CommissionBasis
}

interface FacilitatorLevel {
  id?: string
  level: number
  name: string
  fee_per_session: number
}

interface Holiday {
  id: string
  date: string
  name: string
}

function BasisSelect({
  value,
  onChange,
}: {
  value: CommissionBasis
  onChange: (v: CommissionBasis) => void
}) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value as CommissionBasis)}
      className={formStyles.input}
    >
      <option value="revenue">Revenue</option>
      <option value="profit">Profit</option>
    </select>
  )
}

function CommissionTab() {
  const queryClient = useQueryClient()
  const [form, setForm] = useState<CommissionSettings>({
    op_leader_pct: 0,
    op_leader_basis: 'revenue',
    dept_leader_pct: 0,
    dept_leader_basis: 'revenue',
    course_creator_pct: 0,
    course_creator_basis: 'revenue',
  })
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data } = useQuery({
    queryKey: ['settings-commission'],
    queryFn: () => apiClient.get<{ data: CommissionSettings }>('/settings/commission'),
  })

  useEffect(() => {
    if (data?.data) setForm(data.data)
  }, [data])

  function setField<K extends keyof CommissionSettings>(key: K, value: CommissionSettings[K]) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setIsSubmitting(true)
    setServerError('')
    try {
      await apiClient.put('/settings/commission', form)
      await queryClient.invalidateQueries({ queryKey: ['settings-commission'] })
      toast.success('Pengaturan komisi berhasil disimpan')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan pengaturan')
      toast.error('Gagal menyimpan pengaturan komisi')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      {serverError && (
        <p style={{ color: 'var(--color-danger)', marginBottom: 'var(--space-4)', fontSize: 'var(--font-sm)' }}>
          {serverError}
        </p>
      )}
      <FormGrid>
        <FormColumn>
          <Field label="Komisi Operation Leader (%)" required>
            <input
              type="number"
              min={0}
              max={100}
              step={0.1}
              value={form.op_leader_pct}
              onChange={(e) => setField('op_leader_pct', parseFloat(e.target.value) || 0)}
              className={formStyles.input}
            />
          </Field>
          <Field label="Basis Komisi Operation Leader" required>
            <BasisSelect value={form.op_leader_basis} onChange={(v) => setField('op_leader_basis', v)} />
          </Field>
          <Field label="Komisi Kepala Departemen (%)" required>
            <input
              type="number"
              min={0}
              max={100}
              step={0.1}
              value={form.dept_leader_pct}
              onChange={(e) => setField('dept_leader_pct', parseFloat(e.target.value) || 0)}
              className={formStyles.input}
            />
          </Field>
          <Field label="Basis Komisi Kepala Departemen" required>
            <BasisSelect value={form.dept_leader_basis} onChange={(v) => setField('dept_leader_basis', v)} />
          </Field>
        </FormColumn>
        <FormColumn>
          <Field label="Komisi Course Creator (%)" required>
            <input
              type="number"
              min={0}
              max={100}
              step={0.1}
              value={form.course_creator_pct}
              onChange={(e) => setField('course_creator_pct', parseFloat(e.target.value) || 0)}
              className={formStyles.input}
            />
          </Field>
          <Field label="Basis Komisi Course Creator" required>
            <BasisSelect value={form.course_creator_basis} onChange={(v) => setField('course_creator_basis', v)} />
          </Field>
          <div style={{ marginTop: 'var(--space-4)' }}>
            <button
              type="submit"
              className={formStyles.btnPrimary ?? ''}
              disabled={isSubmitting}
              style={{
                padding: '8px 20px', borderRadius: 'var(--radius-md)',
                background: 'var(--color-primary)', color: '#fff',
                border: 'none', cursor: isSubmitting ? 'not-allowed' : 'pointer',
                fontWeight: 600, fontSize: 'var(--font-sm)',
              }}
            >
              {isSubmitting ? 'Menyimpan...' : 'Simpan Komisi'}
            </button>
          </div>
        </FormColumn>
      </FormGrid>
    </form>
  )
}

function FacilitatorLevelsTab() {
  const queryClient = useQueryClient()
  const [levels, setLevels] = useState<FacilitatorLevel[]>([])
  const [isSubmitting, setIsSubmitting] = useState(false)

  const { data } = useQuery({
    queryKey: ['settings-facilitator-levels'],
    queryFn: () => apiClient.get<{ data: FacilitatorLevel[] }>('/settings/facilitator-levels'),
  })

  useEffect(() => {
    if (data?.data) setLevels(data.data)
  }, [data])

  function updateLevel(index: number, field: keyof FacilitatorLevel, value: string | number) {
    setLevels((prev) => prev.map((l, i) => i === index ? { ...l, [field]: value } : l))
  }

  async function handleSave() {
    setIsSubmitting(true)
    try {
      await apiClient.put('/settings/facilitator-levels', {
        levels: levels.map((l, i) => ({ level: l.level ?? i + 1, name: l.name, fee_per_session: l.fee_per_session })),
      })
      await queryClient.invalidateQueries({ queryKey: ['settings-facilitator-levels'] })
      toast.success('Level fasilitator berhasil disimpan')
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Gagal menyimpan level fasilitator')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 'var(--font-sm)' }}>
        <thead>
          <tr style={{ borderBottom: '1px solid var(--color-border)' }}>
            <th style={{ textAlign: 'left', padding: '8px 12px', fontWeight: 600 }}>Nama Level</th>
            <th style={{ textAlign: 'left', padding: '8px 12px', fontWeight: 600 }}>Fee per Sesi (Rp)</th>
          </tr>
        </thead>
        <tbody>
          {levels.length === 0 ? (
            <tr>
              <td colSpan={2} style={{ padding: '16px 12px', color: 'var(--color-text-tertiary)', textAlign: 'center' }}>
                Belum ada level fasilitator
              </td>
            </tr>
          ) : (
            levels.map((level, i) => (
              <tr key={i} style={{ borderBottom: '1px solid var(--color-border-subtle)' }}>
                <td style={{ padding: '8px 12px' }}>
                  <input
                    type="text"
                    value={level.name}
                    onChange={(e) => updateLevel(i, 'name', e.target.value)}
                    className={formStyles.input}
                  />
                </td>
                <td style={{ padding: '8px 12px' }}>
                  <input
                    type="number"
                    min={0}
                    value={level.fee_per_session}
                    onChange={(e) => updateLevel(i, 'fee_per_session', parseInt(e.target.value) || 0)}
                    className={formStyles.input}
                  />
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
      <div>
        <button
          type="button"
          onClick={handleSave}
          disabled={isSubmitting}
          style={{
            padding: '8px 20px', borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary)', color: '#fff',
            border: 'none', cursor: isSubmitting ? 'not-allowed' : 'pointer',
            fontWeight: 600, fontSize: 'var(--font-sm)',
          }}
        >
          {isSubmitting ? 'Menyimpan...' : 'Simpan'}
        </button>
      </div>
    </div>
  )
}

const EMPTY_HOLIDAY = { date: '', name: '' }

function HolidaysTab() {
  const queryClient = useQueryClient()
  const [year, setYear] = useState(new Date().getFullYear())
  const [modalOpen, setModalOpen] = useState(false)
  const [form, setForm] = useState(EMPTY_HOLIDAY)

  const { data, isLoading } = useQuery({
    queryKey: ['settings-holidays', year],
    queryFn: () => apiClient.get<{ data: Holiday[] }>(`/settings/holidays?year=${year}`),
  })

  const holidays = data?.data ?? []

  const createMutation = useMutation({
    mutationFn: (payload: typeof EMPTY_HOLIDAY) => apiClient.post('/settings/holidays', payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings-holidays', year] })
      toast.success('Hari libur berhasil ditambahkan')
      setModalOpen(false)
      setForm(EMPTY_HOLIDAY)
    },
    onError: (err: Error) => toast.error(err.message),
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiClient.delete(`/settings/holidays/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings-holidays', year] })
      toast.success('Hari libur berhasil dihapus')
    },
    onError: (err: Error) => toast.error(err.message),
  })

  const TABLE_STYLE: React.CSSProperties = { width: '100%', borderCollapse: 'collapse', fontSize: 'var(--font-sm)' }
  const TH_STYLE: React.CSSProperties = { textAlign: 'left', padding: '8px 12px', fontWeight: 600, borderBottom: '1px solid var(--color-border)' }
  const TD_STYLE: React.CSSProperties = { padding: '8px 12px', borderBottom: '1px solid var(--color-border-subtle)' }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
          <label style={{ fontSize: 'var(--font-sm)', fontWeight: 500 }}>Tahun:</label>
          <select
            value={year}
            onChange={(e) => setYear(Number(e.target.value))}
            className={formStyles.input}
            style={{ width: 'auto' }}
          >
            {Array.from({ length: 5 }, (_, i) => new Date().getFullYear() - 1 + i).map((y) => (
              <option key={y} value={y}>{y}</option>
            ))}
          </select>
        </div>
        <button
          type="button"
          onClick={() => setModalOpen(true)}
          style={{
            display: 'flex', alignItems: 'center', gap: '6px',
            padding: '8px 16px', borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary)', color: '#fff',
            border: 'none', cursor: 'pointer', fontWeight: 600, fontSize: 'var(--font-sm)',
          }}
        >
          <Plus size={16} /> Tambah Hari Libur
        </button>
      </div>

      {isLoading ? (
        <p style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>Memuat...</p>
      ) : (
        <table style={TABLE_STYLE}>
          <thead>
            <tr>
              <th style={TH_STYLE}>Tanggal</th>
              <th style={TH_STYLE}>Nama</th>
              <th style={{ ...TH_STYLE, width: '60px' }}></th>
            </tr>
          </thead>
          <tbody>
            {holidays.length === 0 ? (
              <tr>
                <td colSpan={3} style={{ ...TD_STYLE, color: 'var(--color-text-tertiary)', textAlign: 'center' }}>
                  Belum ada hari libur untuk tahun {year}
                </td>
              </tr>
            ) : (
              holidays.map((h) => (
                <tr key={h.id}>
                  <td style={TD_STYLE}>{h.date}</td>
                  <td style={TD_STYLE}>{h.name}</td>
                  <td style={TD_STYLE}>
                    <button
                      type="button"
                      onClick={() => deleteMutation.mutate(h.id)}
                      disabled={deleteMutation.isPending}
                      style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-danger)', padding: 4 }}
                      title="Hapus"
                    >
                      <Trash2 size={15} />
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      )}

      <Modal isOpen={modalOpen} onClose={() => { setModalOpen(false); setForm(EMPTY_HOLIDAY) }} title="Tambah Hari Libur" size="sm">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' }}>
          <Field label="Tanggal" required>
            <input
              type="date"
              value={form.date}
              onChange={(e) => setForm((p) => ({ ...p, date: e.target.value }))}
              className={formStyles.input}
            />
          </Field>
          <Field label="Nama Hari Libur" required>
            <input
              type="text"
              value={form.name}
              placeholder="contoh: Hari Kemerdekaan RI"
              onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
              className={formStyles.input}
            />
          </Field>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-2)' }}>
            <button
              type="button"
              onClick={() => { setModalOpen(false); setForm(EMPTY_HOLIDAY) }}
              style={{ padding: '8px 16px', borderRadius: 'var(--radius-md)', background: 'var(--color-surface-alt)', border: '1px solid var(--color-border)', cursor: 'pointer', fontSize: 'var(--font-sm)' }}
            >
              Batal
            </button>
            <button
              type="button"
              onClick={() => createMutation.mutate(form)}
              disabled={!form.date || !form.name || createMutation.isPending}
              style={{ padding: '8px 16px', borderRadius: 'var(--radius-md)', background: 'var(--color-primary)', color: '#fff', border: 'none', cursor: 'pointer', fontWeight: 600, fontSize: 'var(--font-sm)' }}
            >
              {createMutation.isPending ? 'Menyimpan...' : 'Simpan'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  )
}

export default function SettingsPage() {
  const navigate = useNavigate()

  function noop(e: React.FormEvent) {
    e.preventDefault()
  }

  return (
    <FormPageTemplate
      title="Pengaturan Sistem"
      icon={<Settings size={24} />}
      onBack={() => navigate('/dashboard')}
      onSubmit={noop}
      onCancel={() => navigate('/dashboard')}
      readonly
      tabs={[
        {
          id: 'commission',
          label: 'Komisi',
          content: <CommissionTab />,
        },
        {
          id: 'facilitator-levels',
          label: 'Level Fasilitator',
          content: <FacilitatorLevelsTab />,
        },
        {
          id: 'holidays',
          label: 'Hari Libur',
          content: <HolidaysTab />,
        },
      ]}
    />
  )
}
