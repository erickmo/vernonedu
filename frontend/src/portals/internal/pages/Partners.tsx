import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus, AlertTriangle } from 'lucide-react'
import { usePartners, useExpiringMous } from '@/lib/api/partner'
import { PARTNER_STATUSES, PARTNER_TYPES, type Partner } from '@/types/partner'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'

const LIMIT = 15

const COLUMNS: Column<Partner>[] = [
  { header: 'Name', accessor: 'name' },
  {
    header: 'Type',
    accessor: 'type',
    cell: (r) => <span className="text-sm capitalize">{r.type}</span>,
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => (
      <span
        className={
          r.status === 'active'
            ? 'inline-flex px-2 py-0.5 rounded-full text-xs bg-emerald-50 text-emerald-700'
            : r.status === 'prospect'
            ? 'inline-flex px-2 py-0.5 rounded-full text-xs bg-amber-50 text-amber-700'
            : 'inline-flex px-2 py-0.5 rounded-full text-xs bg-neutral-100 text-neutral-500'
        }
      >
        {r.status}
      </span>
    ),
  },
  { header: 'Contact', accessor: 'contact_name' },
  { header: 'Email', accessor: 'contact_email' },
]

export default function Partners() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [type, setType] = useState<string>('')
  const [status, setStatus] = useState<string>('')

  const { data, isLoading } = usePartners({
    page,
    limit: LIMIT,
    type: (type || undefined) as any,
    status: (status || undefined) as any,
  })
  const { data: expiring = [] } = useExpiringMous()

  return (
    <div className="space-y-4">
      {expiring.length > 0 && (
        <div className="flex items-start gap-3 p-4 rounded-xl border border-amber-200 bg-amber-50">
          <AlertTriangle className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
          <div className="text-sm">
            <p className="font-semibold text-amber-900">
              {expiring.length} MOU{expiring.length > 1 ? 's' : ''} expiring soon
            </p>
            <ul className="mt-1 space-y-0.5 text-amber-800">
              {expiring.slice(0, 3).map((m) => (
                <li key={m.id}>
                  {m.title} ({m.partner_name ?? m.partner_id}) — {m.days_until_expiry} days
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}

      <ListPageTemplate
        title="Partners"
        subtitle="Manage business partners and MOUs"
        actions={
          <div className="flex gap-2">
            <Select value={type} onChange={(e) => setType(e.target.value)}>
              <option value="">All types</option>
              {PARTNER_TYPES.map((t) => (
                <option key={t} value={t}>{t}</option>
              ))}
            </Select>
            <Select value={status} onChange={(e) => setStatus(e.target.value)}>
              <option value="">All statuses</option>
              {PARTNER_STATUSES.map((s) => (
                <option key={s} value={s}>{s}</option>
              ))}
            </Select>
            <RoleGate action="create" resource="mou">
              <Button onClick={() => navigate('/internal/partners/new')}>
                <Plus className="w-4 h-4" /> Add Partner
              </Button>
            </RoleGate>
          </div>
        }
        columns={COLUMNS}
        data={data?.data ?? []}
        loading={isLoading}
        pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
        onPageChange={setPage}
        rowKey={(r) => r.id}
        onRowClick={(r) => navigate(`/internal/partners/${r.id}`)}
      />
    </div>
  )
}
