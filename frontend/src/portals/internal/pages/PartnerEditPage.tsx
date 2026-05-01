import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { StandardPageLayout, BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import { usePartner, useUpdatePartner, type Partner } from '@/lib/api/partnerships'

const PARTNER_TYPES: Partner['type'][] = ['corporate', 'government', 'ngo', 'university']
const PARTNER_STATUSES: Partner['status'][] = ['active', 'inactive', 'prospect']

export default function PartnerEditPage() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: partner, isLoading } = usePartner(id)
  const updateMutation = useUpdatePartner()

  const [form, setForm] = useState({
    name: '',
    type: 'corporate' as Partner['type'],
    contact_name: '',
    contact_email: '',
    contact_phone: '',
    status: 'prospect' as Partner['status'],
  })

  useEffect(() => {
    if (partner) {
      setForm({
        name: partner.name,
        type: partner.type,
        contact_name: partner.contact_name,
        contact_email: partner.contact_email,
        contact_phone: partner.contact_phone,
        status: partner.status,
      })
    }
  }, [partner])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.name.trim()) return
    try {
      await updateMutation.mutateAsync({ id, ...form })
      navigate(`/internal/partners/${id}`)
    } catch (err) {
      console.error('Failed to update partner:', err)
    }
  }

  const handleCancel = () => navigate(`/internal/partners/${id}`)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-24">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!partner) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <p className="text-neutral-500">Partner not found.</p>
        <button onClick={() => navigate(-1)} className="text-sm text-brand-600 hover:underline">
          Go back
        </button>
      </div>
    )
  }

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Partners', to: '/internal/partners' },
    { label: partner.name, to: `/internal/partners/${id}` },
    { label: 'Edit' },
  ]

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title={`Edit ${partner.name}`}
      subtitle="Update partner information"
    >
      <form onSubmit={handleSubmit} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <div>
          <label className="block text-sm font-medium text-neutral-700 mb-1">Name *</label>
          <input
            type="text"
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-neutral-700 mb-1">Type *</label>
          <select
            value={form.type}
            onChange={(e) => setForm({ ...form, type: e.target.value as Partner['type'] })}
            className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
          >
            {PARTNER_TYPES.map((t) => (
              <option key={t} value={t}>{t.charAt(0).toUpperCase() + t.slice(1)}</option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-neutral-700 mb-1">Status *</label>
          <select
            value={form.status}
            onChange={(e) => setForm({ ...form, status: e.target.value as Partner['status'] })}
            className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
          >
            {PARTNER_STATUSES.map((s) => (
              <option key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-neutral-700 mb-1">Contact Name</label>
          <input
            type="text"
            value={form.contact_name}
            onChange={(e) => setForm({ ...form, contact_name: e.target.value })}
            className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-neutral-700 mb-1">Contact Email</label>
          <input
            type="email"
            value={form.contact_email}
            onChange={(e) => setForm({ ...form, contact_email: e.target.value })}
            className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-neutral-700 mb-1">Contact Phone</label>
          <input
            type="tel"
            value={form.contact_phone}
            onChange={(e) => setForm({ ...form, contact_phone: e.target.value })}
            className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>

        <div className="flex justify-end gap-2 pt-4 border-t border-neutral-100">
          <Button variant="secondary" onClick={handleCancel} type="button" disabled={updateMutation.isPending}>
            Cancel
          </Button>
          <Button variant="primary" type="submit" disabled={updateMutation.isPending}>
            {updateMutation.isPending ? 'Saving...' : 'Save Changes'}
          </Button>
        </div>
      </form>
    </StandardPageLayout>
  )
}
