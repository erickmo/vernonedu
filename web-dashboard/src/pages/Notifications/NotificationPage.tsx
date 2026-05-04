import { useQueryClient } from '@tanstack/react-query'
import { BellDot, CheckCheck } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { notificationService } from '@/services/notification.service'
import type { Notification } from '@/services/notification.service'
import { toast } from '@/widgets/Toast/Toast'

const QUERY_KEY = 'notifications'

const columns: ColumnDef<Notification>[] = [
  {
    key: 'title',
    header: 'Judul',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 8, height: 8, borderRadius: '50%', flexShrink: 0,
          background: row.is_read ? 'var(--color-surface-alt)' : 'var(--color-primary)',
        }} />
        <div>
          <div style={{ fontWeight: row.is_read ? 400 : 600, fontSize: 'var(--font-base)' }}>
            {row.title}
          </div>
          {row.body && (
            <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
              {row.body.length > 80 ? row.body.slice(0, 80) + '...' : row.body}
            </div>
          )}
        </div>
      </div>
    ),
  },
  {
    key: 'type',
    header: 'Tipe',
    sortable: true,
    width: 140,
    render: (_v, row) => row.type || '—',
  },
  {
    key: 'is_read',
    header: 'Status',
    width: 110,
    align: 'center',
    render: (_v, row) => (
      <span style={{
        display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
        fontSize: 'var(--font-xs)', fontWeight: 600,
        background: row.is_read ? 'var(--color-surface-alt)' : 'var(--color-primary-subtle)',
        color: row.is_read ? 'var(--color-text-tertiary)' : 'var(--color-primary)',
      }}>
        {row.is_read ? 'Dibaca' : 'Belum Dibaca'}
      </span>
    ),
  },
  {
    key: 'created_at',
    header: 'Tanggal',
    sortable: true,
    width: 140,
    render: (_v, row) =>
      row.created_at
        ? new Date(row.created_at * 1000).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
        : '—',
  },
]

export default function NotificationPage() {
  const queryClient = useQueryClient()

  const rowActions: RowActionDef<Notification>[] = [
    {
      key: 'mark-read',
      label: 'Tandai Dibaca',
      icon: <BellDot size={14} />,
      visible: (row) => !row.is_read,
      onClick: async (row) => {
        try {
          await notificationService.markRead(row.id)
          await queryClient.invalidateQueries({ queryKey: [QUERY_KEY] })
          toast.success('Notifikasi ditandai sebagai dibaca')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menandai notifikasi')
        }
      },
    },
  ]

  async function handleMarkAllRead() {
    try {
      await notificationService.markAllRead()
      await queryClient.invalidateQueries({ queryKey: [QUERY_KEY] })
      toast.success('Semua notifikasi ditandai sebagai dibaca')
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Gagal menandai semua notifikasi')
    }
  }

  const headerActions = (
    <button
      onClick={handleMarkAllRead}
      style={{
        display: 'flex', alignItems: 'center', gap: 6,
        padding: '6px 14px', borderRadius: 'var(--radius-md)',
        border: '1px solid var(--color-border)', background: 'var(--color-surface)',
        color: 'var(--color-text-primary)', fontSize: 'var(--font-sm)',
        cursor: 'pointer', fontWeight: 500,
      }}
    >
      <CheckCheck size={15} />
      Tandai Semua Dibaca
    </button>
  )

  return (
    <ListPageTemplate<Notification>
      title="Notifikasi"
      queryKey={QUERY_KEY}
      fetcher={(params) => notificationService.list(params)}
      columns={columns}
      rowActions={rowActions}
      searchPlaceholder="Cari notifikasi..."
      emptyTitle="Tidak ada notifikasi"
      emptyDescription="Belum ada notifikasi yang masuk."
      helpTitle="Notifikasi"
      helpText="Notifikasi sistem untuk aktivitas terkait akun Anda."
      hidePagination={false}
      actions={headerActions}
    />
  )
}
