import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Button from '@/components/ui/Button'
import { createBranchSchema, type CreateBranchInput } from '@/schemas/branch'
import { useCreateBranch } from '@/lib/api/branch'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Settings', to: '/internal/settings/branches' },
  { label: 'Branches', to: '/internal/settings/branches' },
  { label: 'New Branch' },
]

export default function BranchCreatePage() {
  const navigate = useNavigate()
  const create = useCreateBranch()

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateBranchInput>({
    resolver: zodResolver(createBranchSchema),
    defaultValues: {
      code: '',
      name: '',
      address: '',
      city: '',
      province: '',
      phone: '',
      email: '',
      is_active: true,
    },
  })

  async function onSubmit(values: CreateBranchInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Branch created')
      navigate('/internal/settings/branches')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create branch')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="Add Branch" subtitle="Create a new branch">
      <form
        onSubmit={handleSubmit(onSubmit)}
        className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4"
      >
        <div className="grid grid-cols-2 gap-4">
          <FormField label="Code" required error={errors.code?.message}>
            <Input {...register('code')} placeholder="JKT" />
          </FormField>
          <FormField label="Name" required error={errors.name?.message}>
            <Input {...register('name')} placeholder="Jakarta HQ" />
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
            <Input {...register('email')} placeholder="branch@vernon.id" />
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
