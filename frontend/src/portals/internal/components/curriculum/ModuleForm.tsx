import { useEffect } from 'react'
import { useForm, Controller, type Resolver } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import MultiInput from '@/components/shared/MultiInput'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import {
  createCourseModuleSchema,
  updateCourseModuleSchema,
  type CreateCourseModuleInput,
  type UpdateCourseModuleInput,
} from '@/schemas/coursemodule'
import {
  useCreateCourseModule,
  useUpdateCourseModule,
  useCourseVersions,
  useCourseModules,
} from '@/lib/api/curriculum'
import type { CourseModule } from '@/types/coursemodule'

type Mode =
  | { kind: 'create'; defaultSequence: number }
  | { kind: 'edit'; module: CourseModule }

interface Props {
  versionId: string
  /** Optional: courseTypeId to enable reference module selection across all versions of this type. */
  courseTypeId?: string
  mode: Mode
  onSuccess: () => void
  onCancel: () => void
}

const EMPTY_CREATE: CreateCourseModuleInput = {
  module_code: '',
  module_title: '',
  duration_hours: 0,
  sequence: 1,
  content_depth: '',
  topics: [],
  practical_activities: [],
  assessment_method: '',
  tools_required: [],
  requirements: [],
  is_reference: false,
  ref_module_id: null,
}

function moduleToUpdate(m: CourseModule): UpdateCourseModuleInput {
  return {
    module_title: m.module_title,
    duration_hours: m.duration_hours,
    sequence: m.sequence,
    content_depth: m.content_depth,
    topics: m.topics,
    practical_activities: m.practical_activities,
    assessment_method: m.assessment_method,
    tools_required: m.tools_required,
    requirements: m.requirements,
  }
}

type FormValues = CreateCourseModuleInput

/**
 * Fetch reference module candidates from a sibling version of the same course type.
 * To stay within hook rules, we only query modules of the FIRST sibling version.
 */
function useReferenceCandidates(
  courseTypeId: string | undefined,
  excludeVersionId: string,
): { id: string; label: string }[] {
  const { data: versions } = useCourseVersions(courseTypeId)
  const sibling = (versions ?? []).find((v) => v.id !== excludeVersionId)
  const { data: modules } = useCourseModules(sibling?.id)
  if (!sibling || !modules) return []
  return modules
    .filter((m) => !m.is_reference)
    .map((m) => ({
      id: m.id,
      label: `${m.module_code} — ${m.module_title}`,
    }))
}

export default function ModuleForm({
  versionId,
  courseTypeId,
  mode,
  onSuccess,
  onCancel,
}: Props) {
  const create = useCreateCourseModule(versionId)
  const update = useUpdateCourseModule(versionId)
  const isEdit = mode.kind === 'edit'

  const resolver = (isEdit
    ? zodResolver(updateCourseModuleSchema)
    : zodResolver(createCourseModuleSchema)) as unknown as Resolver<FormValues>

  const defaults: FormValues = isEdit
    ? { ...EMPTY_CREATE, ...moduleToUpdate(mode.module) }
    : { ...EMPTY_CREATE, sequence: mode.defaultSequence }

  const {
    register,
    handleSubmit,
    control,
    watch,
    reset,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver, defaultValues: defaults })

  useEffect(() => {
    if (isEdit) reset({ ...EMPTY_CREATE, ...moduleToUpdate(mode.module) })
    else reset({ ...EMPTY_CREATE, sequence: mode.defaultSequence })
  }, [mode, reset, isEdit])

  const isReference = !isEdit && watch('is_reference')

  // Keep a ref of selected sibling version (extension point)
  const refCandidates = useReferenceCandidates(courseTypeId, versionId)

  async function onSubmit(values: FormValues) {
    try {
      if (isEdit) {
        const updateValues = moduleToUpdate({ ...mode.module, ...values })
        await update.mutateAsync({ moduleId: mode.module.id, input: updateValues })
        toast.success('Module updated')
      } else {
        const payload: FormValues = values.is_reference
          ? values
          : { ...values, ref_module_id: null }
        await create.mutateAsync(payload)
        toast.success('Module created')
      }
      onSuccess()
    } catch (e: any) {
      const msg = e?.response?.data?.message ?? 'Failed to save module'
      if (!isEdit && /code|duplicate|exists|already/i.test(msg)) {
        setError('module_code', { message: msg })
      }
      toast.error(msg)
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <h3 className="font-semibold text-neutral-900">
        {isEdit ? 'Edit Module' : 'New Module'}
      </h3>

      {!isEdit && (
        <FormField label="Module Code" required error={errors.module_code?.message as string}>
          <Input {...register('module_code')} placeholder="e.g. CODE-001" />
        </FormField>
      )}

      <FormField label="Module Title" required error={errors.module_title?.message as string}>
        <Input {...register('module_title')} placeholder="e.g. Pemrograman Dasar" />
      </FormField>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Sequence" required error={errors.sequence?.message as string}>
          <Input type="number" min={1} {...register('sequence', { valueAsNumber: true })} />
        </FormField>
        <FormField label="Duration (jam)" error={errors.duration_hours?.message as string}>
          <Input
            type="number"
            min={0}
            step={0.5}
            {...register('duration_hours', { valueAsNumber: true })}
          />
        </FormField>
      </div>

      {!isEdit && (
        <div className="space-y-3 p-3 border border-neutral-200 rounded-lg bg-neutral-50">
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              {...register('is_reference')}
              className="h-4 w-4 rounded border-neutral-300"
            />
            <span className="font-medium text-neutral-800">
              This is a reference module
            </span>
          </label>
          {isReference && (
            <FormField
              label="Reference Module"
              required
              error={errors.ref_module_id?.message as string}
            >
              <Controller
                name="ref_module_id"
                control={control}
                render={({ field }) => (
                  <Select
                    value={field.value ?? ''}
                    onChange={(e) => field.onChange(e.target.value || null)}
                  >
                    <option value="">— pick a module —</option>
                    {refCandidates.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.label}
                      </option>
                    ))}
                  </Select>
                )}
              />
              {refCandidates.length === 0 && (
                <p className="text-xs text-neutral-500 mt-1">
                  No modules available from other versions of this course type.
                </p>
              )}
            </FormField>
          )}
        </div>
      )}

      {!isReference && (
        <>
          <FormField label="Content Depth" error={errors.content_depth?.message as string}>
            <Textarea {...register('content_depth')} rows={3} />
          </FormField>

          <FormField
            label="Assessment Method"
            error={errors.assessment_method?.message as string}
          >
            <Input {...register('assessment_method')} placeholder="e.g. Project + Quiz" />
          </FormField>

          <FormField label="Topics">
            <Controller
              name="topics"
              control={control}
              render={({ field }) => (
                <MultiInput
                  value={field.value ?? []}
                  onChange={field.onChange}
                  placeholder="Add topic"
                />
              )}
            />
          </FormField>

          <FormField label="Practical Activities">
            <Controller
              name="practical_activities"
              control={control}
              render={({ field }) => (
                <MultiInput
                  value={field.value ?? []}
                  onChange={field.onChange}
                  placeholder="Add activity"
                />
              )}
            />
          </FormField>

          <FormField label="Tools Required">
            <Controller
              name="tools_required"
              control={control}
              render={({ field }) => (
                <MultiInput
                  value={field.value ?? []}
                  onChange={field.onChange}
                  placeholder="Add tool"
                />
              )}
            />
          </FormField>

          <FormField label="Requirements">
            <Controller
              name="requirements"
              control={control}
              render={({ field }) => (
                <MultiInput
                  value={field.value ?? []}
                  onChange={field.onChange}
                  placeholder="Add requirement"
                />
              )}
            />
          </FormField>
        </>
      )}

      <div className="flex gap-2 pt-2 border-t border-neutral-100">
        <Button type="button" variant="secondary" onClick={onCancel}>
          Cancel
        </Button>
        <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
          Save
        </Button>
      </div>
    </form>
  )
}
