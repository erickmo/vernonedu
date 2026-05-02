import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import {
  upsertCharacterTestConfigSchema,
  TEST_TYPES,
  type UpsertCharacterTestConfigInput,
} from '@/schemas/charactertestconfig'
import {
  useCharacterTestConfig,
  useUpsertCharacterTestConfig,
} from '@/lib/api/curriculum'

interface Props {
  versionId: string
  locked: boolean
}

const EMPTY: UpsertCharacterTestConfigInput = {
  test_type: 'DISC',
  test_provider: '',
  passing_threshold: 70,
  talentpool_eligible: false,
}

export default function CharacterTestConfigForm({ versionId, locked }: Props) {
  const { data, isLoading } = useCharacterTestConfig(versionId)
  const upsert = useUpsertCharacterTestConfig(versionId)

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting, isDirty },
  } = useForm<UpsertCharacterTestConfigInput>({
    resolver: zodResolver(upsertCharacterTestConfigSchema),
    defaultValues: EMPTY,
  })

  useEffect(() => {
    if (data) {
      reset({
        test_type: data.test_type,
        test_provider: data.test_provider,
        passing_threshold: data.passing_threshold,
        talentpool_eligible: data.talentpool_eligible,
      })
    }
  }, [data, reset])

  async function onSubmit(values: UpsertCharacterTestConfigInput) {
    try {
      await upsert.mutateAsync(values)
      toast.success('Character test config saved')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to save character test config')
    }
  }

  if (isLoading) return <LoadingSpinner size="md" />

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-3 bg-white border border-neutral-200 rounded-xl p-5">
      <h4 className="font-semibold text-neutral-900">Character Test</h4>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Test Type" required error={errors.test_type?.message}>
          <Select {...register('test_type')} disabled={locked}>
            {TEST_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
          </Select>
        </FormField>
        <FormField label="Test Provider" error={errors.test_provider?.message}>
          <Input {...register('test_provider')} disabled={locked} />
        </FormField>
        <FormField label="Passing Threshold (0-100)" required error={errors.passing_threshold?.message}>
          <Input type="number" min={0} max={100} step={1}
            {...register('passing_threshold', { valueAsNumber: true })} disabled={locked} />
        </FormField>
      </div>

      <label className="flex items-center gap-2 text-sm text-neutral-700">
        <input type="checkbox" {...register('talentpool_eligible')} disabled={locked} />
        Talentpool eligible (passes graduate to TalentPool)
      </label>

      <div className="flex justify-end pt-2 border-t border-neutral-100">
        {locked ? (
          <span className="text-xs text-neutral-500">🔒 Read-only</span>
        ) : (
          <RoleGate action="update" resource="charactertestconfig">
            <Button type="submit" loading={isSubmitting} disabled={isSubmitting || !isDirty}>
              Save Character Test
            </Button>
          </RoleGate>
        )}
      </div>
    </form>
  )
}
