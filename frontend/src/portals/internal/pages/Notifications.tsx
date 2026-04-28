import { useState } from 'react'
import { Bell, Edit2, Plus, Trash2 } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { cn } from '@/lib/utils/cn'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  useNotificationTemplates,
  useCreateNotificationTemplate,
  useUpdateNotificationTemplate,
  useDeleteNotificationTemplate,
  type NotificationTemplate,
} from '@/lib/api/platform-admin'

const CHANNEL_STYLES: Record<NotificationTemplate['channel'], string> = {
  email: 'bg-sky-50 text-sky-700',
  in_app: 'bg-brand-50 text-brand-700',
  push: 'bg-violet-50 text-violet-700',
}

const CHANNEL_LABELS: Record<NotificationTemplate['channel'], string> = {
  email: 'Email',
  in_app: 'In-App',
  push: 'Push',
}

const templateSchema = z.object({
  key: z.string().min(2, 'Key required'),
  channel: z.enum(['email', 'in_app', 'push']),
  subject: z.string().optional(),
  body: z.string().min(5, 'Body required'),
})

type TemplateForm = z.infer<typeof templateSchema>

export default function Notifications() {
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editTarget, setEditTarget] = useState<NotificationTemplate | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<NotificationTemplate | null>(null)

  const { data = [], isLoading } = useNotificationTemplates()
  const createTemplate = useCreateNotificationTemplate()
  const updateTemplate = useUpdateNotificationTemplate()
  const deleteTemplate = useDeleteNotificationTemplate()

  const isEditMode = !!editTarget

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<TemplateForm>({
    resolver: zodResolver(templateSchema),
  })

  const openCreate = () => {
    setEditTarget(null)
    reset({ key: '', channel: 'email', subject: '', body: '' })
    setDialogOpen(true)
  }

  const openEdit = (tpl: NotificationTemplate) => {
    setEditTarget(tpl)
    reset({
      key: tpl.key,
      channel: tpl.channel,
      subject: tpl.subject ?? '',
      body: tpl.body,
    })
    setDialogOpen(true)
  }

  const handleClose = () => {
    setDialogOpen(false)
    setEditTarget(null)
  }

  const onSubmit = async (values: TemplateForm) => {
    try {
      if (isEditMode && editTarget) {
        await updateTemplate.mutateAsync({
          id: editTarget.id,
          subject: values.subject || undefined,
          body: values.body,
        })
        toast.success('Template updated')
      } else {
        await createTemplate.mutateAsync({
          key: values.key,
          channel: values.channel,
          subject: values.subject || undefined,
          body: values.body,
        })
        toast.success('Template created')
      }
      handleClose()
    } catch {
      toast.error(isEditMode ? 'Failed to update template' : 'Failed to create template')
    }
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    try {
      await deleteTemplate.mutateAsync(deleteTarget.id)
      toast.success('Template deleted')
      setDeleteTarget(null)
    } catch {
      toast.error('Failed to delete template')
    }
  }

  const columns: Column<NotificationTemplate>[] = [
    {
      header: 'Key',
      accessor: 'key',
      cell: (row) => (
        <span className="font-mono text-xs text-neutral-700">{row.key}</span>
      ),
    },
    {
      header: 'Channel',
      accessor: 'channel',
      cell: (row) => (
        <span
          className={cn(
            'inline-flex px-2 py-0.5 rounded-full text-xs font-medium',
            CHANNEL_STYLES[row.channel]
          )}
        >
          {CHANNEL_LABELS[row.channel]}
        </span>
      ),
    },
    {
      header: 'Subject',
      accessor: 'subject',
      cell: (row) => (
        <span className="text-sm text-neutral-600">{row.subject ?? '—'}</span>
      ),
    },
    {
      header: 'Status',
      accessor: 'is_active',
      cell: (row) => (
        <span
          className={cn(
            'inline-flex px-2 py-0.5 rounded-full text-xs font-medium capitalize',
            row.is_active
              ? 'bg-emerald-50 text-emerald-700'
              : 'bg-neutral-100 text-neutral-500'
          )}
        >
          {row.is_active ? 'Active' : 'Inactive'}
        </span>
      ),
    },
    {
      header: 'Actions',
      accessor: 'id',
      cell: (row) => (
        <div className="flex items-center gap-1.5">
          <button
            onClick={() => openEdit(row)}
            className="p-1.5 rounded-lg text-neutral-500 hover:text-brand-600 hover:bg-brand-50 transition-colors"
            aria-label="Edit template"
          >
            <Edit2 className="w-4 h-4" />
          </button>
          <button
            onClick={() => setDeleteTarget(row)}
            className="p-1.5 rounded-lg text-neutral-500 hover:text-red-600 hover:bg-red-50 transition-colors"
            aria-label="Delete template"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-5">
      <PageHeader
        title="Notifications"
        subtitle={isLoading ? 'Loading templates…' : `${data.length} template${data.length !== 1 ? 's' : ''}`}
        actions={
          <button
            onClick={openCreate}
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            New Template
          </button>
        }
      />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={columns}
          data={data}
          loading={isLoading}
          rowKey={(row) => row.id}
        />
      </div>

      {/* Create / Edit Dialog */}
      <Dialog.Root open={dialogOpen} onOpenChange={(o) => !o && handleClose()}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-50 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0" />
          <Dialog.Content className="fixed left-1/2 top-1/2 z-50 -translate-x-1/2 -translate-y-1/2 w-full max-w-lg bg-white rounded-xl shadow-xl p-6 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95">
            <div className="flex items-center gap-3 mb-5">
              <div className="w-9 h-9 rounded-lg bg-brand-50 flex items-center justify-center">
                <Bell className="w-4 h-4 text-brand-600" />
              </div>
              <div>
                <Dialog.Title className="text-base font-semibold text-neutral-900">
                  {isEditMode ? 'Edit Template' : 'New Template'}
                </Dialog.Title>
                <Dialog.Description className="text-xs text-neutral-500">
                  {isEditMode ? 'Update notification template content.' : 'Create a new notification template.'}
                </Dialog.Description>
              </div>
            </div>

            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-xs font-medium text-neutral-700">Key *</label>
                  <input
                    {...register('key')}
                    disabled={isEditMode}
                    placeholder="e.g. enrollment_confirmed"
                    className={cn(
                      'w-full px-3 py-2 text-sm font-mono rounded-lg border border-neutral-200 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent transition',
                      isEditMode && 'bg-neutral-50 text-neutral-400 cursor-not-allowed'
                    )}
                  />
                  {errors.key && (
                    <p className="text-xs text-red-500">{errors.key.message}</p>
                  )}
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-medium text-neutral-700">Channel *</label>
                  <select
                    {...register('channel')}
                    disabled={isEditMode}
                    className={cn(
                      'w-full px-3 py-2 text-sm rounded-lg border border-neutral-200 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent transition bg-white',
                      isEditMode && 'bg-neutral-50 text-neutral-400 cursor-not-allowed'
                    )}
                  >
                    <option value="email">Email</option>
                    <option value="in_app">In-App</option>
                    <option value="push">Push</option>
                  </select>
                </div>
              </div>

              <div className="space-y-1">
                <label className="text-xs font-medium text-neutral-700">Subject</label>
                <input
                  {...register('subject')}
                  placeholder="Email subject (optional)"
                  className="w-full px-3 py-2 text-sm rounded-lg border border-neutral-200 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent transition"
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-medium text-neutral-700">Body *</label>
                <textarea
                  {...register('body')}
                  rows={5}
                  placeholder="Template body content…"
                  className="w-full px-3 py-2 text-sm rounded-lg border border-neutral-200 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent transition resize-none"
                />
                {errors.body && (
                  <p className="text-xs text-red-500">{errors.body.message}</p>
                )}
              </div>

              <div className="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={handleClose}
                  className="px-4 py-2 text-sm font-medium text-neutral-700 bg-neutral-100 rounded-lg hover:bg-neutral-200 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-60 transition-colors"
                >
                  {isSubmitting ? 'Saving…' : isEditMode ? 'Save Changes' : 'Create Template'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Template"
        description={`Delete template "${deleteTarget?.key ?? ''}"? This action cannot be undone.`}
        confirmLabel="Delete"
        destructive
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  )
}
