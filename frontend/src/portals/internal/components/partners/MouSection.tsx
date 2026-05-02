import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Plus, Trash2, ExternalLink } from 'lucide-react'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { createMouSchema, type CreateMouInput } from '@/schemas/mou'
import { MOU_STATUSES } from '@/types/mou'
import {
  usePartnerMous,
  useCreateMou,
  useDeleteMou,
} from '@/lib/api/partner'

interface Props {
  partnerId: string
}

const STATUS_CLASS: Record<string, string> = {
  draft: 'bg-neutral-100 text-neutral-600',
  active: 'bg-emerald-50 text-emerald-700',
  expired: 'bg-rose-50 text-rose-700',
  terminated: 'bg-neutral-200 text-neutral-700',
}

export default function MouSection({ partnerId }: Props) {
  const { data: mous = [], isLoading } = usePartnerMous(partnerId)
  const create = useCreateMou(partnerId)
  const del = useDeleteMou(partnerId)

  const [showForm, setShowForm] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null)

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting },
  } = useForm<CreateMouInput>({
    resolver: zodResolver(createMouSchema),
    defaultValues: {
      title: '', description: '',
      start_date: '', end_date: '',
      document_url: '', status: 'draft',
    },
  })

  async function onSubmit(values: CreateMouInput) {
    try {
      await create.mutateAsync(values)
      toast.success('MOU added')
      reset()
      setShowForm(false)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to add MOU')
    }
  }

  async function handleDelete() {
    if (!confirmDelete) return
    try {
      await del.mutateAsync(confirmDelete)
      toast.success('MOU deleted')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to delete MOU')
    } finally {
      setConfirmDelete(null)
    }
  }

  if (isLoading) return <LoadingSpinner />

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-neutral-700">
          MOUs ({mous.length})
        </h3>
        <RoleGate action="create" resource="mou">
          <Button variant="secondary" onClick={() => setShowForm(!showForm)}>
            <Plus className="w-4 h-4" /> {showForm ? 'Close' : 'Add MOU'}
          </Button>
        </RoleGate>
      </div>

      {showForm && (
        <form
          onSubmit={handleSubmit(onSubmit)}
          className="bg-white rounded-xl border border-neutral-100 p-4 space-y-3"
        >
          <FormField label="Title" required error={errors.title?.message}>
            <Input {...register('title')} placeholder="MOU 2026" />
          </FormField>
          <div className="grid grid-cols-2 gap-3">
            <FormField label="Start Date" required error={errors.start_date?.message}>
              <Input type="date" {...register('start_date')} />
            </FormField>
            <FormField label="End Date" required error={errors.end_date?.message}>
              <Input type="date" {...register('end_date')} />
            </FormField>
          </div>
          <FormField label="Document URL" error={errors.document_url?.message}>
            <Input {...register('document_url')} placeholder="https://..." />
          </FormField>
          <FormField label="Status" error={errors.status?.message}>
            <Select {...register('status')}>
              {MOU_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
            </Select>
          </FormField>
          <FormField label="Description" error={errors.description?.message}>
            <Textarea {...register('description')} rows={2} />
          </FormField>
          <div className="flex gap-2 justify-end">
            <Button type="button" variant="secondary" onClick={() => setShowForm(false)}>
              Cancel
            </Button>
            <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
              Save MOU
            </Button>
          </div>
        </form>
      )}

      {mous.length === 0 ? (
        <p className="text-sm text-neutral-400 italic py-4">No MOUs yet.</p>
      ) : (
        <ul className="space-y-2">
          {mous.map((m) => (
            <li
              key={m.id}
              className="bg-white rounded-xl border border-neutral-100 p-4 flex items-start gap-4"
            >
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h4 className="font-medium text-neutral-900">{m.title}</h4>
                  <span
                    className={`text-xs px-2 py-0.5 rounded-full ${STATUS_CLASS[m.status] ?? ''}`}
                  >
                    {m.status}
                  </span>
                </div>
                <p className="text-xs text-neutral-500 mt-1">
                  {m.start_date} → {m.end_date}
                </p>
                {m.description && (
                  <p className="text-sm text-neutral-600 mt-2 whitespace-pre-wrap">
                    {m.description}
                  </p>
                )}
                {m.document_url && (
                  <a
                    href={m.document_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1 text-xs text-brand-600 hover:underline mt-2"
                  >
                    <ExternalLink className="w-3 h-3" /> Document
                  </a>
                )}
              </div>
              <RoleGate action="delete" resource="mou">
                <button
                  type="button"
                  onClick={() => setConfirmDelete(m.id)}
                  className="text-rose-500 hover:text-rose-700 p-1"
                  aria-label="Delete MOU"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </RoleGate>
            </li>
          ))}
        </ul>
      )}

      <ConfirmDialog
        open={!!confirmDelete}
        title="Delete MOU?"
        description="This action cannot be undone."
        confirmLabel="Delete"
        destructive
        onConfirm={handleDelete}
        onCancel={() => setConfirmDelete(null)}
      />
    </div>
  )
}
