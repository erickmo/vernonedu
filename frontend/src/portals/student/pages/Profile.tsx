import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useAuth } from '@/lib/auth/useAuth'
import { useUpdateStudentProfile } from '@/lib/api/identity'
import PageHeader from '@/components/shared/PageHeader'

const profileSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email'),
  phone: z.string().min(8, 'Phone must be at least 8 characters'),
})

type ProfileForm = z.infer<typeof profileSchema>

function ProfileCompletionBar({ percent }: { percent: number }) {
  return (
    <div className="bg-white rounded-xl border border-border p-5">
      <div className="flex items-center justify-between mb-2">
        <p className="text-sm font-medium text-neutral-700">Profile completion</p>
        <p className="text-sm font-bold text-brand-600">{percent}%</p>
      </div>
      <div className="w-full h-2 bg-neutral-100 rounded-full overflow-hidden">
        <div
          className="h-full bg-brand-500 rounded-full transition-all duration-500"
          style={{ width: `${percent}%` }}
        />
      </div>
      {percent < 100 && (
        <p className="text-xs text-neutral-500 mt-2">
          Fill in all fields to complete your profile.
        </p>
      )}
    </div>
  )
}

export default function StudentProfile() {
  const { user } = useAuth()
  const updateProfile = useUpdateStudentProfile()

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isDirty },
  } = useForm<ProfileForm>({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      name: user?.name ?? '',
      email: user?.email ?? '',
      phone: '',
    },
  })

  const values = watch()
  const filledCount = [values.name, values.email, values.phone].filter(Boolean).length
  const completionPercent = Math.round((filledCount / 3) * 100)

  const onSubmit = async (data: ProfileForm) => {
    if (!user?.id) return
    try {
      await updateProfile.mutateAsync({ id: user.id, ...data })
      toast.success('Profile updated successfully')
    } catch {
      toast.error('Failed to update profile')
    }
  }

  return (
    <div className="space-y-6 max-w-2xl">
      <PageHeader
        title="My Profile"
        subtitle="Manage your personal information"
        breadcrumbs={[{ label: 'Profile' }]}
      />

      <ProfileCompletionBar percent={completionPercent} />

      <form onSubmit={handleSubmit(onSubmit)} className="bg-white rounded-xl border border-border p-6 space-y-5">
        <h2 className="font-semibold text-neutral-800">Basic Information</h2>

        <div className="space-y-1.5">
          <label className="text-sm font-medium text-neutral-700">Full name</label>
          <input
            {...register('name')}
            className="w-full px-3 py-2.5 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
            placeholder="Your full name"
          />
          {errors.name && (
            <p className="text-xs text-red-600">{errors.name.message}</p>
          )}
        </div>

        <div className="space-y-1.5">
          <label className="text-sm font-medium text-neutral-700">Email address</label>
          <input
            {...register('email')}
            type="email"
            className="w-full px-3 py-2.5 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
            placeholder="you@example.com"
          />
          {errors.email && (
            <p className="text-xs text-red-600">{errors.email.message}</p>
          )}
        </div>

        <div className="space-y-1.5">
          <label className="text-sm font-medium text-neutral-700">Phone number</label>
          <input
            {...register('phone')}
            type="tel"
            className="w-full px-3 py-2.5 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
            placeholder="+62 xxx xxxx xxxx"
          />
          {errors.phone && (
            <p className="text-xs text-red-600">{errors.phone.message}</p>
          )}
        </div>

        <div className="pt-2 flex justify-end">
          <button
            type="submit"
            disabled={!isDirty || updateProfile.isPending}
            className="px-5 py-2.5 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {updateProfile.isPending ? 'Saving...' : 'Save changes'}
          </button>
        </div>
      </form>
    </div>
  )
}
