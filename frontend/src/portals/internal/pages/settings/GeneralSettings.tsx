import { Link } from 'react-router-dom'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'

const breadcrumbs: BreadcrumbItem[] = [{ label: 'Settings' }]

const SETTINGS_LINKS = [
  { to: '/internal/settings/general', label: 'General', desc: 'Company settings overview' },
  { to: '/internal/settings/facilitator-levels', label: 'Facilitator Levels', desc: 'Levels + fee per session' },
  { to: '/internal/settings/commissions', label: 'Commission', desc: 'Director-only commission config' },
  { to: '/internal/settings/holidays', label: 'Holidays', desc: 'National & company holidays' },
]

export default function GeneralSettings() {
  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Settings"
      subtitle="Configure company-wide settings"
    >
      <div className="grid sm:grid-cols-2 gap-4 max-w-3xl">
        {SETTINGS_LINKS.map((link) => (
          <Link
            key={link.to}
            to={link.to}
            className="block bg-white rounded-xl border border-neutral-100 p-5 hover:border-brand-300 hover:shadow-sm transition"
          >
            <div className="font-semibold">{link.label}</div>
            <div className="text-sm text-neutral-500 mt-1">{link.desc}</div>
          </Link>
        ))}
      </div>
    </StandardPageLayout>
  )
}
