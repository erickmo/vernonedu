import { useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Button from '@/components/ui/Button'
import { updateUserSchema, type UpdateUserInput } from '@/schemas/user'
import { useUser, useUpdateUser, useDeleteUser } from '@/lib/api/user'

export default function UserEditPage() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: user, isLoading } = useUser(id)
  const update = useUpdateUser(id)
  const remove = useDeleteUser()

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateUserInput>({
    resolver: zodResolver(updateUserSchema),
    defaultValues: { name: '' },
  })

  useEffect(() => {
    if (user) reset({ name: user.name })
  }, [user, reset])

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'HR', to: '/internal/hr' },
    { label: 'Users', to: '/internal/users' },
    { label: user?.name ?? 'Edit' },
  ]

  async function onSubmit(values: UpdateUserInput) {
    try {
      await update.mutateAsync(values)
      toast.success('User updated')
      navigate('/internal/users')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update user')
    }
  }

  async function onDelete() {
    if (!confirm('Delete this user? This cannot be undone.')) return
    try {
      await remove.mutateAsync(id)
      toast.success('User deleted')
      navigate('/internal/users')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to delete user')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="Edit User" subtitle={user?.email}>
      {isLoading ? (
        <div className="text-sm text-neutral-500">Loading…</div>
      ) : (
        <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
          <FormField label="Name" required error={errors.name?.message}>
            <Input {...register('name')} />
          </FormField>
          <div className="text-sm text-neutral-500">
            <strong>Roles:</strong>{' '}
            {(user?.roles ?? []).map((r) => r.replace(/_/g, ' ')).join(', ') || '—'}
          </div>
          <div className="flex gap-2 pt-2">
            <Button type="button" variant="secondary" onClick={() => navigate('/internal/users')}>Cancel</Button>
            <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>Save</Button>
            <Button type="button" variant="danger" onClick={onDelete}>Delete</Button>
          </div>
        </form>
      )}
    </StandardPageLayout>
  )
}
