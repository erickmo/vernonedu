import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { FolderOpen } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { projectService } from '@/services/project.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'
import { DatePicker } from '@/widgets/DatePicker/DatePicker'

const TYPE_OPTIONS = [
  { label: '— Pilih Jenis —', value: '' },
  { label: 'Event', value: 'event' },
  { label: 'Kolaborasi', value: 'collaboration' },
  { label: 'Lainnya', value: 'other' },
]

const STATUS_OPTIONS = [
  { label: 'Direncanakan', value: 'planned' },
  { label: 'Aktif', value: 'active' },
  { label: 'Selesai', value: 'completed' },
  { label: 'Dibatalkan', value: 'cancelled' },
]

export default function ProjectFormPage() {
  const { projectId } = useParams<{ projectId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const isEdit = Boolean(projectId)

  const [name, setName] = useState('')
  const [type, setType] = useState('')
  const [status, setStatus] = useState('planned')
  const [description, setDescription] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [budget, setBudget] = useState('')
  const [partnerId, setPartnerId] = useState('')

  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: project } = useQuery<any>({
    queryKey: ['project', projectId],
    queryFn: () => projectService.getById(projectId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (project) {
      setName(project.name ?? '')
      setType(project.type ?? '')
      setStatus(project.status ?? 'planned')
      setDescription(project.description ?? '')
      setStartDate(project.start_date ?? '')
      setEndDate(project.end_date ?? '')
      setBudget(project.budget ? String(project.budget) : '')
      setPartnerId(project.partner_id ?? '')
    }
  }, [project])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!name.trim()) e.name = 'Nama proyek wajib diisi'
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
        name: name.trim(),
        type: type || undefined,
        status,
        description: description.trim() || undefined,
        start_date: startDate || undefined,
        end_date: endDate || undefined,
        budget: Number(budget) || undefined,
        partner_id: partnerId.trim() || undefined,
      }

      if (isEdit) {
        await projectService.update(projectId!, payload)
        toast.success('Proyek berhasil diperbarui')
      } else {
        await projectService.create(payload)
        toast.success('Proyek berhasil ditambahkan')
      }

      await queryClient.invalidateQueries({ queryKey: ['projects'] })
      navigate(isEdit ? `/projects/${projectId}` : '/projects')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Proyek' : 'Tambah Proyek'}
      icon={<FolderOpen size={20} />}
      onBack={() => navigate(isEdit ? `/projects/${projectId}` : '/projects')}
      tabs={[
        {
          id: 'info',
          label: 'Informasi',
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Proyek" required error={errors.name}>
                  <input
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="cth. Workshop Entrepreneurship 2026"
                    className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Jenis">
                  <select
                    value={type}
                    onChange={(e) => setType(e.target.value)}
                    className={formStyles.input}
                  >
                    {TYPE_OPTIONS.map((opt) => (
                      <option key={opt.value} value={opt.value}>{opt.label}</option>
                    ))}
                  </select>
                </Field>
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
                <Field label="Deskripsi">
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Deskripsi singkat proyek..."
                    rows={3}
                    className={formStyles.textarea}
                  />
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Tanggal Mulai">
                  <DatePicker
                    value={startDate}
                    onChange={val => setStartDate(val)}
                  />
                </Field>
                <Field label="Tanggal Selesai">
                  <DatePicker
                    value={endDate}
                    onChange={val => setEndDate(val)}
                  />
                </Field>
                <Field label="Anggaran" hint="Opsional. Masukkan nilai dalam Rupiah">
                  <input
                    type="number"
                    value={budget}
                    onChange={(e) => setBudget(e.target.value)}
                    placeholder="5000000"
                    className={formStyles.input}
                  />
                </Field>
                <Field label="Partner ID" hint="Opsional. ID partner yang terlibat">
                  <input
                    type="text"
                    value={partnerId}
                    onChange={(e) => setPartnerId(e.target.value)}
                    placeholder="ID partner..."
                    className={formStyles.input}
                  />
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate(isEdit ? `/projects/${projectId}` : '/projects')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
