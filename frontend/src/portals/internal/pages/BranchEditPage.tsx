import { useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Button from '@/components/ui/Button'
import { updateBranchSchema, type UpdateBranchInput } from '@/schemas/branch'
import { useBranch, useUpdateBranch } from '@/lib/api/branch'

export default function BranchEditPage() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = useBranch(id)
  const update = useUpdateBranch(id)

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateBranchInput>({
    resolver: zodResolver(updateBranchSchema),
    defaultValues: {
      code: '', name: '', address: '', city: '', province: '',
      phone: '', email: '', is_active: true,
    },
  })

  useEffect(() => {
    if (data) {
      reset({
        code: data.code, name: data.name, address: data.address,
        city: data.city, province: data.province, phone: data.phone,
        email: data.email, is_active: data.is_active,
      })
    }
  }, [data, reset])

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Settings', to: '/internal/settings/branches' },
    { label: 'Branches', to: '/internal/settings/branches' },
    { label: data.name },
  ]

  async function onSubmit(values: UpdateBranchInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Branch updated')
      navigate('/internal/settings/branches')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update branch')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title={`Edit ${data.name}`} subtitle="Update branch details">
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4"
      >
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Code" required error={errors.code?.message}>
            <Input {...register('code')} />
          </FormField>
          <FormField label="Name" required error={errors.name?.message}>
            <Input {...register('name')} />
          </FormField>
        </div>
        <FormField label="Address" error={errors.address?.message}>
          <Input {...register('address')} />
        </FormField>
        <div className="grid grid-cols-2 gap-4">
          <FormField label="City" error={errors.city?.message}>
            <Input {...register('city')} />
          </FormField>
          <FormField label="Province" error={errors.province?.message}>
            <Input {...register('province')} />
          </FormField>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Phone" error={errors.phone?.message}>
            <Input {...register('phone')} />
          </FormField>
          <FormField label="Email" error={errors.email?.message}>
            <Input {...register('email')} />
          </FormField>
        </div>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" {...register('is_active')} className="rounded" />
          Active
        </label>
        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/settings/branches')}>
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
