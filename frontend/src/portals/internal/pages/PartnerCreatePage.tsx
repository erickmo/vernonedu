import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import Button from '@/components/ui/Button'
import { useCreatePartner, type Partner } from '@/lib/api/partnerships'

const PARTNER_TYPES: Partner['type'][] = ['corporate', 'government', 'ngo', 'university']
const PARTNER_STATUSES: Partner['status'][] = ['active', 'inactive', 'prospect']

export default function PartnerCreatePage() {
  const navigate = useNavigate()
  const createMutation = useCreatePartner()

  const [form, setForm] = useState({
    name: '',
    type: 'corporate' as Partner['type'],
    contact_name: '',
    contact_email: '',
    contact_phone: '',
    status: 'prospect' as Partner['status'],
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.name.trim()) return
    try {
      const result = await createMutation.mutateAsync(form)
      navigate(`/internal/partners/${result.id}`)
    } catch (err) {
      console.error('Failed to create partner:', err)
    }
  }

  const handleCancel = () => navigate('/internal/partners')

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Partners', to: '/internal/partners' },
    { label: 'New Partner' },
  ]

  return (
    <StandardPageLayout
      breadcrumbs={breadcrumbs}
      title="Create New Partner"
      subtitle="Add a new business partner"
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
          <Button variant="secondary" onClick={handleCancel} type="button" disabled={createMutation.isPending}>
            Cancel
          </Button>
          <Button variant="primary" type="submit" disabled={createMutation.isPending}>
            {createMutation.isPending ? 'Creating...' : 'Create Partner'}
          </Button>
        </div>
      </form>
    </StandardPageLayout>
  )
}
