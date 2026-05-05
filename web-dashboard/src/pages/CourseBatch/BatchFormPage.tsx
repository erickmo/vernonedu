import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Calendar, Info, Settings } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { courseBatchService } from '@/services/course-batch.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

export default function BatchFormPage() {
  const navigate = useNavigate()
  const { batchId } = useParams<{ batchId: string }>()
  const queryClient = useQueryClient()
  const isEdit = Boolean(batchId)

  const [batchName, setBatchName] = useState('')
  const [courseId, setCourseId] = useState('')
  const [facilitatorId, setFacilitatorId] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [price, setPrice] = useState('')
  const [minParticipants, setMinParticipants] = useState('')
  const [maxParticipants, setMaxParticipants] = useState('')
  const [paymentMethod, setPaymentMethod] = useState('upfront')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [serverError, setServerError] = useState('')

  const { data: batch } = useQuery({
    queryKey: ['course-batch', batchId],
    queryFn: () => courseBatchService.getDetail(batchId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (batch) {
      setBatchName(batch.batch_name ?? '')
      setCourseId(batch.course_id ?? '')
      setFacilitatorId(batch.facilitator_id ?? '')
      setPrice(batch.price?.toString() ?? '')
      setMinParticipants(batch.min_participants?.toString() ?? '')
      setMaxParticipants(batch.max_participants?.toString() ?? '')
      setPaymentMethod(batch.payment_method ?? 'upfront')
      if (batch.start_date) {
        setStartDate(new Date(batch.start_date * 1000).toISOString().split('T')[0])
      }
      if (batch.end_date) {
        setEndDate(new Date(batch.end_date * 1000).toISOString().split('T')[0])
      }
    }
  }, [batch])

  function validate(): boolean {
    const e: Record<string, string> = {}
    if (!batchName.trim()) e.batch_name = 'Nama batch wajib diisi'
    else if (batchName.trim().length < 2) e.batch_name = 'Minimal 2 karakter'
    if (!courseId.trim()) e.course_id = 'ID kursus wajib diisi'
    if (!facilitatorId.trim()) e.facilitator_id = 'ID fasilitator wajib diisi'
    if (!startDate) e.start_date = 'Tanggal mulai wajib diisi'
    if (!endDate) e.end_date = 'Tanggal selesai wajib diisi'
    if (new Date(startDate) > new Date(endDate)) {
      e.end_date = 'Tanggal selesai harus setelah tanggal mulai'
    }
    if (!price.trim()) e.price = 'Harga wajib diisi'
    if (Number(price) < 0) e.price = 'Harga tidak boleh negatif'
    if (minParticipants && Number(minParticipants) < 1) {
      e.min_participants = 'Minimal 1 peserta'
    }
    if (maxParticipants && Number(maxParticipants) < Number(minParticipants || 0)) {
      e.max_participants = 'Maksimal harus lebih besar atau sama dengan minimal'
    }
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
        batch_name: batchName.trim(),
        course_id: courseId.trim(),
        facilitator_id: facilitatorId.trim(),
        start_date: new Date(startDate).getTime() / 1000,
        end_date: new Date(endDate).getTime() / 1000,
        price: Number(price),
        min_participants: minParticipants ? Number(minParticipants) : undefined,
        max_participants: maxParticipants ? Number(maxParticipants) : undefined,
        payment_method: paymentMethod,
      }
      if (isEdit) {
        await courseBatchService.list({ action: 'update', batch_id: batchId!, ...payload })
        toast.success('Batch kelas berhasil diperbarui')
      } else {
        await courseBatchService.create(payload)
        toast.success('Batch kelas berhasil dibuat')
      }
      await queryClient.invalidateQueries({ queryKey: ['course-batches'] })
      navigate(isEdit ? `/course-batches/${batchId}` : '/course-batches')
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'Gagal menyimpan data')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <FormPageTemplate
      title={isEdit ? 'Edit Batch Kelas' : 'Tambah Batch Kelas'}
      icon={<Calendar size={20} />}
      onBack={() => navigate(isEdit ? `/course-batches/${batchId}` : '/course-batches')}
      tabs={[
        {
          id: 'general',
          label: 'Informasi Umum',
          icon: <Info size={14} />,
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Nama Batch" required error={errors.batch_name}>
                  <input
                    type="text"
                    value={batchName}
                    onChange={(e) => setBatchName(e.target.value)}
                    placeholder="cth. Batch Technology 2024-Q1"
                    className={`${formStyles.input} ${errors.batch_name ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field label="ID Kursus" required error={errors.course_id} hint="Masukkan ID kursus yang akan dibuatkan batch.">
                  <input
                    type="text"
                    value={courseId}
                    onChange={(e) => setCourseId(e.target.value)}
                    placeholder="cth. COURSE-001"
                    className={`${formStyles.input} ${errors.course_id ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="ID Fasilitator" required error={errors.facilitator_id} hint="Masukkan ID fasilitator yang akan mengajar.">
                  <input
                    type="text"
                    value={facilitatorId}
                    onChange={(e) => setFacilitatorId(e.target.value)}
                    placeholder="cth. FACIL-001"
                    className={`${formStyles.input} ${errors.facilitator_id ? formStyles.inputError : ''}`}
                  />
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Tanggal Mulai" required error={errors.start_date}>
                  <input
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    className={`${formStyles.input} ${errors.start_date ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Tanggal Selesai" required error={errors.end_date}>
                  <input
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    className={`${formStyles.input} ${errors.end_date ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Harga (IDR)" required error={errors.price}>
                  <input
                    type="number"
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                    placeholder="5000000"
                    min="0"
                    step="100000"
                    className={`${formStyles.input} ${errors.price ? formStyles.inputError : ''}`}
                  />
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
        {
          id: 'settings',
          label: 'Pengaturan',
          icon: <Settings size={14} />,
          content: (
            <FormGrid>
              <FormColumn>
                <Field label="Metode Pembayaran" hint="Pilih cara siswa membayar kursus ini.">
                  <select
                    value={paymentMethod}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                    className={formStyles.input}
                  >
                    <option value="upfront">Pembayaran Penuh (Upfront)</option>
                    <option value="scheduled">Terjadwal (Scheduled)</option>
                    <option value="monthly">Bulanan (Monthly)</option>
                    <option value="batch_lump">Sekaligus (Batch Lump)</option>
                    <option value="per_session">Per Sesi (Per Session)</option>
                  </select>
                </Field>
              </FormColumn>
              <FormColumn>
                <Field label="Minimal Peserta" error={errors.min_participants} hint="Opsional. Jika 0, tidak ada batasan minimal.">
                  <input
                    type="number"
                    value={minParticipants}
                    onChange={(e) => setMinParticipants(e.target.value)}
                    placeholder="5"
                    min="0"
                    className={`${formStyles.input} ${errors.min_participants ? formStyles.inputError : ''}`}
                  />
                </Field>
                <Field label="Maksimal Peserta" error={errors.max_participants} hint="Opsional. Jika kosong, tidak ada batasan maksimal.">
                  <input
                    type="number"
                    value={maxParticipants}
                    onChange={(e) => setMaxParticipants(e.target.value)}
                    placeholder="30"
                    min="0"
                    className={`${formStyles.input} ${errors.max_participants ? formStyles.inputError : ''}`}
                  />
                </Field>
              </FormColumn>
            </FormGrid>
          ),
        },
      ]}
      onSubmit={handleSubmit}
      onCancel={() => navigate(isEdit ? `/course-batches/${batchId}` : '/course-batches')}
      isSubmitting={isSubmitting}
      serverError={serverError}
    />
  )
}
