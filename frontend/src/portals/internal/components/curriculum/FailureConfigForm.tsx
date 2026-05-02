import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import {
  componentFailureConfigSchema,
  DEFAULT_FAILURE_CONFIG,
  type ComponentFailureConfigInput,
} from '@/schemas/failureconfig'
import {
  PEMBELAJARAN_OPTIONS,
  INTERNSHIP_OPTIONS,
  CHARACTER_TEST_OPTIONS,
  type ComponentFailureConfig,
} from '@/types/failureconfig'
import { useUpdateFailureConfig } from '@/lib/api/curriculum'

interface Props {
  typeId: string
  initial?: ComponentFailureConfig | null
}

const PEMBELAJARAN_LABELS: Record<string, string> = {
  retry: 'Retry (re-take learning)',
  continue_no_cert: 'Continue without certificate',
  disqualified: 'Disqualified',
}
const INTERNSHIP_LABELS: Record<string, string> = {
  retry: 'Retry internship',
  continue_no_cert: 'Continue without certificate',
  disqualified: 'Disqualified',
}
const CHARACTER_TEST_LABELS: Record<string, string> = {
  retry: 'Retry character test',
  continue_no_talentpool: 'Continue without talent pool',
  disqualified: 'Disqualified',
}

export default function FailureConfigForm({ typeId, initial }: Props) {
  const update = useUpdateFailureConfig(typeId)

  const defaults: ComponentFailureConfigInput = initial
    ? {
        pembelajaran: initial.pembelajaran,
        internship: initial.internship,
        character_test: initial.character_test,
      }
    : DEFAULT_FAILURE_CONFIG

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting, isDirty },
  } = useForm<ComponentFailureConfigInput>({
    resolver: zodResolver(componentFailureConfigSchema),
    defaultValues: defaults,
  })

  useEffect(() => {
    reset(defaults)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [typeId, initial?.pembelajaran, initial?.internship, initial?.character_test])

  async function onSubmit(values: ComponentFailureConfigInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Failure config saved')
      reset(values)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to save failure config')
    }
  }

  return (
    <form
      onSubmit={handleSubmit(onSubmit)}
      className="space-y-4 mt-6 pt-6 border-t border-neutral-100"
    >
      <div>
        <h4 className="text-sm font-semibold text-neutral-900">
          Component Failure Config
        </h4>
        <p className="text-xs text-neutral-500 mt-1">
          Behavior when a Program Karir component fails.
        </p>
      </div>

      <FormField label="Pembelajaran" required error={errors.pembelajaran?.message}>
        <Select {...register('pembelajaran')}>
          {PEMBELAJARAN_OPTIONS.map((o) => (
            <option key={o} value={o}>
              {PEMBELAJARAN_LABELS[o]}
            </option>
          ))}
        </Select>
      </FormField>

      <FormField label="Internship" required error={errors.internship?.message}>
        <Select {...register('internship')}>
          {INTERNSHIP_OPTIONS.map((o) => (
            <option key={o} value={o}>
              {INTERNSHIP_LABELS[o]}
            </option>
          ))}
        </Select>
      </FormField>

      <FormField label="Character Test" required error={errors.character_test?.message}>
        <Select {...register('character_test')}>
          {CHARACTER_TEST_OPTIONS.map((o) => (
            <option key={o} value={o}>
              {CHARACTER_TEST_LABELS[o]}
            </option>
          ))}
        </Select>
      </FormField>

      <div className="flex gap-2">
        <Button
          type="submit"
          loading={isSubmitting}
          disabled={isSubmitting || !isDirty}
          variant="secondary"
        >
          Save Failure Config
        </Button>
      </div>
    </form>
  )
}
