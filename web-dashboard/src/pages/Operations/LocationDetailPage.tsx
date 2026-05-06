import { useParams, useNavigate } from 'react-router-dom'
import { Building2, DoorOpen, Pencil, MapPin, FileText, Trash2 } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { useDeleteConfirmModal } from '@/widgets/Modals/DeleteConfirmModal'
import { locationService } from '@/services/location.service'
import { RoomsManager, type Room } from './RoomsManager'

export default function LocationDetailPage() {
  const { buildingId } = useParams<{ buildingId: string }>()
  const navigate = useNavigate()
  const confirmDelete = useDeleteConfirmModal()

  const { data: building, isLoading: loadingBuilding } = useQuery({
    queryKey: ['building', buildingId],
    queryFn: () => locationService.getBuilding(buildingId!),
  })

  const { data: rooms = [], isLoading: loadingRooms } = useQuery<Room[]>({
    queryKey: ['rooms', buildingId],
    queryFn: async () => {
      const data = await locationService.listRooms(buildingId)
      return Array.isArray(data) ? data : (data as any)?.items ?? []
    },
  })

  const b = building as any

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Gedung',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/pengembangan/locations/${buildingId}/edit`),
      variant: 'default',
    },
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: () => confirmDelete('Hapus Lokasi', 'Yakin ingin menghapus lokasi ini?', async () => {
        await locationService.deleteBuilding(buildingId!)
        toast.success('Lokasi berhasil dihapus')
        navigate('/pengembangan/locations')
      }),
      variant: 'danger' as const,
    },
  ]

  const overviewContent = (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' }}>
      {/* Ownership */}
      <div style={{ marginBottom: 'var(--space-3)' }}>
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: (b as any)?.ownership === 'partner' ? 'var(--color-info-light)' : 'var(--color-surface-alt)',
          color: (b as any)?.ownership === 'partner' ? 'var(--color-info-dark)' : 'var(--color-text-secondary)',
        }}>
          {(b as any)?.ownership === 'partner' ? 'Milik Partner' : 'Milik Sendiri'}
        </span>
        {(b as any)?.partner && (
          <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginLeft: 8 }}>
            Partner:{' '}
            <a href={`/business-dev/partners/${(b as any).partner.id}`}
               style={{ color: 'var(--color-primary)', fontWeight: 600 }}>
              {(b as any).partner.name}
            </a>
          </span>
        )}
      </div>
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
        gap: 'var(--space-3)',
      }}>
        <div style={{
          padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
          display: 'flex', alignItems: 'center', gap: 'var(--space-3)',
        }}>
          <div style={{
            width: 40, height: 40, borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary-subtle)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: 'var(--color-primary)',
          }}>
            <DoorOpen size={18} />
          </div>
          <div>
            <div style={{ fontSize: 'var(--font-2xl)', fontWeight: 700, lineHeight: 1.2 }}>
              {loadingRooms ? '—' : rooms.length}
            </div>
            <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
              Ruangan
            </div>
          </div>
        </div>

        <div style={{
          padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
          display: 'flex', alignItems: 'center', gap: 'var(--space-3)',
        }}>
          <div style={{
            width: 40, height: 40, borderRadius: 'var(--radius-md)',
            background: 'var(--color-secondary-subtle, #f0fdf4)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: 'var(--color-secondary, #16a34a)',
          }}>
            <Building2 size={18} />
          </div>
          <div>
            <div style={{ fontSize: 'var(--font-2xl)', fontWeight: 700, lineHeight: 1.2 }}>
              {loadingRooms ? '—' : rooms.reduce((sum, r) => sum + (r.capacity ?? 0), 0) || '—'}
            </div>
            <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
              Total Kapasitas
            </div>
          </div>
        </div>
      </div>

      {b?.address && (
        <div style={{
          padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
          display: 'flex', gap: 'var(--space-3)', alignItems: 'flex-start',
        }}>
          <MapPin size={16} style={{ color: 'var(--color-text-tertiary)', marginTop: 2, flexShrink: 0 }} />
          <div>
            <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 2 }}>Alamat</div>
            <div style={{ fontSize: 'var(--font-sm)' }}>{b.address}</div>
          </div>
        </div>
      )}

      {b?.description && (
        <div style={{
          padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
          display: 'flex', gap: 'var(--space-3)', alignItems: 'flex-start',
        }}>
          <FileText size={16} style={{ color: 'var(--color-text-tertiary)', marginTop: 2, flexShrink: 0 }} />
          <div>
            <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 2 }}>Deskripsi</div>
            <div style={{ fontSize: 'var(--font-sm)', lineHeight: 1.6 }}>{b.description}</div>
          </div>
        </div>
      )}
    </div>
  )


  return (
    <DetailPageTemplate
      onBack={() => navigate('/pengembangan/locations')}
      icon={<Building2 size={20} />}
      title={loadingBuilding ? 'Memuat...' : (b?.name ?? 'Gedung')}
      actions={actions}
      helpTitle="Detail Gedung"
      helpText="Halaman ini menampilkan informasi gedung dan daftar ruangan yang dapat dikelola langsung."
      sections={[
        {
          id: 'overview',
          label: 'Overview',
          icon: <Building2 size={14} />,
          tabs: [{ id: 'overview', label: 'Overview', content: overviewContent }],
        },
        {
          id: 'rooms',
          label: 'Ruangan',
          icon: <DoorOpen size={14} />,
          tabs: [{ id: 'rooms', label: 'Ruangan', content: <RoomsManager buildingId={buildingId!} /> }],
        },
      ]}
    />
  )
}
