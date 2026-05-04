import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { BookOpen } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { accountingService } from '@/services/accounting.service'
import { apiClient } from '@/services/api.client'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const TYPE_OPTIONS = [
  { value: 'aset', label: 'Aset' },
  { value: 'kewajiban', label: 'Kewajiban' },
  { value: 'ekuitas', label: 'Ekuitas' },
  { value: 'pendapatan', label: 'Pendapatan' },
  { value: 'beban', label: 'Beban' },
]

const BALANCE_OPTIONS = [
  { value: 'debit', label: 'Debit' },
  { value: 'kredit', label: 'Kredit' },
]

export default function CoaFormPage() {
  const navigate = useNavigate()
  const { coaId } = useParams<{ coaId: string }>()
  const id = coaId
  const queryClient = useQueryClient()
  const isEdit = Boolean(id)

  const [code, setCode] = useState('')
  const [name, setName] = useState('')
  const [type, setType] = useState('')
  const [normalBalance, setNormalBalance] = useState('')
  const [parentId, setParentId] = useState('')
  const [description, setDescription] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: accounts } = useQuery({
    queryKey: ['coa'],
    queryFn: () => accountingService.listCoa(),
  })

  const { data: coaItem } = useQuery({
    queryKey: ['coa', id],
    queryFn: async () => {
      const all = await accountingService.listCoa()
      const items: any[] = Array.isArray(all) ? all : (all as any)?.items ?? []
      return items.find((a: any) => a.id === id) ?? null
    },
    enabled: isEdit,
  })

  // Populate form on edit
  if (isEdit && coaItem && code === '' && !isSubmitting) {
    setCode(coaItem.code ?? '')
    setName(coaItem.name ?? '')
    setType(coaItem.type ?? '')
    setNormalBalance(coaItem.normal_balance ?? '')
    setParentId(coaItem.parent_id ?? '')
    setDescription(coaItem.description ?? '')
  }

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!code.trim()) e.code = 'Kode akun wajib diisi'
    if (!name.trim()) e.name = 'Nama akun wajib diisi'
    if (!type) e.type = 'Jenis akun wajib dipilih'
    if (!normalBalance) e.normal_balance = 'Saldo normal wajib dipilih'
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
        code: code.trim(),
        name: name.trim(),
        type,
        normal_balance: normalBalance,
        parent_id: parentId.trim() || undefined,
        description: description.trim() || undefined,
      }

      if (isEdit) {
        await apiClient.put(`/accounting/coa/${id}`, payload)
        toast.success('Akun berhasil diperbarui')
      } else {
        await apiClient.post('/accounting/coa', payload)
        toast.success('Akun berhasil dibuat')
      }

      await queryClient.invalidateQueries({ queryKey: ['coa'] })
      navigate('/finance/chart-of-accounts')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  const allAccounts: any[] = Array.isArray(accounts) ? accounts : (accounts as any)?.items ?? []

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Akun' : 'Tambah Akun'}
      icon={<BookOpen size={20} />}
      onBack={() => navigate('/finance/chart-of-accounts')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Akun',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Kode Akun" required error={errors.code}>
                  <input
                    type="text"
                    value={code}
                    onChange={(e) => setCode(e.target.value)}
                    placeholder="cth. 1.1.01"
                    className={`${formStyles.input} ${formStyles.inputMono} ${errors.code ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field label="Nama Akun" required error={errors.name}>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="cth. Kas Kecil"
                    className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Jenis Akun" required error={errors.type}>
                  <select
                    value={type}
                    onChange={(e) => setType(e.target.value)}
                    className={`${formStyles.input} ${errors.type ? formStyles.inputError : ''}`}
                  >
                    <option value="">Pilih jenis akun...</option>
                    {TYPE_OPTIONS.map((opt) => (
                      <option key={opt.value} value={opt.value}>{opt.label}</option>
                    ))}
                  </select>
                </Field>
                <Field label="Saldo Normal" required error={errors.normal_balance}>
                  <select
                    value={normalBalance}
                    onChange={(e) => setNormalBalance(e.target.value)}
                    className={`${formStyles.input} ${errors.normal_balance ? formStyles.inputError : ''}`}
                  >
                    <option value="">Pilih saldo normal...</option>
                    {BALANCE_OPTIONS.map((opt) => (
                      <option key={opt.value} value={opt.value}>{opt.label}</option>
                    ))}
                  </select>
                </Field>
                <Field label="Deskripsi" hint="Opsional. Jelaskan kegunaan akun ini.">
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Jelaskan kegunaan akun ini..."
                    rows={4}
                    className={formStyles.textarea}
                  />
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Akun Induk" hint="Opsional. Pilih akun induk jika ini adalah sub-akun.">
                  <select
                    value={parentId}
                    onChange={(e) => setParentId(e.target.value)}
                    className={formStyles.input}
                  >
                    <option value="">Tanpa akun induk (akun utama)</option>
                    {allAccounts
                      .filter((a) => a.id !== id)
                      .map((a) => (
                        <option key={a.id} value={a.id}>
                          {a.code} — {a.name}
                        </option>
                      ))}
                  </select>
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate('/finance/chart-of-accounts')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
