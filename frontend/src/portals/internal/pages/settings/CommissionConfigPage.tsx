import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import {
  useCommissionConfig,
  useUpdateCommissionConfig,
} from '@/lib/api/settings-hr'
import {
  updateCommissionConfigSchema,
  COMMISSION_BASIS,
  type UpdateCommissionConfigInput,
} from '@/schemas/commissionconfig'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Settings', to: '/internal/settings' },
  { label: 'Commission' },
]

export default function CommissionConfigPage() {
  const { data, isLoading } = useCommissionConfig()
  const update = useUpdateCommissionConfig()

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateCommissionConfigInput>({
    resolver: zodResolver(updateCommissionConfigSchema),
    defaultValues: {
      op_leader_pct: 0,
      op_leader_basis: 'profit',
      dept_leader_pct: 0,
      dept_leader_basis: 'profit',
      course_creator_pct: 0,
      course_creator_basis: 'profit',
    },
  })

  useEffect(() => {
    if (data) reset(data)
  }, [data, reset])

  async function onSubmit(values: UpdateCommissionConfigInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Commission config updated')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update')
    }
  }

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Commission Configuration"
      subtitle="Director-only settings for revenue/profit splits"
    >
      {isLoading ? (
        <div className="text-sm text-neutral-500">Loading…</div>
      ) : (
        <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-6">
          {(['op_leader', 'dept_leader', 'course_creator'] as const).map((role) => (
            <div key={role} className="space-y-3 border-b last:border-b-0 pb-4 last:pb-0">
              <h3 className="font-semibold capitalize">{role.replace(/_/g, ' ')}</h3>
              <div className="grid grid-cols-2 gap-4">
                <FormField label="Percentage (%)" required error={errors[`${role}_pct` as const]?.message}>
                  <Input
                    type="number"
                    step="0.01"
                    {...register(`${role}_pct` as const, { valueAsNumber: true })}
                  />
                </FormField>
                <FormField label="Basis" required error={errors[`${role}_basis` as const]?.message}>
                  <Select {...register(`${role}_basis` as const)}>
                    {COMMISSION_BASIS.map((b) => (
                      <option key={b} value={b}>{b}</option>
                    ))}
                  </Select>
                </FormField>
              </div>
            </div>
          ))}
          <div className="flex gap-2 pt-2">
            <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>Save</Button>
          </div>
        </form>
      )}
    </StandardPageLayout>
  )
}
