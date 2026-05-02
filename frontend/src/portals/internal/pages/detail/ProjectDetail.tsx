import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Briefcase, Pencil, Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import DetailPageLayout, { type BreadcrumbItem, type DetailTab } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { useProject, useDeleteProject } from '@/lib/api/project'

const TABS: DetailTab[] = [{ value: 'overview', label: 'Overview' }]

function formatIDR(n: number) {
  return `Rp ${n.toLocaleString()}`
}

export default function ProjectDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = useProject(id)
  const del = useDeleteProject()
  const [confirmDelete, setConfirmDelete] = useState(false)

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Projects', to: '/internal/projects' },
    { label: data.name },
  ]

  async function handleDelete() {
    try {
      await del.mutateAsync(id)
      toast.success('Project deleted')
      navigate('/internal/projects')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to delete project')
    } finally {
      setConfirmDelete(false)
    }
  }

  const profit = data.earning - data.budget

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<Briefcase className="w-5 h-5 text-brand-600" />}
      title={data.name}
      subtitle={`${data.code} · ${data.start_date} → ${data.end_date}`}
      status={<StatusBadge status={data.status} />}
      actions={
        <div className="flex gap-2">
          <RoleGate action="update" resource="project">
            <Button onClick={() => navigate(`/internal/projects/${id}/edit`)}>
              <Pencil className="w-4 h-4" /> Edit
            </Button>
          </RoleGate>
          <RoleGate action="delete" resource="project">
            <Button variant="danger" onClick={() => setConfirmDelete(true)}>
              <Trash2 className="w-4 h-4" /> Delete
            </Button>
          </RoleGate>
        </div>
      }
      tabs={TABS}
      activeTab="overview"
      onTabChange={() => {}}
    >
      <div className="space-y-6 max-w-3xl">
        {data.description && (
          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Description</h3>
            <p className="text-sm text-neutral-700 whitespace-pre-wrap">{data.description}</p>
          </section>
        )}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Budget</p>
            <p className="text-sm font-semibold">{formatIDR(data.budget)}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Earning</p>
            <p className="text-sm font-semibold">{formatIDR(data.earning)}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Profit</p>
            <p
              className={`text-sm font-semibold ${
                profit >= 0 ? 'text-emerald-700' : 'text-rose-700'
              }`}
            >
              {formatIDR(profit)}
            </p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Partner</p>
            {data.partner_id ? (
              <button
                type="button"
                onClick={() => navigate(`/internal/partners/${data.partner_id}`)}
                className="text-sm font-semibold text-brand-600 hover:underline text-left"
              >
                {data.partner_name ?? data.partner_id}
              </button>
            ) : (
              <p className="text-sm text-neutral-400">—</p>
            )}
          </div>
        </div>
      </div>

      <ConfirmDialog
        open={confirmDelete}
        title="Delete project?"
        description={`Are you sure you want to delete "${data.name}"?`}
        confirmLabel="Delete"
        destructive
        onConfirm={handleDelete}
        onCancel={() => setConfirmDelete(false)}
      />
    </DetailPageLayout>
  )
}
