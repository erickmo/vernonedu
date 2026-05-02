import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useCertificates } from '@/lib/api/certificate-issue'
import type { Certificate } from '@/types/certificate'
import { CERTIFICATE_TYPES } from '@/schemas/certificate'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'

const LIMIT = 15

const STATUS_BADGE: Record<string, string> = {
  issued: 'bg-emerald-50 text-emerald-700',
  revoked: 'bg-red-50 text-red-700',
}

const COLUMNS: Column<Certificate>[] = [
  { header: 'Code', accessor: 'code', cell: (r) => <span className="font-mono text-xs">{r.code || '—'}</span> },
  { header: 'Student', accessor: 'student_id', cell: (r) => r.student_name || r.student_id },
  { header: 'Batch', accessor: 'batch_id', cell: (r) => r.batch_name || r.batch_id },
  {
    header: 'Type',
    accessor: 'type',
    cell: (r) => (
      <span className="capitalize px-2 py-0.5 rounded-md bg-neutral-100 text-xs">
        {r.type}
      </span>
    ),
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => (
      <span className={`capitalize px-2 py-0.5 rounded-md text-xs ${STATUS_BADGE[r.status] ?? 'bg-neutral-100'}`}>
        {r.status}
      </span>
    ),
  },
  {
    header: 'Issued',
    accessor: 'issued_at',
    cell: (r) => (r.issued_at ? new Date(r.issued_at).toLocaleDateString() : '—'),
  },
]

export default function Certificates() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [type, setType] = useState<string>('')
  const [batchId, setBatchId] = useState<string>('')

  const { data, isLoading } = useCertificates({
    type: type || undefined,
    batch_id: batchId || undefined,
  })

  const filtered = useMemo(() => {
    const all = data ?? []
    if (!search) return all
    const q = search.toLowerCase()
    return all.filter(
      (c) =>
        (c.code ?? '').toLowerCase().includes(q) ||
        (c.student_name ?? '').toLowerCase().includes(q) ||
        (c.student_id ?? '').toLowerCase().includes(q),
    )
  }, [data, search])

  const start = (page - 1) * LIMIT
  const paginated = filtered.slice(start, start + LIMIT)

  return (
    <ListPageTemplate
      title="Certificates"
      subtitle="Issued certificates of participant & competency"
      actions={
        <RoleGate action="create" resource="certificate">
          <Button onClick={() => navigate('/internal/certificates/new')}>
            <Plus className="w-4 h-4" /> Issue Certificate
          </Button>
        </RoleGate>
      }
      search={{
        value: search,
        onChange: (v) => { setPage(1); setSearch(v) },
        placeholder: 'Search by code or student',
      }}
      filters={
        <div className="flex gap-2">
          <select
            value={type}
            onChange={(e) => { setPage(1); setType(e.target.value) }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg"
          >
            <option value="">All types</option>
            {CERTIFICATE_TYPES.map((t) => (
              <option key={t} value={t} className="capitalize">{t}</option>
            ))}
          </select>
          <input
            value={batchId}
            onChange={(e) => { setPage(1); setBatchId(e.target.value) }}
            placeholder="Filter by batch ID"
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg w-44"
          />
        </div>
      }
      columns={COLUMNS}
      data={paginated}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: filtered.length }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/certificates/${r.id}`)}
    />
  )
}
