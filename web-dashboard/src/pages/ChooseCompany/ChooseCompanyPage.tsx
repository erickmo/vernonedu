import { useNavigate } from 'react-router-dom'
import { Building2, LogOut } from 'lucide-react'
import { useAuthStore } from '@/stores/auth.store'
import styles from './ChooseCompanyPage.module.css'

export default function ChooseCompanyPage() {
  const navigate = useNavigate()
  const { user, logout } = useAuthStore()

  function handleLogout() {
    logout()
    navigate('/login')
  }

  return (
    <div className={styles.root}>
      <div className={styles.card}>
        <div className={styles.header}>
          <Building2 size={28} className={styles.headerIcon} />
          <div>
            <h1 className={styles.title}>Pilih Perusahaan</h1>
            <p className={styles.subtitle}>
              Selamat datang, <strong>{user?.name}</strong>.
            </p>
          </div>
        </div>

        <div className={styles.groups}>
          <p className={styles.empty}>
            Mode single-tenant aktif. Halaman ini tidak digunakan.
          </p>
        </div>

        <button className={styles.logoutBtn} onClick={handleLogout}>
          <LogOut size={14} />
          Keluar dari akun
        </button>
      </div>
    </div>
  )
}
