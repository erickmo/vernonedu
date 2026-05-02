import { useEffect, useMemo } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import {
  updateCertificateTemplateSchema,
  CERT_TYPES,
  type UpdateCertificateTemplateInput,
} from '@/schemas/certificatetemplate'
import {
  useCertificateTemplates,
  useUpdateCertificateTemplate,
} from '@/lib/api/certificate'

export default function CertificateTemplateEditPage() {
  const navigate = useNavigate()
  const { id = '' } = useParams<{ id: string }>()
  const { data: list, isLoading } = useCertificateTemplates()
  const update = useUpdateCertificateTemplate(id)

  const template = useMemo(
    () => (list ?? []).find((t) => t.id === id),
    [list, id],
  )

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateCertificateTemplateInput>({
    resolver: zodResolver(updateCertificateTemplateSchema),
  })

  useEffect(() => {
    if (template) {
      reset({
        name: template.name,
        type: template.type,
        template_data: JSON.stringify(template.template_data ?? {}, null, 2),
      })
    }
  }, [template, reset])

  async function onSubmit(values: UpdateCertificateTemplateInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Certificate template updated')
      navigate('/internal/certificate-templates')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update template')
    }
  }

  if (isLoading || !template) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Academic', to: '/internal/academic' },
    { label: 'Certificate Templates', to: '/internal/certificate-templates' },
    { label: template.name },
    { label: 'Edit' },
  ]

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Edit Certificate Template"
      subtitle={template.name}
    >
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Name" required error={errors.name?.message}>
          <Input {...register('name')} />
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

        <div className="flex gap-2 pt-2 border-t border-neutral-100">
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
