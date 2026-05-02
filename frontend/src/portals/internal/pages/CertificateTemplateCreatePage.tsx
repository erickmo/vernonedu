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
  createCertificateTemplateSchema,
  CERT_TYPES,
  type CreateCertificateTemplateInput,
} from '@/schemas/certificatetemplate'
import { useCreateCertificateTemplate } from '@/lib/api/certificate'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Academic', to: '/internal/academic' },
  { label: 'Certificate Templates', to: '/internal/certificate-templates' },
  { label: 'New Template' },
]

const DEFAULT_TEMPLATE_DATA = `{
  "title": "Certificate of Participant",
  "background_url": "",
  "fields": []
}`

export default function CertificateTemplateCreatePage() {
  const navigate = useNavigate()
  const create = useCreateCertificateTemplate()

  const {
    register, handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateCertificateTemplateInput>({
    resolver: zodResolver(createCertificateTemplateSchema),
    defaultValues: {
      name: '',
      type: 'participant',
      template_data: DEFAULT_TEMPLATE_DATA,
    },
  })

  async function onSubmit(values: CreateCertificateTemplateInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Certificate template created')
      navigate('/internal/certificate-templates')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create template')
    }
  }

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Add Certificate Template"
      subtitle="Define a new certificate template"
    >
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Name" required error={errors.name?.message}>
          <Input {...register('name')} placeholder="Default Participant" />
        </FormField>

        <FormField label="Type" required error={errors.type?.message}>
          <Select {...register('type')}>
            {CERT_TYPES.map((t) => (
              <option key={t} value={t} className="capitalize">{t}</option>
            ))}
          </Select>
        </FormField>

        <FormField label="Template Data (JSON)" required error={errors.template_data?.message}>
          <Textarea {...register('template_data')} rows={10} className="font-mono text-xs" />
        </FormField>

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/certificate-templates')}>
            Cancel
          </Button>
          <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
            Save
          </Button>
        </div>
      </form>
    </StandardPageLayout>
  )
}
