import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import { createBuildingSchema, type CreateBuildingInput } from '@/schemas/building'
import { useCreateBuilding } from '@/lib/api/location'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Operations', to: '/internal/operations' },
  { label: 'Buildings', to: '/internal/buildings' },
  { label: 'New Building' },
]

export default function BuildingCreatePage() {
  const navigate = useNavigate()
  const create = useCreateBuilding()

  const {
    register, handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateBuildingInput>({
    resolver: zodResolver(createBuildingSchema),
    defaultValues: { name: '', address: '', description: '' },
  })

  async function onSubmit(values: CreateBuildingInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Building created')
      navigate('/internal/buildings')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create building')
    }
  }

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Add Building"
      subtitle="Create a new building location"
    >
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Name" required error={errors.name?.message}>
          <Input {...register('name')} placeholder="Main Building" />
        </FormField>

        <FormField label="Address" error={errors.address?.message}>
          <Input {...register('address')} placeholder="Jl. Sudirman 1" />
        </FormField>

        <FormField label="Description" error={errors.description?.message}>
          <Textarea {...register('description')} rows={4} />
        </FormField>

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/buildings')}>
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
