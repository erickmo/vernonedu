import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import {
  issueCertificateSchema,
  CERTIFICATE_TYPES,
  type IssueCertificateInput,
} from '@/schemas/certificate'
import { useIssueCertificate } from '@/lib/api/certificate-issue'
import { useCertificateTemplates } from '@/lib/api/certificate'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Academic', to: '/internal/academic' },
  { label: 'Certificates', to: '/internal/certificates' },
  { label: 'Issue Certificate' },
]

export default function CertificateIssuePage() {
  const navigate = useNavigate()
  const issue = useIssueCertificate()
  const { data: templates, isLoading: templatesLoading } = useCertificateTemplates()

  const {
    register, handleSubmit, watch,
    formState: { errors, isSubmitting },
  } = useForm<IssueCertificateInput>({
    resolver: zodResolver(issueCertificateSchema),
    defaultValues: {
      template_id: '',
      student_id: '',
      batch_id: '',
      course_id: '',
      type: 'participant',
      verification_base_url: '',
      notes: '',
    },
  })

  const selectedType = watch('type')
  const filteredTemplates = (templates ?? []).filter((t) => !selectedType || t.type === selectedType)

  async function onSubmit(values: IssueCertificateInput) {
    try {
      await issue.mutateAsync(values)
      toast.success('Certificate issued')
      navigate('/internal/certificates')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to issue certificate')
    }
  }

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Issue Certificate"
      subtitle="Generate a new certificate for a student"
    >
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4"
      >
        <FormField label="Type" required error={errors.type?.message}>
          <Select {...register('type')}>
            {CERTIFICATE_TYPES.map((t) => (
              <option key={t} value={t} className="capitalize">{t}</option>
            ))}
          </Select>
        </FormField>

        <FormField label="Template" required error={errors.template_id?.message}>
          <Select {...register('template_id')} disabled={templatesLoading}>
            <option value="">Select template</option>
            {filteredTemplates.map((t) => (
              <option key={t.id} value={t.id}>{t.name}</option>
            ))}
          </Select>
        </FormField>

        <FormField label="Student ID" required error={errors.student_id?.message}>
          <Input {...register('student_id')} placeholder="UUID of student" />
        </FormField>

        <FormField label="Batch ID" required error={errors.batch_id?.message}>
          <Input {...register('batch_id')} placeholder="UUID of course batch" />
        </FormField>

        <FormField label="Course ID" required error={errors.course_id?.message}>
          <Input {...register('course_id')} placeholder="UUID of master course" />
        </FormField>

        <FormField label="Verification Base URL" error={errors.verification_base_url?.message}>
          <Input
            {...register('verification_base_url')}
            placeholder="https://verify.vernon.edu"
          />
        </FormField>

        <FormField label="Notes" error={errors.notes?.message}>
          <Textarea {...register('notes')} rows={3} placeholder="Optional internal notes" />
        </FormField>

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/certificates')}>
            Cancel
          </Button>
          <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
            Issue
          </Button>
        </div>
      </form>
    </StandardPageLayout>
  )
}
