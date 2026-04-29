import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { Bell } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'

interface NotificationData {
  id: string
  title: string
  type: string
  status: string
}

function useNotificationDetail(id: string): { data: NotificationData; isLoading: false } {
  return {
    data: { id, title: 'Notification Template', type: 'email', status: 'active' },
    isLoading: false,
  }
}

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'send-history', label: 'Send History' },
  { value: 'activity', label: 'Activity' },
]

export default function NotificationDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: notification } = useNotificationDetail(id)

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Notifications', to: '/internal/notifications' },
    { label: notification.title },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<Bell className="w-5 h-5 text-brand-600" />}
      title={notification.title}
      status={<StatusBadge status={notification.status} />}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Type</p>
            <p className="text-sm font-semibold text-neutral-900 capitalize">{notification.type}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Status</p>
            <StatusBadge status={notification.status} />
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Template ID</p>
            <p className="text-xs font-mono text-neutral-700">{id.slice(0, 8)}</p>
          </div>
        </div>
      )}

      {activeTab !== 'overview' && (
        <div className="py-12 text-center text-neutral-400 text-sm">
          {TABS.find(t => t.value === activeTab)?.label} — coming in next sprint
        </div>
      )}
    </DetailPageLayout>
  )
}
