import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowRight,
  Award,
  BookOpen,
  CheckCircle2,
  Eye,
  EyeOff,
  Lock,
  Mail,
  ShieldCheck,
  Sparkles,
  Users,
} from 'lucide-react'
import { useAuthStore } from '@/stores/auth.store'
import { authService } from '@/services/auth.service'
import type { VernonEduLoginResponse } from '@/types/auth.types'
import { useForm } from '@/hooks/useForm'
import { AppApiError } from '@/types/api.types'
import styles from './LoginPage.module.css'

interface LoginFormValues {
  email: string
  password: string
}

const PRESET_ACCOUNTS = [
  { role: 'Director', email: 'director@vernonedu.com', color: '#1A237E' },
  { role: 'Education Leader', email: 'eduleader@vernonedu.com', color: '#283593' },
  { role: 'Dept Leader', email: 'deptleader@vernonedu.com', color: '#3949AB' },
  { role: 'Course Owner', email: 'courseowner@vernonedu.com', color: '#00695C' },
  { role: 'Facilitator', email: 'facilitator@vernonedu.com', color: '#00796B' },
  { role: 'Operation Leader', email: 'opleader@vernonedu.com', color: '#534BAE' },
  { role: 'Customer Service', email: 'cs@vernonedu.com', color: '#7E57C2' },
  { role: 'Marketing', email: 'marketing@vernonedu.com', color: '#AB47BC' },
  { role: 'Accounting', email: 'accounting@vernonedu.com', color: '#E65100' },
]

const FEATURES = [
  { icon: BookOpen, label: 'Kurikulum', desc: 'Course, modul, dan approval siap dipantau' },
  { icon: Users, label: 'Operasional', desc: 'Enrollment, kelas, absensi, dan cabang' },
  { icon: Award, label: 'Sertifikasi', desc: 'Template, issue, dan QR verification' },
]

const METRICS = [
  { value: '24', label: 'modul operasional' },
  { value: '9', label: 'role dashboard' },
  { value: '1', label: 'pusat kontrol' },
]

export default function LoginPage() {
  const navigate = useNavigate()
  const login = useAuthStore((s) => s.login)
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [serverError, setServerError] = useState('')

  const { values, errors, field, handleSubmit, setValues } = useForm<LoginFormValues>({
    initialValues: { email: '', password: '' },
    validate: (v) => ({
      email: !v.email ? 'Email wajib diisi' : undefined,
      password: !v.password ? 'Kata sandi wajib diisi' : undefined,
    }),
  })

  const onSubmit = handleSubmit(async (v) => {
    setIsLoading(true)
    setServerError('')
    try {
      const response: VernonEduLoginResponse = await authService.login(v)
      login(response)
      navigate('/dashboard', { replace: true })
    } catch (err) {
      if (err instanceof AppApiError) {
        setServerError(err.message)
      } else {
        setServerError('Terjadi kesalahan, coba lagi')
      }
    } finally {
      setIsLoading(false)
    }
  })

  return (
    <div className={styles.root}>
      <div className={styles.brandPanel}>
        <div className={styles.brandTop}>
          <div className={styles.brandMark}>V</div>
          <span className={styles.brandName}>VernonEdu</span>
        </div>

        <div className={styles.brandContent}>
          <div className={styles.kicker}>
            <Sparkles size={15} />
            Education operations dashboard
          </div>
          <h1 className={styles.brandTitle}>Kelola seluruh perjalanan belajar dari satu ruang kerja.</h1>
          <p className={styles.brandSubtitle}>
            Masuk untuk mengatur kurikulum, enrollment, finance, marketing, sampai sertifikasi tanpa berpindah sistem.
          </p>

          <div className={styles.metricsGrid}>
            {METRICS.map((metric) => (
              <div key={metric.label} className={styles.metricCard}>
                <strong>{metric.value}</strong>
                <span>{metric.label}</span>
              </div>
            ))}
          </div>

          <div className={styles.featureCards}>
            {FEATURES.map((f) => (
              <div key={f.label} className={styles.featureCard}>
                <div className={styles.featureIcon}>
                  <f.icon size={20} />
                </div>
                <div>
                  <div className={styles.featureLabel}>{f.label}</div>
                  <div className={styles.featureDesc}>{f.desc}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className={styles.workflowCard} aria-label="Dashboard workflow preview">
          <div className={styles.workflowHeader}>
            <span>Today</span>
            <ShieldCheck size={16} />
          </div>
          <div className={styles.workflowItem}>
            <CheckCircle2 size={16} />
            <span>Course version approved</span>
          </div>
          <div className={styles.workflowItem}>
            <CheckCircle2 size={16} />
            <span>Batch enrollment synced</span>
          </div>
          <div className={styles.workflowItem}>
            <CheckCircle2 size={16} />
            <span>Certificate queue ready</span>
          </div>
        </div>
      </div>

      <div className={styles.formPanel}>
        <div className={styles.formWrapper}>
          <div className={styles.mobileLogo}>
            <span className={styles.mobileLogoIcon}>V</span>
            <span className={styles.mobileLogoText}>VernonEdu</span>
          </div>

          <div className={styles.formHeader}>
            <p className={styles.formGreeting}>Selamat datang</p>
            <h2 className={styles.formTitle}>Masuk ke Akun Anda</h2>
            <p className={styles.formSubtitle}>Masukkan email dan kata sandi untuk melanjutkan</p>
          </div>

          <form onSubmit={onSubmit} className={styles.form} noValidate>
            <div className={styles.field}>
              <label htmlFor="email" className={styles.label}>Email</label>
              <div className={styles.inputWrap}>
                <Mail size={16} className={styles.inputIcon} />
                <input
                  id="email"
                  type="email"
                  autoComplete="email"
                  placeholder="nama@perusahaan.com"
                  className={styles.input}
                  aria-invalid={!!errors.email}
                  {...field('email')}
                  value={String(values.email)}
                />
              </div>
              {errors.email && <p className={styles.error}>{errors.email}</p>}
            </div>

            <div className={styles.field}>
              <label htmlFor="password" className={styles.label}>Kata Sandi</label>
              <div className={styles.inputWrap}>
                <Lock size={16} className={styles.inputIcon} />
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  placeholder="Masukkan kata sandi"
                  className={styles.input}
                  aria-invalid={!!errors.password}
                  {...field('password')}
                  value={String(values.password)}
                />
                <button
                  type="button"
                  className={styles.eyeBtn}
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'}
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
              {errors.password && <p className={styles.error}>{errors.password}</p>}
            </div>

            {serverError && (
              <div className={styles.serverError} role="alert">
                {serverError}
              </div>
            )}

            <button type="submit" className={styles.submitBtn} disabled={isLoading}>
              {isLoading ? (
                <span className={styles.spinner} />
              ) : (
                <>
                  Masuk
                  <ArrowRight size={16} />
                </>
              )}
            </button>
          </form>

          <div className={styles.divider}>
            <span className={styles.dividerLine} />
            <span className={styles.dividerText}>Quick login (dev)</span>
            <span className={styles.dividerLine} />
          </div>

          <div className={styles.presetsGrid}>
            {PRESET_ACCOUNTS.map((acc) => (
              <button
                key={acc.email}
                type="button"
                className={styles.presetPill}
                style={{ '--pill-color': acc.color } as React.CSSProperties}
                onClick={() => {
                  setValues({ email: acc.email, password: 'password123' })
                }}
                title={`Email: ${acc.email}\nPassword: password123`}
              >
                {acc.role}
              </button>
            ))}
          </div>

          <div className={styles.formFooter}>
            &copy; {new Date().getFullYear()} VernonEdu. All rights reserved.
          </div>
        </div>
      </div>
    </div>
  )
}
