import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { StandardPageLayout, type BreadcrumbItem } from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import RoleGate from '@/components/shared/RoleGate'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  updateMarketingPrSchema,
  type UpdateMarketingPrInput,
} from '@/schemas/marketingpr'
import { PR_TYPES, PR_STATUSES } from '@/types/marketingpr'
import {
  useMarketingPrDetail,
  useUpdateMarketingPr,
  useDeleteMarketingPr,
} from '@/lib/api/marketing'

export default function MarketingPREditPage() {
  const navigate = useNavigate()
  const { id = '' } = useParams<{ id: string }>()
  const { data, isLoading } = useMarketingPrDetail(id)
  const update = useUpdateMarketingPr(id)
  const del = useDeleteMarketingPr()
  const [confirmDelete, setConfirmDelete] = useState(false)

  const {
    register, handleSubmit, reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateMarketingPrInput>({
    resolver: zodResolver(updateMarketingPrSchema),
  })

  useEffect(() => {
    if (data) {
      reset({
        title: data.title,
        type: data.type,
        scheduled_at: data.scheduled_at?.slice(0, 16) ?? '',
        media_venue: data.media_venue ?? '',
        pic_id: data.pic_id ?? null,
        pic_name: data.pic_name ?? '',
        notes: data.notes ?? '',
        status: data.status,
      })
    }
  }, [data, reset])

  async function onSubmit(values: UpdateMarketingPrInput) {
    try {
      await update.mutateAsync(values)
      toast.success('PR updated')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update')
    }
  }

  async function onDelete() {
    try {
      await del.mutateAsync(id)
      toast.success('PR deleted')
      navigate('/internal/marketing/pr')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed')
    } finally {
      setConfirmDelete(false)
    }
  }

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Marketing', to: '/internal/marketing/pr' },
    { label: 'PR', to: '/internal/marketing/pr' },
    { label: 'Edit' },
  ]

  return (
    <StandardPageLayout breadcrumbs={breadcrumbs} title="Edit Marketing PR">
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
        <FormField label="Title" required error={errors.title?.message}>
          <Input {...register('title')} />
        </FormField>
        <FormField label="Type" required error={errors.type?.message}>
          <Select {...register('type')}>
            {PR_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
          </Select>
        </FormField>
        <FormField label="Status" required error={errors.status?.message}>
          <Select {...register('status')}>
            {PR_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
          </Select>
        </FormField>
        <FormField label="Scheduled At" required error={errors.scheduled_at?.message}>
          <Input type="datetime-local" {...register('scheduled_at')} />
        </FormField>
        <FormField label="Media / Venue" error={errors.media_venue?.message}>
          <Input {...register('media_venue')} />
        </FormField>
        <FormField label="PIC Name" error={errors.pic_name?.message}>
          <Input {...register('pic_name')} />
        </FormField>
        <FormField label="Notes" error={errors.notes?.message}>
          <Textarea {...register('notes')} rows={4} />
        </FormField>
        <div className="flex gap-2 pt-2 border-t border-neutral-100">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/marketing/pr')}>
            Cancel
          </Button>
          <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>
            Save
          </Button>
          <RoleGate action="delete" resource="marketing_post">
            <Button type="button" variant="danger" onClick={() => setConfirmDelete(true)}>
              Delete
            </Button>
          </RoleGate>
        </div>
      </form>

      <ConfirmDialog
        open={confirmDelete}
        onConfirm={onDelete}
        onCancel={() => setConfirmDelete(false)}
        title="Delete PR?"
        description="This cannot be undone."
        confirmLabel="Delete"
        destructive
      />
    </StandardPageLayout>
  )
}
