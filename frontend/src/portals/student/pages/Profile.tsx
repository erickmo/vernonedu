import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { User, Mail, Phone, Shield } from 'lucide-react'
import { useAuth } from '@/lib/auth/useAuth'
import { useUpdateStudentProfile } from '@/lib/api/identity'

const profileSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email'),
  phone: z.string().min(8, 'Phone must be at least 8 characters'),
})

type ProfileForm = z.infer<typeof profileSchema>

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
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">My Profile</h1>
        <p className="text-sm text-neutral-500 mt-0.5">Manage your personal information</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left: info card */}
        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-6 flex flex-col items-center text-center">
            <div className="w-20 h-20 rounded-full bg-emerald-50 flex items-center justify-center text-3xl font-bold text-emerald-700 mb-3">
              {user?.name?.charAt(0).toUpperCase() ?? '?'}
            </div>
            <p className="font-semibold text-neutral-900">{user?.name}</p>
            <p className="text-sm text-neutral-500 capitalize mt-0.5">{user?.role}</p>
          </div>

          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5 space-y-3">
            <p className="text-xs font-semibold text-neutral-500 uppercase tracking-wide">Account Info</p>
            <div className="flex items-center gap-2.5 text-sm text-neutral-700">
              <Mail className="w-4 h-4 text-neutral-400 shrink-0" />
              <span className="truncate">{user?.email}</span>
            </div>
            <div className="flex items-center gap-2.5 text-sm text-neutral-700">
              <Shield className="w-4 h-4 text-neutral-400 shrink-0" />
              <span className="capitalize">{user?.role}</span>
            </div>
          </div>

          {/* Profile completion */}
          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5">
            <div className="flex items-center justify-between mb-2">
              <p className="text-sm font-medium text-neutral-700">Profile completion</p>
              <p className="text-sm font-bold text-emerald-600">{completionPercent}%</p>
            </div>
            <div className="w-full h-1.5 bg-neutral-100 rounded-full overflow-hidden">
              <div
                className="h-full bg-emerald-500 rounded-full transition-all duration-500"
                style={{ width: `${completionPercent}%` }}
              />
            </div>
          </div>
        </div>

        {/* Right: edit form */}
        <div className="lg:col-span-2">
          <form
            onSubmit={handleSubmit(onSubmit)}
            className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-6 space-y-5"
          >
            <h2 className="font-semibold text-neutral-900 text-base">Edit Information</h2>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-neutral-700 flex items-center gap-1.5">
                <User className="w-3.5 h-3.5 text-neutral-400" /> Full name
              </label>
              <input
                {...register('name')}
                className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                placeholder="Your full name"
              />
              {errors.name && <p className="text-xs text-red-600">{errors.name.message}</p>}
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-neutral-700 flex items-center gap-1.5">
                <Mail className="w-3.5 h-3.5 text-neutral-400" /> Email address
              </label>
              <input
                {...register('email')}
                type="email"
                className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                placeholder="you@example.com"
              />
              {errors.email && <p className="text-xs text-red-600">{errors.email.message}</p>}
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-neutral-700 flex items-center gap-1.5">
                <Phone className="w-3.5 h-3.5 text-neutral-400" /> Phone number
              </label>
              <input
                {...register('phone')}
                type="tel"
                className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                placeholder="+62 xxx xxxx xxxx"
              />
              {errors.phone && <p className="text-xs text-red-600">{errors.phone.message}</p>}
            </div>

            <div className="pt-2 flex justify-end">
              <button
                type="submit"
                disabled={!isDirty || updateProfile.isPending}
                className="px-5 py-2.5 text-sm font-semibold text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {updateProfile.isPending ? 'Saving…' : 'Save changes'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
