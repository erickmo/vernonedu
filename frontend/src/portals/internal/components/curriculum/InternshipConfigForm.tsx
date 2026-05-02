import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import {
  upsertInternshipConfigSchema,
  type UpsertInternshipConfigInput,
} from '@/schemas/internshipconfig'
import {
  useInternshipConfig,
  useUpsertInternshipConfig,
} from '@/lib/api/curriculum'

interface Props {
  versionId: string
  locked: boolean
}

const EMPTY: UpsertInternshipConfigInput = {
  partner_company_name: '',
  partner_company_id: '',
  position_title: '',
  duration_weeks: 4,
  supervisor_name: '',
  supervisor_contact: '',
  mou_document_url: '',
  is_company_provided: false,
}

export default function InternshipConfigForm({ versionId, locked }: Props) {
  const { data, isLoading } = useInternshipConfig(versionId)
  const upsert = useUpsertInternshipConfig(versionId)

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting, isDirty },
  } = useForm<UpsertInternshipConfigInput>({
    resolver: zodResolver(upsertInternshipConfigSchema),
    defaultValues: EMPTY,
  })

  useEffect(() => {
    if (data) {
      reset({
        partner_company_name: data.partner_company_name,
        partner_company_id: data.partner_company_id ?? '',
        position_title: data.position_title,
        duration_weeks: data.duration_weeks,
        supervisor_name: data.supervisor_name,
        supervisor_contact: data.supervisor_contact,
        mou_document_url: data.mou_document_url,
        is_company_provided: data.is_company_provided,
      })
    }
  }, [data, reset])

  async function onSubmit(values: UpsertInternshipConfigInput) {
    try {
      await upsert.mutateAsync(values)
      toast.success('Internship config saved')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to save internship config')
    }
  }

  if (isLoading) return <LoadingSpinner size="md" />

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-3 bg-white border border-neutral-200 rounded-xl p-5">
      <h4 className="font-semibold text-neutral-900">Internship</h4>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Partner Company" required error={errors.partner_company_name?.message}>
          <Input {...register('partner_company_name')} disabled={locked} />
        </FormField>
        <FormField label="Position Title" required error={errors.position_title?.message}>
          <Input {...register('position_title')} disabled={locked} />
        </FormField>
        <FormField label="Duration (weeks)" required error={errors.duration_weeks?.message}>
          <Input type="number" min={1} {...register('duration_weeks', { valueAsNumber: true })} disabled={locked} />
        </FormField>
        <FormField label="Supervisor Name" error={errors.supervisor_name?.message}>
          <Input {...register('supervisor_name')} disabled={locked} />
        </FormField>
        <FormField label="Supervisor Contact" error={errors.supervisor_contact?.message}>
          <Input {...register('supervisor_contact')} disabled={locked} />
        </FormField>
        <FormField label="MOU Document URL" error={errors.mou_document_url?.message}>
          <Input {...register('mou_document_url')} placeholder="https://..." disabled={locked} />
        </FormField>
      </div>

      <label className="flex items-center gap-2 text-sm text-neutral-700">
        <input type="checkbox" {...register('is_company_provided')} disabled={locked} />
        Is company provided
      </label>

      <div className="flex justify-end pt-2 border-t border-neutral-100">
        {locked ? (
          <span className="text-xs text-neutral-500">🔒 Read-only</span>
        ) : (
          <RoleGate action="update" resource="internshipconfig">
            <Button type="submit" loading={isSubmitting} disabled={isSubmitting || !isDirty}>
              Save Internship
            </Button>
          </RoleGate>
        )}
      </div>
    </form>
  )
}
