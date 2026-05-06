import { useNavigate } from 'react-router-dom'
import { ClipboardList } from 'lucide-react'
import { FormPageTemplate } from '@/widgets/FormPageTemplate/FormPageTemplate'

export default function CharacterTestConfigPage() {
  const navigate = useNavigate()

  return (
    <FormPageTemplate
      title="Konfigurasi Tes Karakter"
      icon={<ClipboardList size={20} />}
      onBack={() => navigate(-1)}
      onSubmit={(e) => e.preventDefault()}
      onCancel={() => navigate(-1)}
      readonly={true}
      tabs={[
        {
          id: 'info',
          label: 'Informasi',
          content: (
            <div style={{
              padding: 'var(--space-6)',
              color: 'var(--color-text-secondary)',
              fontSize: 'var(--font-base)',
              lineHeight: 1.6,
            }}>
              <p>
                Konfigurasi tes karakter diatur per versi kursus. Buka halaman versi kursus untuk mengatur konfigurasi ini.
              </p>
            </div>
          ),
        },
      ]}
    />
  )
}
