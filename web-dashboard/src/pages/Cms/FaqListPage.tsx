import { useNavigate } from 'react-router-dom'
import { Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { cmsService } from '@/services/cms.service'

interface Faq {
  id: string
  question: string
  category?: string
  page_slug?: string
  page?: string
  order?: number
  sort_order?: number
  [key: string]: unknown
}

const columns: ColumnDef<Faq>[] = [
  {
    key: 'question',
    header: 'Pertanyaan',
    render: (_v, row) => {
      const text = row.question || '—'
      const truncated = text.length > 100 ? text.slice(0, 100) + '…' : text
      return (
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {truncated}
        </div>
      )
    },
  },
  {
    key: 'category',
    header: 'Kategori',
    width: 150,
    render: (_v, row) => (
      <span>{row.category || '—'}</span>
    ),
  },
  {
    key: 'page_slug',
    header: 'Halaman',
    width: 160,
    render: (_v, row) => (
      <span>{row.page_slug || row.page || '—'}</span>
    ),
  },
  {
    key: 'order',
    header: 'Urutan',
    width: 80,
    align: 'center',
    render: (_v, row) => {
      const val = row.sort_order ?? row.order
      return <span>{val !== undefined && val !== null ? val : '—'}</span>
    },
  },
]

export default function FaqListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Faq>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/cms/faq/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Faq>
      title="FAQ"
      addLabel="Tambah FAQ"
      onAdd={() => navigate('/cms/faq/new')}
      queryKey="cms-faq"
      fetcher={async (_params) => {
        const raw = await cmsService.listFaq()
        const items = Array.isArray(raw) ? raw : (raw as any)?.items ?? []
        return { items, total: items.length, limit: 9999, offset: 0 }
      }}
      columns={columns}
      rowActions={rowActions}
      hidePagination
      searchPlaceholder="Cari pertanyaan..."
      emptyTitle="Belum ada FAQ"
      emptyDescription="Tambahkan pertanyaan yang sering ditanyakan oleh calon siswa."
      helpTitle="FAQ"
      helpText="Kelola FAQ yang ditampilkan di website publik untuk menjawab pertanyaan umum tentang program kursus."
      deleteConfig={{
        onDelete: (row) => cmsService.deleteFaq(row.id),
        dialogTitle: 'Hapus FAQ?',
        dialogBody: (row) => `"${row.question}" akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: (row) => `FAQ "${row.question}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus FAQ',
      }}
    />
  )
}
