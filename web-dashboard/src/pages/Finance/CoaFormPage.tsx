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
import { SearchableSelect } from '@/widgets/SearchableSelect/SearchableSelect'
import type { SelectOption } from '@/widgets/SearchableSelect/SearchableSelect'
import { toast } from '@/widgets/Toast/Toast'
import { accountingService } from '@/services/accounting.service'
import { apiClient } from '@/services/api.client'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

function flattenCoaForSelect(nodes: any[]): any[] {
  return nodes.flatMap(n => [n, ...flattenCoaForSelect(n.children ?? [])])
}

const TYPE_OPTIONS = [
  { value: 'asset', label: 'Aset' },
  { value: 'liability', label: 'Kewajiban' },
  { value: 'equity', label: 'Ekuitas' },
  { value: 'revenue', label: 'Pendapatan' },
  { value: 'expense', label: 'Beban' },
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
  const [parentId, setParentId] = useState('')
  const [parentLabel, setParentLabel] = useState('')
  const [description, setDescription] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: accounts } = useQuery({
    queryKey: ['coa'],
    queryFn: () => accountingService.getCoaTree(),
  })

  const { data: coaItem } = useQuery({
    queryKey: ['coa', id],
    queryFn: async () => {
      const all = await accountingService.getCoaTree()
      const roots: any[] = Array.isArray(all) ? all : (all as any)?.items ?? []
      const items = flattenCoaForSelect(roots)
      return items.find((a: any) => a.id === id) ?? null
    },
    enabled: isEdit,
  })

  // Populate form on edit
  if (isEdit && coaItem && code === '' && !isSubmitting) {
    setCode(coaItem.code ?? '')
    setName(coaItem.name ?? '')
    setType(coaItem.type ?? '')
    setParentId(coaItem.parent_id ?? '')
    setDescription(coaItem.description ?? '')
  }

  const accountRoots: any[] = Array.isArray(accounts) ? accounts : (accounts as any)?.items ?? []
  const allAccounts: any[] = flattenCoaForSelect(accountRoots)

  async function fetchParentOptions(search: string): Promise<SelectOption[]> {
    const q = search.toLowerCase()
    return allAccounts
      .filter(a => a.id !== id)
      .filter(a => !q || a.code?.toLowerCase().includes(q) || a.name?.toLowerCase().includes(q))
      .slice(0, 50)
      .map(a => ({ value: a.id, label: a.name, meta: a.code }))
  }

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!code.trim()) e.code = 'Kode akun wajib diisi'
    if (!name.trim()) e.name = 'Nama akun wajib diisi'
    if (!type) e.type = 'Jenis akun wajib dipilih'
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
        parent_id: parentId || undefined,
      }

      if (isEdit) {
        await apiClient.put(`/finance/coa/${id}`, payload)
        toast.success('Akun berhasil diperbarui')
      } else {
        await apiClient.post('/finance/coa', payload)
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
                <Field label="Kode Akun" required error={errors.code} hint="Gunakan format hierarki, cth. 1100, 1110">
                  <input
                    type="text"
                    value={code}
                    onChange={(e) => setCode(e.target.value)}
                    placeholder="cth. 1110"
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
              </FormColumn>
              <FormColumn>
                <Field label="Akun Induk" hint="Opsional. Pilih akun induk jika ini adalah sub-akun.">
                  <SearchableSelect
                    value={parentId}
                    displayLabel={parentLabel}
                    placeholder="Cari akun induk..."
                    fetchOptions={fetchParentOptions}
                    onSelect={(opt) => {
                      setParentId(opt?.value ?? '')
                      setParentLabel(opt ? `${opt.meta} — ${opt.label}` : '')
                    }}
                  />
                </Field>
                <Field label="Deskripsi" hint="Opsional. Jelaskan kegunaan akun ini.">
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Jelaskan kegunaan akun ini..."
                    rows={5}
                    className={formStyles.textarea}
                  />
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
