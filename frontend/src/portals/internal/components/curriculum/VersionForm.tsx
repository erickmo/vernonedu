import { useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import {
  createCourseVersionSchema,
  CHANGE_TYPES,
  nextVersion,
  type CreateCourseVersionInput,
} from '@/schemas/courseversion'
import { useCreateCourseVersion } from '@/lib/api/curriculum'
import type { CourseVersion, ChangeType } from '@/types/courseversion'

interface Props {
  typeId: string
  latestVersion?: CourseVersion
  onSuccess: () => void
  onCancel: () => void
}

export default function VersionForm({ typeId, latestVersion, onSuccess, onCancel }: Props) {
  const create = useCreateCourseVersion(typeId)
  const [manual, setManual] = useState(false)

  const baseVersion = latestVersion?.version_number ?? '0.0.0'

  const {
    register, handleSubmit, watch, setValue,
    formState: { errors, isSubmitting },
  } = useForm<CreateCourseVersionInput>({
    resolver: zodResolver(createCourseVersionSchema),
    defaultValues: {
      change_type: 'patch',
      version_number: nextVersion(baseVersion, 'patch'),
      changelog: '',
    },
  })

  const changeType = watch('change_type') as ChangeType

  useEffect(() => {
    if (!manual) {
      setValue('version_number', nextVersion(baseVersion, changeType), { shouldValidate: true })
    }
  }, [changeType, manual, baseVersion, setValue])

  async function onSubmit(values: CreateCourseVersionInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Version created')
      onSuccess()
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create version')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <h3 className="font-semibold text-neutral-900">New Version</h3>

      <FormField label="Change Type" required error={errors.change_type?.message}>
        <Select {...register('change_type')}>
          {CHANGE_TYPES.map((c) => <option key={c} value={c}>{c}</option>)}
        </Select>
      </FormField>

      <FormField label="Version Number" required error={errors.version_number?.message}>
        <div className="flex gap-2">
          <Input
            {...register('version_number')}
            readOnly={!manual}
            className={!manual ? 'bg-neutral-50' : undefined}
          />
          <Button type="button" variant="secondary" size="sm" onClick={() => setManual((m) => !m)}>
            {manual ? 'Auto' : 'Edit manually'}
          </Button>
        </div>
        {!manual && (
          <p className="text-xs text-neutral-500 mt-1">
            Auto-suggested from {baseVersion}. Click "Edit manually" to override.
          </p>
        )}
      </FormField>

      <FormField label="Changelog" required error={errors.changelog?.message}>
        <Textarea
          {...register('changelog')}
          rows={6}
          placeholder="Describe what changed in this version (min 10 characters)"
        />
      </FormField>

      <div className="flex gap-2 pt-2 border-t border-neutral-100">
        <Button type="button" variant="secondary" onClick={onCancel}>Cancel</Button>
        <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>Create</Button>
      </div>
    </form>
  )
}
