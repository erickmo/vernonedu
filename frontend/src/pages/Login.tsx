import { useNavigate, Link } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { GraduationCap, Eye, EyeOff, ChevronDown, ChevronUp, Code } from 'lucide-react'
import { useState } from 'react'
import { useAuth } from '@/lib/auth/useAuth'
import { motion } from 'framer-motion'
import { fadeInUp, stagger, staggerItem } from '@/lib/utils/motion'
import { cn } from '@/lib/utils/cn'

const PRESET_USERS = [
  { email: 'director2@test.com', role: 'CEO / Director' },
  { email: 'education2@test.com', role: 'Education Leader' },
  { email: 'dept@test.com', role: 'Dept Leader' },
  { email: 'course2@test.com', role: 'Course Creator' },
  { email: 'student@test.com', role: 'Student' },
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
  const [showDevTools, setShowDevTools] = useState(false)

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
    <div className="relative min-h-screen flex items-center justify-center p-4 overflow-hidden">
      {/* Layered background with geometric pattern */}
      <div className="absolute inset-0 bg-gradient-to-br from-brand-900 via-brand-800 to-brand-950" />
      <div
        className="absolute inset-0 opacity-10"
        style={{
          backgroundImage: 'radial-gradient(circle at 2px 2px, white 1px, transparent 0)',
          backgroundSize: '32px 32px',
        }}
      />
      <div className="grain-overlay absolute inset-0" />

      {/* Ambient glow effects */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-brand-500/20 rounded-full blur-3xl" />
      <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-brand-400/10 rounded-full blur-3xl" />

      {/* Content */}
      <div className="relative z-10 w-full max-w-md">
        {/* Logo section - enters first */}
        <motion.div
          className="text-center mb-8"
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.5, ease: [0.25, 0.1, 0.25, 1] }}
        >
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-brand-400 to-brand-600 shadow-2xl shadow-brand-500/30 mb-4">
            <GraduationCap className="w-9 h-9 text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white tracking-tight mb-2">
            Welcome to VernonEdu
          </h1>
          <p className="text-brand-200/80 text-sm font-light">
            Your premium learning journey starts here
          </p>
        </motion.div>

        {/* Main form card */}
        <motion.div
          variants={stagger}
          initial="hidden"
          animate="visible"
          className="bg-white/95 backdrop-blur-xl rounded-3xl border border-white/20 shadow-2xl shadow-black/10 p-8"
        >
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            {/* Email field */}
            <motion.div variants={staggerItem} className="space-y-2">
              <label className="text-sm font-semibold text-neutral-800 tracking-wide uppercase text-xs">
                Email Address
              </label>
              <div className="relative group">
                <input
                  {...register('email')}
                  type="email"
                  autoComplete="email"
                  placeholder="you@example.com"
                  className={cn(
                    'w-full px-4 py-3 text-sm bg-neutral-50 border-2 border-neutral-200 rounded-xl',
                    'focus:outline-none focus:bg-white focus:border-brand-500',
                    'transition-all duration-200 ease-out',
                    'group-hover:border-neutral-300',
                    errors.email && 'border-red-400 focus:border-red-500'
                  )}
                />
                <div className="absolute inset-0 rounded-xl bg-brand-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none" />
              </div>
              {errors.email && (
                <motion.p
                  initial={{ opacity: 0, y: -4 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="text-xs text-red-500 font-medium"
                >
                  {errors.email.message}
                </motion.p>
              )}
            </motion.div>

            {/* Password field */}
            <motion.div variants={staggerItem} className="space-y-2">
              <label className="text-sm font-semibold text-neutral-800 tracking-wide uppercase text-xs">
                Password
              </label>
              <div className="relative group">
                <input
                  {...register('password')}
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  placeholder="••••••••"
                  className={cn(
                    'w-full px-4 py-3 pr-12 text-sm bg-neutral-50 border-2 border-neutral-200 rounded-xl',
                    'focus:outline-none focus:bg-white focus:border-brand-500',
                    'transition-all duration-200 ease-out',
                    'group-hover:border-neutral-300',
                    errors.password && 'border-red-400 focus:border-red-500'
                  )}
                />
                <div className="absolute inset-0 rounded-xl bg-brand-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none" />
                <motion.button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.95 }}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-neutral-600 transition-colors"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </motion.button>
              </div>
              {errors.password && (
                <motion.p
                  initial={{ opacity: 0, y: -4 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="text-xs text-red-500 font-medium"
                >
                  {errors.password.message}
                </motion.p>
              )}
            </motion.div>

            {/* Submit button */}
            <motion.div variants={staggerItem}>
              <motion.button
                type="submit"
                disabled={isSubmitting}
                whileHover={{ scale: isSubmitting ? 1 : 1.02 }}
                whileTap={{ scale: isSubmitting ? 1 : 0.98 }}
                className={cn(
                  'w-full py-3 text-sm font-bold text-white bg-gradient-to-r from-brand-600 to-brand-700 rounded-xl',
                  'shadow-lg shadow-brand-500/25 hover:shadow-xl hover:shadow-brand-500/40',
                  'disabled:opacity-60 disabled:cursor-not-allowed disabled:shadow-none',
                  'transition-all duration-200 ease-out'
                )}
              >
                {isSubmitting ? (
                  <span className="flex items-center justify-center gap-2">
                    <motion.span
                      animate={{ rotate: 360 }}
                      transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
                    >
                      <Code className="w-4 h-4" />
                    </motion.span>
                    Signing in...
                  </span>
                ) : (
                  'Sign in to your account'
                )}
              </motion.button>
            </motion.div>
          </form>

          {/* Register link */}
          <motion.div variants={staggerItem} className="mt-6 text-center">
            <p className="text-sm text-neutral-600">
              Don't have an account?{' '}
              <Link
                to="/register"
                className="font-semibold text-brand-600 hover:text-brand-700 transition-colors"
              >
                Create your free account
              </Link>
            </p>
          </motion.div>
        </motion.div>

        {/* Collapsible dev tools bar */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.8, duration: 0.3 }}
          className="mt-6"
        >
          <button
            type="button"
            onClick={() => setShowDevTools(!showDevTools)}
            className="flex items-center gap-2 mx-auto text-xs font-medium text-brand-200/70 hover:text-brand-200 transition-colors"
          >
            <Code className="w-3.5 h-3.5" />
            {showDevTools ? (
              <>
                <span>Hide</span>
                <ChevronUp className="w-3.5 h-3.5" />
              </>
            ) : (
              <>
                <span>Dev Tools</span>
                <ChevronDown className="w-3.5 h-3.5" />
              </>
            )}
          </button>

          <motion.div
            initial={false}
            animate={{ height: showDevTools ? 'auto' : 0, opacity: showDevTools ? 1 : 0 }}
            transition={{ duration: 0.2, ease: 'easeInOut' }}
            className="overflow-hidden mt-2"
          >
            <div className="bg-black/40 backdrop-blur-md rounded-xl border border-white/10 p-4">
              <p className="text-xs font-semibold text-brand-200/80 uppercase tracking-wider mb-3">
                Preset Users
              </p>
              <div className="flex flex-wrap gap-2">
                {PRESET_USERS.map((u) => (
                  <motion.button
                    key={u.email}
                    type="button"
                    onClick={() => fillPreset(u.email)}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    className="text-xs px-3 py-1.5 rounded-lg border border-brand-400/30 bg-brand-500/20 text-brand-100 hover:bg-brand-500/30 hover:border-brand-400/50 transition-all"
                  >
                    {u.role}
                  </motion.button>
                ))}
              </div>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </div>
  )
}
