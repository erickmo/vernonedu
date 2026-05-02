import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useCertificateTemplates } from '@/lib/api/certificate'
import type { CertificateTemplate } from '@/types/certificatetemplate'
import { CERT_TYPES } from '@/schemas/certificatetemplate'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'

const LIMIT = 15

const COLUMNS: Column<CertificateTemplate>[] = [
  { header: 'Name', accessor: 'name' },
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
    header: 'Updated',
    accessor: 'updated_at',
    cell: (r) =>
      r.updated_at ? new Date(r.updated_at).toLocaleDateString() : '—',
  },
]

export default function CertificateTemplates() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [type, setType] = useState<string>('')

  const { data, isLoading } = useCertificateTemplates()

  const filtered = useMemo(() => {
    const all = data ?? []
    return all.filter((t) => {
      if (type && t.type !== type) return false
      if (search) {
        const q = search.toLowerCase()
        if (!t.name.toLowerCase().includes(q)) return false
      }
      return true
    })
  }, [data, search, type])

  const start = (page - 1) * LIMIT
  const paginated = filtered.slice(start, start + LIMIT)

  return (
    <ListPageTemplate
      title="Certificate Templates"
      subtitle="Global certificate template registry"
      actions={
        <RoleGate action="create" resource="certificatetemplate">
          <Button onClick={() => navigate('/internal/certificate-templates/new')}>
            <Plus className="w-4 h-4" /> Add Template
          </Button>
        </RoleGate>
      }
      search={{
        value: search,
        onChange: (v) => { setPage(1); setSearch(v) },
        placeholder: 'Search by name',
      }}
      filters={
        <select
          value={type}
          onChange={(e) => { setPage(1); setType(e.target.value) }}
          className="px-3 py-2 text-sm border border-neutral-200 rounded-lg"
        >
          <option value="">All types</option>
          {CERT_TYPES.map((t) => (
            <option key={t} value={t} className="capitalize">{t}</option>
          ))}
        </select>
      }
      columns={COLUMNS}
      data={paginated}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: filtered.length }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/certificate-templates/${r.id}/edit`)}
    />
  )
}
