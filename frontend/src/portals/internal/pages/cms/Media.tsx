import { useState, useRef } from 'react'
import { Upload, Trash2, FileText, ImageIcon } from 'lucide-react'
import { toast } from 'sonner'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import RoleGate from '@/components/shared/RoleGate'
import Button from '@/components/ui/Button'
import {
  useCmsMedia,
  useUploadCmsMediaFile,
  useDeleteCmsMedia,
} from '@/lib/api/cms'

const LIMIT = 24

function formatBytes(n: number) {
  if (!n) return '-'
  if (n < 1024) return `${n} B`
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`
  return `${(n / (1024 * 1024)).toFixed(2)} MB`
}

export default function Media() {
  const [page, setPage] = useState(1)
  const { data, isLoading } = useCmsMedia({ page, limit: LIMIT })
  const upload = useUploadCmsMediaFile()
  const del = useDeleteCmsMedia()
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  async function onFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    try {
      await upload.mutateAsync(file)
      toast.success(`Uploaded ${file.name}`)
    } catch (err: any) {
      toast.error(err?.response?.data?.message ?? 'Upload failed')
    } finally {
      if (fileInputRef.current) fileInputRef.current.value = ''
    }
  }

  async function onDelete() {
    if (!deleteId) return
    try {
      await del.mutateAsync(deleteId)
      toast.success('Media deleted')
    } catch (err: any) {
      toast.error(err?.response?.data?.message ?? 'Failed to delete')
    } finally {
      setDeleteId(null)
    }
  }

  const items = data?.data ?? []
  const total = data?.total ?? 0
  const totalPages = Math.max(1, Math.ceil(total / LIMIT))

  return (
    <div className="space-y-5">
      <PageHeader
        title="Media Library"
        subtitle="Images and files for the website"
        actions={
          <RoleGate action="create" resource="cms_media">
            <>
              <input
                ref={fileInputRef}
                type="file"
                onChange={onFileChange}
                className="hidden"
              />
              <Button
                onClick={() => fileInputRef.current?.click()}
                loading={upload.isPending}
              >
                <Upload className="w-4 h-4" /> Upload
              </Button>
            </>
          </RoleGate>
        }
      />

      {isLoading ? (
        <LoadingSpinner size="lg" />
      ) : (
        <>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
            {items.length === 0 && (
              <div className="col-span-full bg-white rounded-xl border border-neutral-100 p-6 text-sm text-neutral-500">
                No media yet
              </div>
            )}
            {items.map((m) => {
              const isImage = m.file_type?.startsWith('image/')
              return (
                <div
                  key={m.id}
                  className="group bg-white rounded-xl border border-neutral-100 overflow-hidden"
                >
                  <div className="aspect-square bg-neutral-50 flex items-center justify-center">
                    {isImage ? (
                      <img
                        src={m.url}
                        alt={m.file_name}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <FileText className="w-10 h-10 text-neutral-400" />
                    )}
                  </div>
                  <div className="p-2 text-xs">
                    <div className="font-medium text-neutral-900 truncate" title={m.file_name}>
                      {m.file_name}
                    </div>
                    <div className="flex items-center justify-between text-neutral-500 mt-1">
                      <span>{formatBytes(m.file_size)}</span>
                      <RoleGate action="delete" resource="cms_media">
                        <button
                          onClick={() => setDeleteId(m.id)}
                          className="p-1 text-neutral-400 hover:text-red-600"
                          aria-label="Delete"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </RoleGate>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>

          {totalPages > 1 && (
            <div className="flex items-center justify-end gap-2 text-sm">
              <button
                disabled={page <= 1}
                onClick={() => setPage((p) => p - 1)}
                className="px-3 py-1.5 border border-neutral-200 rounded-lg disabled:opacity-50"
              >
                Prev
              </button>
              <span className="text-neutral-500">
                {page} / {totalPages}
              </span>
              <button
                disabled={page >= totalPages}
                onClick={() => setPage((p) => p + 1)}
                className="px-3 py-1.5 border border-neutral-200 rounded-lg disabled:opacity-50"
              >
                Next
              </button>
            </div>
          )}
        </>
      )}

      <ConfirmDialog
        open={!!deleteId}
        onConfirm={onDelete}
        onCancel={() => setDeleteId(null)}
        title="Delete media?"
        description="This cannot be undone."
        confirmLabel="Delete"
        destructive
      />

      {/* unused icon import safeguard */}
      <span className="hidden">
        <ImageIcon className="w-0 h-0" />
      </span>
    </div>
  )
}
