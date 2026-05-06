import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Store } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { franchiseeService } from '@/services/franchisee.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

const STATUS_OPTIONS = [
  { value: 'active',     label: 'Aktif' },
  { value: 'inactive',   label: 'Nonaktif' },
  { value: 'terminated', label: 'Diakhiri' },
]

export default function FranchiseeFormPage() {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(id)

  const [name, setName] = useState('')
  const [branchName, setBranchName] = useState('')
  const [location, setLocation] = useState('')
  const [contact, setContact] = useState('')
  const [status, setStatus] = useState<string>('active')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: franchisee } = useQuery({
    queryKey: ['franchisee', id],
    queryFn: () => franchiseeService.getById(id!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (franchisee) {
      setName(franchisee.name ?? '')
      setBranchName(franchisee.branch_name ?? '')
      setLocation(franchisee.location ?? '')
      setContact(franchisee.contact ?? '')
      setStatus(franchisee.status ?? 'active')
    }
  }, [franchisee])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama franchisee wajib diisi'
    else if (name.trim().length < 2) e.name = 'Minimal 2 karakter'
    if (!branchName.trim()) e.branch_name = 'Nama cabang wajib diisi'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!validate()) return

    setIsSubmitting(true)
    setServerError('')

    const payload = {
      name: name.trim(),
      branch_name: branchName.trim(),
      location: location.trim(),
      contact: contact.trim(),
      status,
    }

    try {
      if (isEdit) {
        await franchiseeService.update(id!, payload)
        toast.success('Franchisee berhasil diperbarui')
        await queryClient.invalidateQueries({ queryKey: ['franchisee', id] })
        navigate(`/pengembangan/franchisees/${id}`)
      } else {
        await franchiseeService.create(payload)
        toast.success('Franchisee berhasil ditambahkan')
        await queryClient.invalidateQueries({ queryKey: ['franchisees'] })
        navigate('/pengembangan/franchisees')
      }
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  function handleCancel() {
    navigate(isEdit ? `/pengembangan/franchisees/${id}` : '/pengembangan/franchisees')
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Franchisee' : 'Tambah Franchisee'}
      icon={<Store size={20} />}
      onBack={handleCancel}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Umum',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Franchisee" required error={errors.name}>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="cth. PT Maju Bersama"
                    className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>

                <Field label="Nama Cabang" required error={errors.branch_name}>
                  <input
                    type="text"
                    value={branchName}
                    onChange={(e) => setBranchName(e.target.value)}
                    placeholder="cth. Cabang Surabaya"
                    className={`${formStyles.input} ${errors.branch_name ? formStyles.inputError : ''}`}
                  />
                </Field>

                <Field label="Lokasi" hint="Kota atau alamat cabang.">
                  <input
                    type="text"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    placeholder="cth. Surabaya, Jawa Timur"
                    className={formStyles.input}
                  />
                </Field>

                <Field label="Kontak" hint="Nomor telepon atau email PIC.">
                  <input
                    type="text"
                    value={contact}
                    onChange={(e) => setContact(e.target.value)}
                    placeholder="cth. 08123456789"
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>

              <FormColumn>
                <Field label="Status">
                  <select
                    value={status}
                    onChange={(e) => setStatus(e.target.value)}
                    className={formStyles.input}
                  >
                    {STATUS_OPTIONS.map((opt) => (
                      <option key={opt.value} value={opt.value}>{opt.label}</option>
                    ))}
                  </select>
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={handleCancel}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
