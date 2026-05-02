import { useNavigate } from 'react-router-dom'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Button from '@/components/ui/Button'
import { createUserSchema, ROLE_OPTIONS, type CreateUserInput } from '@/schemas/user'
import { useCreateUser } from '@/lib/api/user'

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'HR', to: '/internal/hr' },
  { label: 'Users', to: '/internal/users' },
  { label: 'New User' },
]

export default function UserCreatePage() {
  const navigate = useNavigate()
  const create = useCreateUser()

  const {
    register, handleSubmit, control,
    formState: { errors, isSubmitting },
  } = useForm<CreateUserInput>({
    resolver: zodResolver(createUserSchema),
    defaultValues: { name: '', email: '', password: '', roles: [] },
  })

  async function onSubmit(values: CreateUserInput) {
    try {
      await create.mutateAsync(values)
      toast.success('User created')
      navigate('/internal/users')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create user')
    }
  }

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="Add User" subtitle="Register a new staff account">
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Name" required error={errors.name?.message}>
          <Input {...register('name')} placeholder="Full name" />
        </FormField>
        <FormField label="Email" required error={errors.email?.message}>
          <Input type="email" {...register('email')} placeholder="user@vernonedu.id" />
        </FormField>
        <FormField label="Password" required error={errors.password?.message}>
          <Input type="password" {...register('password')} placeholder="Min 6 characters" />
        </FormField>
        <FormField label="Roles" required error={errors.roles?.message as string | undefined}>
          <Controller
            name="roles"
            control={control}
            render={({ field }) => (
              <div className="grid grid-cols-2 gap-2 p-3 border rounded-lg bg-neutral-50">
                {ROLE_OPTIONS.map((role) => {
                  const checked = field.value?.includes(role) ?? false
                  return (
                    <label key={role} className="flex items-center gap-2 text-sm">
                      <input
                        type="checkbox"
                        checked={checked}
                        onChange={(e) => {
                          const next = new Set(field.value ?? [])
                          if (e.target.checked) next.add(role)
                          else next.delete(role)
                          field.onChange(Array.from(next))
                        }}
                      />
                      <span className="capitalize">{role.replace(/_/g, ' ')}</span>
                    </label>
                  )
                })}
              </div>
            )}
          />
        </FormField>
        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/users')}>Cancel</Button>
          <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>Save</Button>
        </div>
      </form>
    </StandardPageLayout>
  )
}
