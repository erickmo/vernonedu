import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import RoleGate from '@/components/shared/RoleGate'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { updateBuildingSchema, type UpdateBuildingInput } from '@/schemas/building'
import { useBuilding, useUpdateBuilding, useDeleteBuilding } from '@/lib/api/location'

export default function BuildingEditPage() {
  const navigate = useNavigate()
  const { id = '' } = useParams<{ id: string }>()
  const { data, isLoading } = useBuilding(id)
  const update = useUpdateBuilding(id)
  const del = useDeleteBuilding()
  const [confirmDelete, setConfirmDelete] = useState(false)

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateBuildingInput>({
    resolver: zodResolver(updateBuildingSchema),
  })

  useEffect(() => {
    if (data) {
      reset({
        name: data.name,
        address: data.address ?? '',
        description: data.description ?? '',
      })
    }
  }, [data, reset])

  async function onSubmit(values: UpdateBuildingInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Building updated')
      navigate(`/internal/buildings/${id}`)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update')
    }
  }

  async function onDelete() {
    try {
      await del.mutateAsync(id)
      toast.success('Building deleted')
      navigate('/internal/buildings')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to delete')
    } finally {
      setConfirmDelete(false)
    }
  }

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Buildings', to: '/internal/buildings' },
    { label: data.name, to: `/internal/buildings/${id}` },
    { label: 'Edit' },
  ]

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Edit Building"
      subtitle={data.name}
    >
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Name" required error={errors.name?.message}>
          <Input {...register('name')} />
        </FormField>
        <FormField label="Address" error={errors.address?.message}>
          <Input {...register('address')} />
        </FormField>
        <FormField label="Description" error={errors.description?.message}>
          <Textarea {...register('description')} rows={4} />
        </FormField>

        <div className="flex gap-2 pt-2 border-t border-neutral-100">
          <Button type="button" variant="secondary" onClick={() => navigate(`/internal/buildings/${id}`)}>
            Cancel
          </Button>
          <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
            Save
          </Button>
          <RoleGate action="delete" resource="building">
            <Button type="button" variant="danger" onClick={() => setConfirmDelete(true)}>
              Delete
            </Button>
          </RoleGate>
        </div>
      </form>

      <ConfirmDialog
        open={confirmDelete}
        onConfirm={onDelete}
        onCancel={() => setConfirmDelete(false)}
        title="Delete building?"
        description="All rooms in this building will also be removed. This action cannot be undone."
        confirmLabel="Delete"
        destructive
      />
    </StandardPageLayout>
  )
}
