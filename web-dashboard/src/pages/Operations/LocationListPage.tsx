import { Building2, DoorOpen } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef } from '@/widgets/DataTable/DataTable'
import { locationService } from '@/services/location.service'

interface RoomItem {
  id: string
  name: string
  capacity: number
}

interface Building {
  id: string
  name: string
  address?: string
  room_count: number
  total_capacity: number
  rooms: RoomItem[]
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
      const count = row.room_count ?? 0
      return count > 0
        ? (
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 4,
            padding: '2px 10px', borderRadius: 'var(--radius-full)',
            background: 'var(--color-primary-subtle)', color: 'var(--color-primary)',
            fontSize: 'var(--font-sm)', fontWeight: 600,
          }}>
            {count} ruangan
          </span>
        )
        : <span style={{ color: 'var(--color-text-tertiary)' }}>—</span>
    },
  },
  {
    key: 'total_capacity',
    header: 'Total Kapasitas',
    width: 150,
    align: 'center',
    render: (_v, row) => {
      const cap = row.total_capacity ?? 0
      return cap > 0
        ? <span style={{ fontWeight: 500 }}>{cap} orang</span>
        : <span style={{ color: 'var(--color-text-tertiary)' }}>—</span>
    },
  },
  {
    key: 'ownership',
    header: 'Kepemilikan',
    width: 160,
    render: (_v: any, row: any) => (
      <span style={{
        display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
        fontSize: 'var(--font-xs)', fontWeight: 600,
        background: row.ownership === 'partner' ? 'var(--color-info-light)' : 'var(--color-surface-alt)',
        color: row.ownership === 'partner' ? 'var(--color-info-dark)' : 'var(--color-text-secondary)',
      }}>
        {row.ownership === 'partner'
          ? (row.partner_name ? `Partner: ${row.partner_name}` : 'Milik Partner')
          : 'Milik Sendiri'}
      </span>
    ),
  },
]

export function RoomList({ rooms }: { rooms: RoomItem[] }) {
  if (rooms.length === 0) {
    return (
      <div style={{ padding: '12px 16px 12px 56px', color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>
        Belum ada ruangan
      </div>
    )
  }
  return (
    <div style={{ padding: '8px 16px 12px 56px' }}>
      <ul style={{ margin: 0, padding: 0, listStyle: 'none', display: 'flex', flexDirection: 'column', gap: 6 }}>
        {rooms.map((room) => (
          <li key={room.id} style={{
            display: 'flex', alignItems: 'center', gap: 8,
            padding: '6px 12px', borderRadius: 6,
            background: 'var(--color-surface)', fontSize: 'var(--font-sm)',
          }}>
            <DoorOpen size={14} style={{ color: 'var(--color-text-secondary)', flexShrink: 0 }} />
            <span style={{ fontWeight: 500 }}>{room.name}</span>
            {room.capacity > 0 && (
              <span style={{
                marginLeft: 'auto', color: 'var(--color-text-secondary)',
                fontSize: 'var(--font-xs)',
              }}>
                {room.capacity} orang
              </span>
            )}
          </li>
        ))}
      </ul>
    </div>
  )
}

export default function LocationListPage() {
  const navigate = useNavigate()

  return (
    <ListPageTemplate<Building>
      title="Lokasi & Gedung"
      queryKey="locations/buildings"
      fetcher={async (params) => {
        const data = await locationService.listBuildings({
          search: params.search,
          offset: params.offset,
          limit: params.limit,
        })
        let items: Building[] = Array.isArray(data)
          ? data
          : (data as any)?.data ?? (data as any)?.items ?? []
        if (params.sort && params.sort.length > 0) {
          const [sortKey, sortDir] = params.sort[0]
          items = [...items].sort((a, b) => {
            const av = a[sortKey] ?? ''
            const bv = b[sortKey] ?? ''
            if (av < bv) return sortDir === 1 ? -1 : 1
            if (av > bv) return sortDir === 1 ? 1 : -1
            return 0
          })
        }
        const total = (data as any)?.total ?? items.length
        return { items, total, limit: params.limit ?? 9999, offset: params.offset ?? 0 }
      }}
      columns={columns}
      hidePagination
      searchPlaceholder="Cari gedung atau alamat..."
      exportFilename="lokasi"
      emptyTitle="Belum ada gedung"
      emptyDescription="Tambahkan gedung dan ruangan untuk mengelola lokasi pelatihan."
      helpTitle="Lokasi & Gedung"
      helpText="Kelola gedung dan ruangan yang digunakan untuk pelaksanaan kursus. Setiap ruangan memiliki kapasitas dan fasilitas yang bisa dicocokkan dengan kebutuhan sesi."
      onAdd={() => navigate('/pengembangan/locations/new')}
      addLabel="Tambah Gedung"
      onRowClick={row => navigate(`/pengembangan/locations/${row.id}`)}
    />
  )
}
