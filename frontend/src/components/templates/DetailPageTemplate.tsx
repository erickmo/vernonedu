import { ReactNode } from 'react'
import PageHeader from '@/components/shared/PageHeader'

interface Breadcrumb {
  label: string
  href?: string
}

interface DetailPageTemplateProps {
  title: string
  subtitle?: string
  breadcrumbs: Breadcrumb[]
  actions?: ReactNode
  children: ReactNode
}

export default function DetailPageTemplate({
  title,
  subtitle,
  breadcrumbs,
  actions,
  children,
}: DetailPageTemplateProps) {
  return (
    <div className="space-y-6">
      <PageHeader
        title={title}
        subtitle={subtitle}
        breadcrumbs={breadcrumbs}
        actions={actions}
      />
      {children}
    </div>
  )
}
