import { useEffect } from 'react'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import MultiInput from '@/components/shared/MultiInput'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import {
  createCourseTypeSchema,
  TYPE_NAMES,
  PRICE_TYPES,
  CURRENCIES,
  type CreateCourseTypeInput,
} from '@/schemas/coursetype'
import { useCreateCourseType, useUpdateCourseType } from '@/lib/api/curriculum'
import type { CourseType } from '@/types/coursetype'

type Mode = { kind: 'create' } | { kind: 'edit'; variant: CourseType }

interface Props {
  courseId: string
  mode: Mode
  onSuccess: (variant: CourseType) => void
  onCancel: () => void
}

const DEFAULTS: CreateCourseTypeInput = {
  type_name: 'Reguler',
  price_type: 'one-time',
  price_currency: 'IDR',
  target_audience: '',
  certification_type: '',
  extra_docs: [],
  normal_price: 0,
  min_price: 0,
  min_participants: 1,
  max_participants: 1,
}

function variantToInput(v: CourseType): CreateCourseTypeInput {
  return {
    type_name: v.type_name,
    price_type: (PRICE_TYPES.includes(v.price_type as any) ? v.price_type : 'one-time') as CreateCourseTypeInput['price_type'],
    price_currency: 'IDR',
    target_audience: v.target_audience,
    certification_type: v.certification_type,
    extra_docs: v.extra_docs ?? [],
    normal_price: v.normal_price,
    min_price: v.min_price,
    min_participants: v.min_participants,
    max_participants: v.max_participants,
  }
}

export default function VariantForm({ courseId, mode, onSuccess, onCancel }: Props) {
  const create = useCreateCourseType(courseId)
  const update = useUpdateCourseType(mode.kind === 'edit' ? mode.variant.id : '', courseId)

  const {
    register, handleSubmit, control, reset,
    formState: { errors, isSubmitting },
  } = useForm<CreateCourseTypeInput>({
    resolver: zodResolver(createCourseTypeSchema),
    defaultValues: mode.kind === 'edit' ? variantToInput(mode.variant) : DEFAULTS,
  })

  useEffect(() => {
    if (mode.kind === 'edit') reset(variantToInput(mode.variant))
    else reset(DEFAULTS)
  }, [mode, reset])

  async function onSubmit(values: CreateCourseTypeInput) {
    try {
      const result = mode.kind === 'create'
        ? await create.mutateAsync(values)
        : await update.mutateAsync(values)
      toast.success(mode.kind === 'create' ? 'Variant created' : 'Variant updated')
      onSuccess(result)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to save variant')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <h3 className="font-semibold text-neutral-900">
        {mode.kind === 'create' ? 'New Variant' : mode.variant.type_name}
      </h3>

      <FormField label="Type Name" required error={errors.type_name?.message}>
        <Select {...register('type_name')}>
          {TYPE_NAMES.map((n) => <option key={n} value={n}>{n}</option>)}
        </Select>
      </FormField>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Price Type" error={errors.price_type?.message}>
          <Select {...register('price_type')}>
            {PRICE_TYPES.map((p) => <option key={p} value={p}>{p}</option>)}
          </Select>
        </FormField>
        <FormField label="Currency" error={errors.price_currency?.message}>
          <Select {...register('price_currency')}>
            {CURRENCIES.map((c) => <option key={c} value={c}>{c}</option>)}
          </Select>
        </FormField>
      </div>

      <FormField label="Target Audience" error={errors.target_audience?.message}>
        <Input {...register('target_audience')} placeholder="e.g. Mahasiswa Tingkat Akhir" />
      </FormField>

      <FormField label="Certification Type" error={errors.certification_type?.message}>
        <Input {...register('certification_type')} placeholder="e.g. Certificate of Completion" />
      </FormField>

      <FormField label="Extra Docs">
        <Controller
          name="extra_docs"
          control={control}
          render={({ field }) => (
            <MultiInput value={field.value ?? []} onChange={field.onChange} placeholder="e.g. Course outline, Project brief" />
          )}
        />
      </FormField>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Normal Price (IDR)" required error={errors.normal_price?.message}>
          <Input type="number" min={0} {...register('normal_price', { valueAsNumber: true })} />
        </FormField>
        <FormField label="Min Price (IDR)" required error={errors.min_price?.message}>
          <Input type="number" min={0} {...register('min_price', { valueAsNumber: true })} />
        </FormField>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Min Participants" required error={errors.min_participants?.message}>
          <Input type="number" min={1} {...register('min_participants', { valueAsNumber: true })} />
        </FormField>
        <FormField label="Max Participants" required error={errors.max_participants?.message}>
          <Input type="number" min={1} {...register('max_participants', { valueAsNumber: true })} />
        </FormField>
      </div>

      <div className="flex gap-2 pt-2 border-t border-neutral-100">
        <Button type="button" variant="secondary" onClick={onCancel}>Cancel</Button>
        <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>Save</Button>
      </div>
    </form>
  )
}
