import { useNavigate, Link } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { GraduationCap, Eye, EyeOff } from 'lucide-react'
import { useState } from 'react'
import { useAuth } from '@/lib/auth/useAuth'

const PRESET_USERS = [
  { email: 'ceo@vernonedu.id',        role: 'CEO' },
  { email: 'finance@vernonedu.id',    role: 'Finance' },
  { email: 'academic@vernonedu.id',   role: 'Academic Leader' },
  { email: 'dept@vernonedu.id',       role: 'Dept Leader' },
  { email: 'creator@vernonedu.id',    role: 'Course Creator' },
  { email: 'superadmin@vernonedu.id', role: 'Vernon Admin' },
  { email: 'admin2@vernonedu.id',     role: 'Admin' },
  { email: 'student2@vernonedu.id',   role: 'Student' },
  { email: 'franchisee@vernonedu.id', role: 'Franchisee' },
]

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
})

type LoginForm = z.infer<typeof loginSchema>

const ROLE_REDIRECT: Record<string, string> = {
  student: '/student',
  franchisee: '/franchise',
}

const DEFAULT_REDIRECT = '/internal'

export default function Login() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [showPassword, setShowPassword] = useState(false)

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors, isSubmitting },
  } = useForm<LoginForm>({
    resolver: zodResolver(loginSchema),
  })

  const fillPreset = (email: string) => {
    setValue('email', email, { shouldValidate: true })
    setValue('password', 'password123', { shouldValidate: true })
  }

  const onSubmit = async (data: LoginForm) => {
    try {
      await login(data.email, data.password)
      const storedUser = localStorage.getItem('vernonedu_user')
      const user = storedUser ? JSON.parse(storedUser) as { role: string } : null
      const redirect = ROLE_REDIRECT[user?.role ?? ''] ?? DEFAULT_REDIRECT
      navigate(redirect, { replace: true })
    } catch {
      toast.error('Invalid email or password')
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-brand-50 to-neutral-100 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-brand-600 mb-4">
            <GraduationCap className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-neutral-900">Welcome to VernonEdu</h1>
          <p className="text-neutral-500 mt-1 text-sm">Sign in to your account</p>
        </div>

        <div className="bg-white/60 border border-border rounded-2xl p-4 mb-4">
          <p className="text-xs font-semibold text-neutral-400 uppercase tracking-wider mb-2">Preset Users</p>
          <div className="flex flex-wrap gap-1.5">
            {PRESET_USERS.map((u) => (
              <button
                key={u.email}
                type="button"
                onClick={() => fillPreset(u.email)}
                className="text-xs px-2.5 py-1 rounded-full border border-brand-200 bg-brand-50 text-brand-700 hover:bg-brand-100 transition-colors"
              >
                {u.role}
              </button>
            ))}
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-border shadow-sm p-8">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
            <div className="space-y-1.5">
              <label className="text-sm font-medium text-neutral-700">Email address</label>
              <input
                {...register('email')}
                type="email"
                autoComplete="email"
                placeholder="you@example.com"
                className="w-full px-3.5 py-2.5 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 transition-shadow"
              />
              {errors.email && (
                <p className="text-xs text-red-600">{errors.email.message}</p>
              )}
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-neutral-700">Password</label>
              <div className="relative">
                <input
                  {...register('password')}
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  placeholder="••••••••"
                  className="w-full px-3.5 py-2.5 pr-10 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 transition-shadow"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-neutral-600"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
              {errors.password && (
                <p className="text-xs text-red-600">{errors.password.message}</p>
              )}
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full py-2.5 text-sm font-semibold text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-60 disabled:cursor-not-allowed transition-colors"
            >
              {isSubmitting ? 'Signing in...' : 'Sign in'}
            </button>
          </form>

          <p className="mt-6 text-center text-sm text-neutral-500">
            Don't have an account?{' '}
            <Link to="/register" className="font-medium text-brand-600 hover:text-brand-700">
              Register here
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
