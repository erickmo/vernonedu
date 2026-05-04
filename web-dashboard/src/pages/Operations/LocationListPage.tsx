import { Building2 } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef } from '@/widgets/DataTable/DataTable'
import { locationService } from '@/services/location.service'

interface Building {
  id: string
  name: string
  address?: string
  room_count?: number
  rooms?: Array<{
    id: string
    name: string
    capacity?: number
    facilities?: string[]
  }>
  [key: string]: unknown
}

const columns: ColumnDef<Building>[] = [
  {
    key: 'name',
    header: 'Nama Gedung',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Building2 size={16} />
        </div>
        <div>
          <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.name || '—'}</div>
          {row.address && (
            <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
              {row.address.length > 60 ? row.address.slice(0, 60) + '...' : row.address}
            </div>
          )}
        </div>
      </div>
    ),
  },
  {
    key: 'room_count',
    header: 'Jumlah Ruangan',
    width: 140,
    align: 'center',
    render: (_v, row) => {
      const count = row.room_count ?? row.rooms?.length ?? 0
      return count > 0 ? count : '—'
    },
  },
  {
    key: 'total_capacity',
    header: 'Total Kapasitas',
    width: 140,
    align: 'center',
    render: (_v, row) => {
      if (!row.rooms?.length) return '—'
      const total = row.rooms.reduce((sum, r) => sum + (r.capacity ?? 0), 0)
      return total > 0 ? `${total} orang` : '—'
    },
  },
  {
    key: 'facilities',
    header: 'Fasilitas',
    width: 240,
    render: (_v, row) => {
      const allFacilities = row.rooms
        ?.flatMap((r) => r.facilities ?? [])
        ?.filter((v, i, a) => a.indexOf(v) === i) ?? []
      if (allFacilities.length === 0) return '—'
      const shown = allFacilities.slice(0, 3)
      const extra = allFacilities.length - shown.length
      return (
        <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
          {shown.map((f) => (
            <span key={f} style={{
              display: 'inline-block', padding: '1px 8px', borderRadius: 'var(--radius-full)',
              fontSize: 'var(--font-xs)', background: 'var(--color-surface-alt)',
              color: 'var(--color-text-secondary)',
            }}>
              {f}
            </span>
          ))}
          {extra > 0 && (
            <span style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)' }}>
              +{extra}
            </span>
          )}
        </div>
      )
    },
  },
]

export default function LocationListPage() {
  return (
    <ListPageTemplate<Building>
      title="Lokasi & Gedung"
      queryKey="locations/buildings"
      fetcher={async () => {
        const data = await locationService.listBuildings()
        const items = Array.isArray(data) ? data : (data as any)?.items ?? []
        return { items, total: items.length, limit: 9999, offset: 0 }
      }}
      columns={columns}
      hidePagination
      searchPlaceholder="Cari gedung..."
      exportFilename="lokasi"
      emptyTitle="Belum ada gedung"
      emptyDescription="Tambahkan gedung dan ruangan untuk mengelola lokasi pelatihan."
      helpTitle="Lokasi & Gedung"
      helpText="Kelola gedung dan ruangan yang digunakan untuk pelaksanaan kursus. Setiap ruangan memiliki kapasitas dan fasilitas yang bisa dicocokkan dengan kebutuhan sesi."
    />
  )
}
