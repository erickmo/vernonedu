import { useNavigate } from 'react-router-dom'
import { Briefcase } from 'lucide-react'
import { FormPageTemplate } from '@/widgets/FormPageTemplate/FormPageTemplate'

export default function InternshipConfigPage() {
  const navigate = useNavigate()

  return (
    <FormPageTemplate
      title="Konfigurasi Program Magang"
      icon={<Briefcase size={20} />}
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
                Konfigurasi magang diatur per versi kursus. Buka halaman versi kursus untuk mengatur konfigurasi ini.
              </p>
            </div>
          ),
        },
      ]}
    />
  )
}
